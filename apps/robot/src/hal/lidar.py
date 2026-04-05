import asyncio
import logging
from rplidar import RPLidar
from .base import LiDARBase, LidarPoint

logger = logging.getLogger(__name__)


class LiDAR(LiDARBase):
    def __init__(self, port: str = "/dev/ttyUSB0"):
        self._port = port
        self._lidar: RPLidar | None = None
        self._last_scan: list[LidarPoint] = []
        self._nearest: float | None = None
        self._running = False

    async def start(self) -> None:
        self._lidar = RPLidar(self._port)
        self._lidar.start_motor()
        self._running = True
        logger.info(f"LiDAR started on {self._port}")

    async def stop(self) -> None:
        self._running = False
        if self._lidar:
            self._lidar.stop_motor()
            self._lidar.disconnect()
            self._lidar = None
        logger.info("LiDAR stopped")

    async def get_scan(self) -> list[LidarPoint]:
        if not self._lidar or not self._running:
            return []

        scan_data: list[LidarPoint] = []
        try:
            for scan in self._lidar.iter_scans(max_buf_meas=500):
                for _, angle, distance in scan:
                    if distance > 0:
                        scan_data.append(LidarPoint(angle=angle, distance=distance))
                break  # one full scan
        except Exception as e:
            logger.error(f"LiDAR scan error: {e}")
            return self._last_scan

        self._last_scan = scan_data

        if scan_data:
            self._nearest = min(p.distance for p in scan_data)
        else:
            self._nearest = None

        return scan_data

    def get_nearest_obstacle(self) -> float | None:
        return self._nearest
