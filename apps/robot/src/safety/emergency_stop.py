import threading
import time
import logging
from ..hal.base import UltrasonicBase, MotorControllerBase
from ..state.robot_state import RobotStateMachine, State

logger = logging.getLogger(__name__)


class EmergencyStopWatchdog:
    """
    Independent thread that polls ultrasonic sensors and kills motors
    if any obstacle is too close. Runs independently of the main async loop.
    """

    def __init__(
        self,
        ultrasonic: UltrasonicBase,
        motors: MotorControllerBase,
        state_machine: RobotStateMachine,
        poll_rate_hz: float = 20,
    ):
        self._ultrasonic = ultrasonic
        self._motors = motors
        self._state = state_machine
        self._interval = 1.0 / poll_rate_hz
        self._running = False
        self._thread: threading.Thread | None = None
        self._triggered = False

    def start(self) -> None:
        self._running = True
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()
        logger.info(f"Emergency stop watchdog started ({1/self._interval:.0f} Hz)")

    def stop(self) -> None:
        self._running = False
        if self._thread:
            self._thread.join(timeout=2)
        logger.info("Emergency stop watchdog stopped")

    @property
    def triggered(self) -> bool:
        return self._triggered

    def reset(self) -> None:
        self._triggered = False

    def _run(self) -> None:
        while self._running:
            try:
                if self._ultrasonic.is_emergency():
                    self._motors.emergency_stop()
                    self._triggered = True
                    self._state.force_state(State.EMERGENCY_STOP)
                    logger.critical("EMERGENCY STOP: Obstacle too close!")
            except Exception as e:
                logger.error(f"Emergency stop check error: {e}")

            time.sleep(self._interval)
