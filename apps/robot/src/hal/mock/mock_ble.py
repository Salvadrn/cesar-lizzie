import random
import logging
from ..base import BLETrackerBase, BLEDevice
from ...utils.filters import KalmanFilter

logger = logging.getLogger(__name__)


class MockBLETracker(BLETrackerBase):
    def __init__(self, target_uuid: str = "mock-target", kalman_q: float = 0.1, kalman_r: float = 1.0):
        self._target_uuid = target_uuid
        self._kalman = KalmanFilter(q=kalman_q, r=kalman_r, initial=-60.0)
        self._target_rssi: float | None = None
        self._target_found = True
        self._base_rssi = -60.0

    async def start(self) -> None:
        logger.info("[MOCK] BLE tracker started")

    async def stop(self) -> None:
        logger.info("[MOCK] BLE tracker stopped")

    async def scan(self) -> list[BLEDevice]:
        noise = random.gauss(0, 3)
        raw_rssi = int(self._base_rssi + noise)
        self._target_rssi = self._kalman.update(float(raw_rssi))
        self._target_found = random.random() > 0.05  # 95% detection rate

        return [
            BLEDevice(address=self._target_uuid, name="MockiPhone", rssi=raw_rssi),
            BLEDevice(address="aa:bb:cc:dd:ee:ff", name="OtherDevice", rssi=-80),
        ]

    def get_target_rssi(self) -> float | None:
        return self._target_rssi if self._target_found else None

    def is_target_found(self) -> bool:
        return self._target_found

    def set_simulated_distance(self, meters: float) -> None:
        """Helper: set base RSSI based on distance approximation."""
        self._base_rssi = -40 - (20 * (meters ** 0.5))
