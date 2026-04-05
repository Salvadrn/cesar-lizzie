import random
import logging
from ..base import UltrasonicBase

logger = logging.getLogger(__name__)


class MockUltrasonic(UltrasonicBase):
    def __init__(self, emergency_stop_cm: float = 30):
        self._emergency_cm = emergency_stop_cm
        self._distances: dict[str, float] = {
            "front_left": 150.0,
            "front_right": 150.0,
        }

    def start(self) -> None:
        logger.info("[MOCK] Ultrasonic sensors started")

    def stop(self) -> None:
        logger.info("[MOCK] Ultrasonic sensors stopped")

    def get_distance_cm(self, sensor: str) -> float:
        base = self._distances.get(sensor, 150.0)
        return max(2, base + random.gauss(0, 1))

    def is_emergency(self) -> bool:
        for sensor in self._distances:
            if self.get_distance_cm(sensor) < self._emergency_cm:
                return True
        return False

    def set_simulated_distance(self, sensor: str, cm: float) -> None:
        self._distances[sensor] = cm
