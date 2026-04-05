class KalmanFilter:
    """Simple 1D Kalman filter for RSSI smoothing."""

    def __init__(self, q: float = 0.1, r: float = 1.0, initial: float = -70.0):
        self._q = q  # process noise
        self._r = r  # measurement noise
        self._x = initial  # estimated value
        self._p = 1.0  # estimation error

    def update(self, measurement: float) -> float:
        self._p += self._q
        k = self._p / (self._p + self._r)
        self._x += k * (measurement - self._x)
        self._p *= (1 - k)
        return self._x

    @property
    def value(self) -> float:
        return self._x


class MovingAverage:
    """Simple moving average filter."""

    def __init__(self, window: int = 5):
        self._window = window
        self._values: list[float] = []

    def update(self, value: float) -> float:
        self._values.append(value)
        if len(self._values) > self._window:
            self._values.pop(0)
        return sum(self._values) / len(self._values)

    @property
    def value(self) -> float:
        if not self._values:
            return 0.0
        return sum(self._values) / len(self._values)
