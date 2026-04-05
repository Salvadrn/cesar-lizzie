import asyncio
import logging
from bleak import BleakScanner
from .base import BLETrackerBase, BLEDevice
from ..utils.filters import KalmanFilter

logger = logging.getLogger(__name__)


class BLETracker(BLETrackerBase):
    def __init__(self, target_uuid: str, kalman_q: float = 0.1, kalman_r: float = 1.0):
        self._target_uuid = target_uuid.lower()
        self._scanner: BleakScanner | None = None
        self._last_devices: list[BLEDevice] = []
        self._target_rssi: float | None = None
        self._target_found = False
        self._kalman = KalmanFilter(q=kalman_q, r=kalman_r)

    async def start(self) -> None:
        self._scanner = BleakScanner()
        logger.info(f"BLE tracker started, target: {self._target_uuid}")

    async def stop(self) -> None:
        self._scanner = None
        logger.info("BLE tracker stopped")

    async def scan(self) -> list[BLEDevice]:
        if not self._scanner:
            return []

        devices = await BleakScanner.discover(timeout=0.2)
        self._last_devices = [
            BLEDevice(
                address=d.address,
                name=d.name,
                rssi=d.rssi or -100,
            )
            for d in devices
        ]

        target = None
        for d in self._last_devices:
            if d.address.lower() == self._target_uuid:
                target = d
                break

        if target:
            self._target_found = True
            self._target_rssi = self._kalman.update(float(target.rssi))
        else:
            self._target_found = False

        return self._last_devices

    def get_target_rssi(self) -> float | None:
        return self._target_rssi

    def is_target_found(self) -> bool:
        return self._target_found
