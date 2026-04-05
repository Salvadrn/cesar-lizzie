import logging
import pigpio
from .base import MotorControllerBase

logger = logging.getLogger(__name__)


class MotorController(MotorControllerBase):
    def __init__(
        self,
        pi: pigpio.pi,
        drive_pin: int = 18,
        steering_pin: int = 12,
        drive_freq: int = 1000,
        center_pulse: int = 1500,
        range_pulse: int = 500,
        min_angle: float = -45,
        max_angle: float = 45,
    ):
        self._pi = pi
        self._drive_pin = drive_pin
        self._steering_pin = steering_pin
        self._drive_freq = drive_freq
        self._center_pulse = center_pulse
        self._range_pulse = range_pulse
        self._min_angle = min_angle
        self._max_angle = max_angle
        self._speed = 0.0
        self._angle = 0.0
        self._stopped = True

    def start(self) -> None:
        self._pi.set_mode(self._drive_pin, pigpio.OUTPUT)
        self._pi.set_PWM_frequency(self._drive_pin, self._drive_freq)
        self._pi.set_PWM_dutycycle(self._drive_pin, 0)
        self._pi.set_servo_pulsewidth(self._steering_pin, self._center_pulse)
        self._stopped = False
        logger.info("Motor controller started")

    def stop(self) -> None:
        self.emergency_stop()
        self._stopped = True
        logger.info("Motor controller stopped")

    def set_drive(self, speed: float) -> None:
        if self._stopped:
            return
        self._speed = max(-1.0, min(1.0, speed))
        duty = int(abs(self._speed) * 255)
        self._pi.set_PWM_dutycycle(self._drive_pin, duty)

    def set_steering(self, angle: float) -> None:
        if self._stopped:
            return
        self._angle = max(self._min_angle, min(self._max_angle, angle))
        normalized = self._angle / self._max_angle  # -1 to 1
        pulse = self._center_pulse + int(normalized * self._range_pulse)
        self._pi.set_servo_pulsewidth(self._steering_pin, pulse)

    def emergency_stop(self) -> None:
        self._speed = 0.0
        self._pi.set_PWM_dutycycle(self._drive_pin, 0)
        self._pi.set_servo_pulsewidth(self._steering_pin, self._center_pulse)
        logger.warning("EMERGENCY STOP - motors killed")

    def get_speed(self) -> float:
        return self._speed

    def get_steering_angle(self) -> float:
        return self._angle
