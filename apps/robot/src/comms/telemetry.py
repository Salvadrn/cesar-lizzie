import time
import logging
from datetime import datetime, timezone
from ..hal.base import BLETrackerBase, LiDARBase, UltrasonicBase, MotorControllerBase
from ..state.robot_state import RobotStateMachine
from ..navigation.follower import rssi_to_distance

logger = logging.getLogger(__name__)


class TelemetryPackager:
    """Packages sensor data into telemetry dict for backend."""

    def __init__(
        self,
        ble: BLETrackerBase,
        lidar: LiDARBase,
        ultrasonic: UltrasonicBase,
        motors: MotorControllerBase,
        state_machine: RobotStateMachine,
    ):
        self._ble = ble
        self._lidar = lidar
        self._ultrasonic = ultrasonic
        self._motors = motors
        self._state = state_machine
        self._start_time = time.time()

    def package(self) -> dict:
        rssi = self._ble.get_target_rssi()
        ble_distance = rssi_to_distance(rssi) if rssi is not None else None

        return {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "state": self._state.state.value,
            "batteryPercent": self._get_battery(),
            "bleEstimatedDistance": round(ble_distance, 2) if ble_distance else None,
            "bleTargetFound": self._ble.is_target_found(),
            "lidarNearestObstacle": self._safe_round(self._lidar.get_nearest_obstacle()),
            "ultrasonicFrontLeft": self._safe_round(self._ultrasonic.get_distance_cm("front_left")),
            "ultrasonicFrontRight": self._safe_round(self._ultrasonic.get_distance_cm("front_right")),
            "motorSpeed": round(self._motors.get_speed(), 3),
            "steeringAngle": round(self._motors.get_steering_angle(), 1),
            "wifiRssi": -45,  # TODO: read actual wifi RSSI
            "cpuTemp": self._get_cpu_temp(),
            "uptimeSeconds": int(time.time() - self._start_time),
        }

    def _get_battery(self) -> float:
        # TODO: read from ADC or I2C battery monitor
        return 100.0

    def _get_cpu_temp(self) -> float:
        try:
            with open("/sys/class/thermal/thermal_zone0/temp") as f:
                return float(f.read().strip()) / 1000
        except (FileNotFoundError, ValueError):
            return 0.0

    def _safe_round(self, val: float | None, digits: int = 1) -> float | None:
        return round(val, digits) if val is not None else None
