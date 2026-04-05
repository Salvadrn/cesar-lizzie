import time
import logging
import pigpio
from .base import UltrasonicBase

logger = logging.getLogger(__name__)


class Ultrasonic(UltrasonicBase):
    def __init__(
        self,
        pi: pigpio.pi,
        sensors: dict[str, tuple[int, int]],
        emergency_stop_cm: float = 30,
    ):
        self._pi = pi
        self._sensors = sensors  # name -> (trigger_pin, echo_pin)
        self._distances: dict[str, float] = {}
        self._emergency_cm = emergency_stop_cm

    def start(self) -> None:
        for name, (trig, echo) in self._sensors.items():
            self._pi.set_mode(trig, pigpio.OUTPUT)
            self._pi.set_mode(echo, pigpio.INPUT)
            self._pi.write(trig, 0)
        logger.info(f"Ultrasonic sensors started: {list(self._sensors.keys())}")

    def stop(self) -> None:
        for _, (trig, _) in self._sensors.items():
            self._pi.write(trig, 0)
        logger.info("Ultrasonic sensors stopped")

    def get_distance_cm(self, sensor: str) -> float:
        if sensor not in self._sensors:
            return 999.0

        trig, echo = self._sensors[sensor]

        self._pi.gpio_trigger(trig, 10, 1)
        start = time.time()
        timeout = start + 0.04  # 40ms timeout

        while self._pi.read(echo) == 0:
            start = time.time()
            if start > timeout:
                return 999.0

        while self._pi.read(echo) == 1:
            end = time.time()
            if end > timeout:
                return 999.0

        elapsed = end - start
        distance = (elapsed * 34300) / 2  # speed of sound cm/s

        self._distances[sensor] = distance
        return distance

    def is_emergency(self) -> bool:
        for name in self._sensors:
            dist = self.get_distance_cm(name)
            if dist < self._emergency_cm:
                return True
        return False
