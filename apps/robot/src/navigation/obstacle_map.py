import math
import logging
from ..hal.base import LidarPoint

logger = logging.getLogger(__name__)


class ObstacleMap:
    """Converts LiDAR scans into a polar histogram for VFH navigation."""

    def __init__(self, sector_count: int = 72):
        self.sector_count = sector_count
        self.sector_size = 360.0 / sector_count
        self._histogram: list[float] = [0.0] * sector_count

    def update(self, scan: list[LidarPoint]) -> None:
        self._histogram = [0.0] * self.sector_count

        for point in scan:
            sector = int(point.angle / self.sector_size) % self.sector_count
            certainty = max(0, 5000 - point.distance) / 5000  # closer = higher
            self._histogram[sector] = max(self._histogram[sector], certainty * 1000)

    @property
    def histogram(self) -> list[float]:
        return self._histogram

    def is_sector_blocked(self, sector: int, threshold: float = 500) -> bool:
        return self._histogram[sector % self.sector_count] > threshold

    def get_sector_for_angle(self, angle: float) -> int:
        normalized = angle % 360
        return int(normalized / self.sector_size) % self.sector_count
