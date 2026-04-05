import time
import logging
from ..hal.base import MotorControllerBase
from ..state.robot_state import RobotStateMachine, State

logger = logging.getLogger(__name__)


class ConnectionWatchdog:
    """Monitors backend heartbeat and stops robot if connection lost."""

    def __init__(
        self,
        motors: MotorControllerBase,
        state_machine: RobotStateMachine,
        timeout_s: float = 5.0,
    ):
        self._motors = motors
        self._state = state_machine
        self._timeout = timeout_s
        self._last_heartbeat = time.time()

    def heartbeat(self) -> None:
        self._last_heartbeat = time.time()

    def check(self) -> bool:
        """Returns True if connection is healthy, False if timed out."""
        elapsed = time.time() - self._last_heartbeat
        if elapsed > self._timeout:
            if self._state.state != State.DISCONNECTED:
                logger.warning(f"Backend heartbeat lost ({elapsed:.1f}s)")
                self._motors.emergency_stop()
                self._state.force_state(State.DISCONNECTED)
            return False
        return True

    @property
    def seconds_since_heartbeat(self) -> float:
        return time.time() - self._last_heartbeat
