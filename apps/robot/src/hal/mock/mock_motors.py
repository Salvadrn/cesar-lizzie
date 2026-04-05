import logging
from ..base import MotorControllerBase

logger = logging.getLogger(__name__)


class MockMotorController(MotorControllerBase):
    def __init__(self):
        self._speed = 0.0
        self._angle = 0.0
        self._stopped = True

    def start(self) -> None:
        self._stopped = False
        logger.info("[MOCK] Motor controller started")

    def stop(self) -> None:
        self.emergency_stop()
        self._stopped = True
        logger.info("[MOCK] Motor controller stopped")

    def set_drive(self, speed: float) -> None:
        if self._stopped:
            return
        self._speed = max(-1.0, min(1.0, speed))
        logger.debug(f"[MOCK] Drive speed: {self._speed:.2f}")

    def set_steering(self, angle: float) -> None:
        if self._stopped:
            return
        self._angle = max(-45, min(45, angle))
        logger.debug(f"[MOCK] Steering angle: {self._angle:.1f}")

    def emergency_stop(self) -> None:
        self._speed = 0.0
        self._angle = 0.0
        logger.warning("[MOCK] EMERGENCY STOP")

    def get_speed(self) -> float:
        return self._speed

    def get_steering_angle(self) -> float:
        return self._angle
