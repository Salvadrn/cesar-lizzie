import logging
from ..state.robot_state import RobotStateMachine, State
from ..hal.base import MotorControllerBase
from ..safety.emergency_stop import EmergencyStopWatchdog

logger = logging.getLogger(__name__)

COMMAND_STATE_MAP = {
    "start": State.FOLLOWING,
    "stop": State.IDLE,
    "pause": State.PAUSED,
    "resume": State.FOLLOWING,
    "reset": State.IDLE,
}


class CommandHandler:
    def __init__(
        self,
        state_machine: RobotStateMachine,
        motors: MotorControllerBase,
        emergency: EmergencyStopWatchdog,
    ):
        self._state = state_machine
        self._motors = motors
        self._emergency = emergency
        self._config_callback: callable | None = None

    def on_config_update(self, callback: callable) -> None:
        self._config_callback = callback

    async def handle(self, command: dict) -> None:
        cmd_type = command.get("commandType", "")
        payload = command.get("payload", {})

        logger.info(f"Handling command: {cmd_type}")

        if cmd_type == "emergency_stop":
            self._motors.emergency_stop()
            self._state.force_state(State.EMERGENCY_STOP)
            return

        if cmd_type == "reset":
            if self._state.state == State.EMERGENCY_STOP:
                self._emergency.reset()
            self._state.transition(State.IDLE)
            return

        if cmd_type == "update_config" and self._config_callback:
            self._config_callback(payload)
            return

        target_state = COMMAND_STATE_MAP.get(cmd_type)
        if target_state:
            if cmd_type in ("stop", "pause"):
                self._motors.set_drive(0)
            self._state.transition(target_state)
        else:
            logger.warning(f"Unknown command: {cmd_type}")
