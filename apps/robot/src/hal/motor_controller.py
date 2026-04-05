"""
Adapt AI Robot — Motor Controller for REV NEO 550 + SPARK MAX via PWM.

The SPARK MAX accepts standard PWM signals:
  - 1500us = neutral (stopped)
  - 1000us = full reverse
  - 2000us = full forward

Two motors in central swerve config:
  - Drive NEO: forward/reverse motion
  - Steer NEO: left/right rotation of the swerve module
"""

import logging
import pigpio
from .base import MotorControllerBase

logger = logging.getLogger(__name__)

# SPARK MAX PWM constants
NEUTRAL_US = 1500
MIN_US = 1000
MAX_US = 2000


class SparkMaxMotorController(MotorControllerBase):
    """Controls 2 REV NEO 550 motors via SPARK MAX PWM from Raspberry Pi."""

    def __init__(
        self,
        pi: pigpio.pi,
        drive_pin: int = 18,
        steer_pin: int = 12,
        max_drive_speed: float = 0.5,  # limit max speed for safety (0-1)
        max_steer_angle: float = 45.0,  # degrees
    ):
        self._pi = pi
        self._drive_pin = drive_pin
        self._steer_pin = steer_pin
        self._max_drive = max_drive_speed
        self._max_angle = max_steer_angle
        self._speed = 0.0
        self._angle = 0.0
        self._stopped = True

    def start(self) -> None:
        # Initialize both SPARK MAX at neutral
        self._pi.set_servo_pulsewidth(self._drive_pin, NEUTRAL_US)
        self._pi.set_servo_pulsewidth(self._steer_pin, NEUTRAL_US)
        self._stopped = False
        logger.info(
            f"SPARK MAX motor controller started "
            f"(drive=GPIO{self._drive_pin}, steer=GPIO{self._steer_pin})"
        )

    def stop(self) -> None:
        self.emergency_stop()
        self._stopped = True
        logger.info("SPARK MAX motor controller stopped")

    def set_drive(self, speed: float) -> None:
        """Set drive speed. Range: -1.0 (reverse) to 1.0 (forward)."""
        if self._stopped:
            return
        self._speed = max(-1.0, min(1.0, speed))
        # Apply safety limit
        limited = self._speed * self._max_drive
        # Convert to PWM: -1.0 -> 1000us, 0 -> 1500us, 1.0 -> 2000us
        pulse = int(NEUTRAL_US + (limited * 500))
        self._pi.set_servo_pulsewidth(self._drive_pin, pulse)

    def set_steering(self, angle: float) -> None:
        """Set steering angle. Range: -45 to +45 degrees."""
        if self._stopped:
            return
        self._angle = max(-self._max_angle, min(self._max_angle, angle))
        # Normalize to -1.0 to 1.0
        normalized = self._angle / self._max_angle
        # Convert to PWM
        pulse = int(NEUTRAL_US + (normalized * 500))
        self._pi.set_servo_pulsewidth(self._steer_pin, pulse)

    def emergency_stop(self) -> None:
        """Immediately set both motors to neutral."""
        self._speed = 0.0
        self._angle = 0.0
        self._pi.set_servo_pulsewidth(self._drive_pin, NEUTRAL_US)
        self._pi.set_servo_pulsewidth(self._steer_pin, NEUTRAL_US)
        logger.warning("EMERGENCY STOP — both SPARK MAX set to neutral")

    def get_speed(self) -> float:
        return self._speed

    def get_steering_angle(self) -> float:
        return self._angle
