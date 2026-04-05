import random
import math
import logging
from ..base import LiDARBase, LidarPoint

logger = logging.getLogger(__name__)


class MockLiDAR(LiDARBase):
    def __init__(self):
        self._last_scan: list[LidarPoint] = []
        self._nearest: float | None = None
        self._obstacles: list[tuple[float, float]] = []  # (angle, distance_mm)

    async def start(self) -> None:
        logger.info("[MOCK] LiDAR started")

    async def stop(self) -> None:
        logger.info("[MOCK] LiDAR stopped")

    async def get_scan(self) -> list[LidarPoint]:
        scan: list[LidarPoint] = []
        for angle in range(0, 360, 5):
            base_distance = 3000.0 + random.gauss(0, 50)

            for obs_angle, obs_dist in self._obstacles:
                if abs(angle - obs_angle) < 10:
                    base_distance = min(base_distance, obs_dist + random.gauss(0, 10))

            scan.append(LidarPoint(angle=float(angle), distance=max(50, base_distance)))

        self._last_scan = scan
        self._nearest = min(p.distance for p in scan) if scan else None
        return scan

    def get_nearest_obstacle(self) -> float | None:
        return self._nearest

    def add_obstacle(self, angle: float, distance_mm: float) -> None:
        """Add a simulated obstacle for testing."""
        self._obstacles.append((angle, distance_mm))

    def clear_obstacles(self) -> None:
        self._obstacles.clear()
