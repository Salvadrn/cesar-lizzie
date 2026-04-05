import logging
from enum import Enum

logger = logging.getLogger(__name__)


class State(str, Enum):
    IDLE = "idle"
    FOLLOWING = "following"
    PAUSED = "paused"
    ERROR = "error"
    EMERGENCY_STOP = "emergency_stop"
    DISCONNECTED = "disconnected"


VALID_TRANSITIONS: dict[State, set[State]] = {
    State.IDLE: {State.FOLLOWING, State.ERROR, State.EMERGENCY_STOP, State.DISCONNECTED},
    State.FOLLOWING: {State.PAUSED, State.IDLE, State.ERROR, State.EMERGENCY_STOP, State.DISCONNECTED},
    State.PAUSED: {State.FOLLOWING, State.IDLE, State.ERROR, State.EMERGENCY_STOP, State.DISCONNECTED},
    State.ERROR: {State.IDLE, State.EMERGENCY_STOP, State.DISCONNECTED},
    State.EMERGENCY_STOP: {State.IDLE, State.DISCONNECTED},
    State.DISCONNECTED: {State.IDLE, State.ERROR},
}


class RobotStateMachine:
    def __init__(self):
        self._state = State.IDLE
        self._listeners: list[callable] = []

    @property
    def state(self) -> State:
        return self._state

    def can_transition(self, new_state: State) -> bool:
        return new_state in VALID_TRANSITIONS.get(self._state, set())

    def transition(self, new_state: State) -> bool:
        if not self.can_transition(new_state):
            logger.warning(f"Invalid transition: {self._state} -> {new_state}")
            return False

        old = self._state
        self._state = new_state
        logger.info(f"State: {old.value} -> {new_state.value}")

        for listener in self._listeners:
            listener(old, new_state)

        return True

    def on_change(self, callback: callable) -> None:
        self._listeners.append(callback)

    def force_state(self, state: State) -> None:
        """Force state without validation (for emergency/disconnect)."""
        old = self._state
        self._state = state
        logger.warning(f"State FORCED: {old.value} -> {state.value}")
        for listener in self._listeners:
            listener(old, state)
