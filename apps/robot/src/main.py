import asyncio
import argparse
import time
import logging
import yaml
from config.schema import AppConfig
from src.state.robot_state import RobotStateMachine, State
from src.navigation.follower import PIDFollower, rssi_to_distance
from src.navigation.obstacle_map import ObstacleMap
from src.navigation.path_planner import VFHPathPlanner
from src.safety.emergency_stop import EmergencyStopWatchdog
from src.safety.watchdog import ConnectionWatchdog
from src.comms.socket_client import RobotSocketClient
from src.comms.telemetry import TelemetryPackager
from src.comms.command_handler import CommandHandler
from src.voice.voice_manager import VoiceManager
from src.utils.logger import setup_logger

logger = logging.getLogger(__name__)


def load_config(path: str = "config/default.yaml") -> AppConfig:
    with open(path) as f:
        raw = yaml.safe_load(f)
    return AppConfig(**raw)


def create_hal(config: AppConfig, mock: bool = False):
    if mock:
        from src.hal.mock.mock_ble import MockBLETracker
        from src.hal.mock.mock_lidar import MockLiDAR
        from src.hal.mock.mock_ultrasonic import MockUltrasonic
        from src.hal.mock.mock_motors import MockMotorController

        ble = MockBLETracker(target_uuid=config.ble.target_uuid or "mock-target")
        lidar = MockLiDAR()
        ultrasonic = MockUltrasonic(emergency_stop_cm=config.ultrasonic.emergency_stop_cm)
        motors = MockMotorController()
    else:
        import pigpio
        from src.hal.ble_tracker import BLETracker
        from src.hal.lidar import LiDAR
        from src.hal.ultrasonic import Ultrasonic
        from src.hal.motor_controller import SparkMaxMotorController

        pi = pigpio.pi()
        if not pi.connected:
            raise RuntimeError("Could not connect to pigpio daemon")

        ble = BLETracker(
            target_uuid=config.ble.target_uuid,
            kalman_q=config.ble.rssi_kalman_q,
            kalman_r=config.ble.rssi_kalman_r,
        )
        lidar = LiDAR(port=config.lidar.port)
        ultrasonic = Ultrasonic(
            pi=pi,
            sensors={
                "front_left": (config.ultrasonic.front_left.trigger_pin, config.ultrasonic.front_left.echo_pin),
                "front_right": (config.ultrasonic.front_right.trigger_pin, config.ultrasonic.front_right.echo_pin),
            },
            emergency_stop_cm=config.ultrasonic.emergency_stop_cm,
        )
        motors = SparkMaxMotorController(
            pi=pi,
            drive_pin=config.motors.drive.pin,
            steer_pin=config.motors.steering.pin,
            max_drive_speed=config.navigation.max_speed,
        )

    return ble, lidar, ultrasonic, motors


async def main():
    parser = argparse.ArgumentParser(description="Adapt AI Robot Controller")
    parser.add_argument("--mock", action="store_true", help="Run with mock hardware")
    parser.add_argument("--config", default="config/default.yaml", help="Config file path")
    parser.add_argument("--log-level", default="INFO", help="Log level")
    args = parser.parse_args()

    setup_logger(args.log_level)
    config = load_config(args.config)
    use_mock = args.mock or config.loop.mock

    logger.info(f"Starting Adapt AI Robot ({'MOCK' if use_mock else 'HARDWARE'} mode)")

    # Initialize HAL
    ble, lidar, ultrasonic, motors = create_hal(config, mock=use_mock)

    # Initialize subsystems
    state_machine = RobotStateMachine()
    follower = PIDFollower(
        target_distance=config.navigation.follow_distance_m,
        max_speed=config.navigation.max_speed,
        kp=config.navigation.pid.kp,
        ki=config.navigation.pid.ki,
        kd=config.navigation.pid.kd,
    )
    obstacle_map = ObstacleMap(sector_count=config.navigation.vfh.sector_count)
    path_planner = VFHPathPlanner(
        obstacle_map=obstacle_map,
        threshold=config.navigation.vfh.threshold,
        wide_opening=config.navigation.vfh.wide_opening,
    )

    # Safety
    emergency = EmergencyStopWatchdog(
        ultrasonic=ultrasonic,
        motors=motors,
        state_machine=state_machine,
        poll_rate_hz=config.ultrasonic.poll_rate_hz,
    )

    # Comms
    socket_client = RobotSocketClient(
        server_url=config.server.url,
        robot_id=config.robot.id,
        api_key=config.robot.api_key,
        namespace=config.server.namespace,
    )
    watchdog = ConnectionWatchdog(
        motors=motors,
        state_machine=state_machine,
        timeout_s=config.safety.watchdog_timeout_s,
    )
    telemetry = TelemetryPackager(ble, lidar, ultrasonic, motors, state_machine)
    cmd_handler = CommandHandler(state_machine, motors, emergency)
    socket_client.on_command(cmd_handler.handle)

    def on_config_update(payload: dict):
        if "followDistanceM" in payload:
            follower.target_distance = payload["followDistanceM"]
        if "maxSpeed" in payload:
            follower.max_speed = payload["maxSpeed"]

    cmd_handler.on_config_update(on_config_update)

    # State change -> notify backend
    async def on_state_change(old, new):
        await socket_client.emit_status_change(new.value)
        if new == State.EMERGENCY_STOP:
            await socket_client.emit_emergency("obstacle_too_close")

    state_machine.on_change(lambda old, new: asyncio.ensure_future(on_state_change(old, new)))

    # Voice (JARVIS patient mode)
    voice_manager = None
    if config.voice.enabled and config.voice.jarvis_url:
        if use_mock:
            from src.voice.speech_to_text import MockSTT
            from src.voice.text_to_speech import MockTTS
            stt = MockSTT()
            tts = MockTTS()
        else:
            from src.voice.speech_to_text import WhisperSTT
            from src.voice.text_to_speech import PyttsxTTS
            stt = WhisperSTT(api_key=config.voice.openai_api_key, language=config.voice.language)
            tts = PyttsxTTS(rate=config.voice.tts_rate, voice_lang=config.voice.language)

        voice_manager = VoiceManager(
            stt=stt,
            tts=tts,
            jarvis_url=config.voice.jarvis_url,
            jarvis_api_key=config.voice.jarvis_api_key,
            user_id=config.voice.user_id,
            mock_audio=use_mock,
        )
        await voice_manager.start()
        logger.info("Voice manager (JARVIS patient mode) initialized")

    # Start everything
    await ble.start()
    if config.lidar.enabled:
        await lidar.start()
    ultrasonic.start()
    motors.start()
    emergency.start()
    await socket_client.connect()

    logger.info("All subsystems initialized. Entering main loop.")

    loop_interval = 1.0 / config.loop.rate_hz
    telemetry_interval = 1.0 / config.loop.telemetry_rate_hz
    last_telemetry = 0.0

    try:
        while True:
            loop_start = time.time()

            # Watchdog check
            if socket_client.connected:
                watchdog.heartbeat()
            watchdog.check()

            # Only navigate when in FOLLOWING state
            if state_machine.state == State.FOLLOWING:
                # 1. BLE scan
                await ble.scan()

                # 2. Estimate distance
                rssi = ble.get_target_rssi()
                if rssi is not None and ble.is_target_found():
                    distance = rssi_to_distance(rssi)
                    desired_speed = follower.update(distance)
                    desired_angle = 0.0  # BLE doesn't give direction, assume forward

                    # 3. LiDAR scan + obstacle avoidance
                    if config.lidar.enabled:
                        scan = await lidar.get_scan()
                        obstacle_map.update(scan)
                        steering, speed = path_planner.plan(desired_angle, desired_speed)
                    else:
                        steering, speed = 0.0, desired_speed

                    # 4. Apply motor commands
                    motors.set_drive(speed)
                    motors.set_steering(steering)
                else:
                    motors.set_drive(0)

            # Send telemetry at configured rate
            now = time.time()
            if now - last_telemetry >= telemetry_interval:
                data = telemetry.package()
                await socket_client.emit_telemetry(data)
                last_telemetry = now

            # Rate limiting
            elapsed = time.time() - loop_start
            sleep_time = loop_interval - elapsed
            if sleep_time > 0:
                await asyncio.sleep(sleep_time)

    except KeyboardInterrupt:
        logger.info("Shutting down...")
    finally:
        motors.emergency_stop()
        emergency.stop()
        ultrasonic.stop()
        if config.lidar.enabled:
            await lidar.stop()
        await ble.stop()
        await socket_client.disconnect()
        logger.info("Shutdown complete")


if __name__ == "__main__":
    asyncio.run(main())
