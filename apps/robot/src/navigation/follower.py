import time
import logging

logger = logging.getLogger(__name__)


def rssi_to_distance(rssi: float, tx_power: float = -40.0, n: float = 2.5) -> float:
    """Estimate distance in meters from RSSI using log-distance path loss model."""
    if rssi >= 0:
        return 0.1
    return 10 ** ((tx_power - rssi) / (10 * n))


class PIDFollower:
    """PID controller that outputs speed based on distance error from target."""

    def __init__(
        self,
        target_distance: float = 1.5,
        max_speed: float = 0.5,
        kp: float = 0.8,
        ki: float = 0.05,
        kd: float = 0.2,
    ):
        self.target_distance = target_distance
        self.max_speed = max_speed
        self._kp = kp
        self._ki = ki
        self._kd = kd
        self._integral = 0.0
        self._prev_error = 0.0
        self._prev_time = time.time()

    def update(self, current_distance: float) -> float:
        """Returns desired speed (-1.0 to 1.0). Positive = forward."""
        now = time.time()
        dt = now - self._prev_time
        if dt <= 0:
            dt = 0.01
        self._prev_time = now

        error = current_distance - self.target_distance

        self._integral += error * dt
        self._integral = max(-5, min(5, self._integral))  # anti-windup

        derivative = (error - self._prev_error) / dt
        self._prev_error = error

        output = (self._kp * error) + (self._ki * self._integral) + (self._kd * derivative)

        return max(-self.max_speed, min(self.max_speed, output))

    def reset(self) -> None:
        self._integral = 0.0
        self._prev_error = 0.0
        self._prev_time = time.time()
