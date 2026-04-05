import logging
from .obstacle_map import ObstacleMap

logger = logging.getLogger(__name__)


class VFHPathPlanner:
    """
    Vector Field Histogram path planner.
    Combines desired direction with obstacle avoidance.
    """

    def __init__(
        self,
        obstacle_map: ObstacleMap,
        threshold: float = 500,
        wide_opening: int = 5,
    ):
        self._map = obstacle_map
        self._threshold = threshold
        self._wide_opening = wide_opening

    def plan(self, desired_angle: float, desired_speed: float) -> tuple[float, float]:
        """
        Returns (steering_angle, speed) considering obstacles.
        steering_angle: -45 to +45 degrees
        speed: 0.0 to max_speed
        """
        target_sector = self._map.get_sector_for_angle(desired_angle)

        if not self._map.is_sector_blocked(target_sector, self._threshold):
            steering = self._angle_to_steering(desired_angle)
            return steering, desired_speed

        best_sector = self._find_nearest_open(target_sector)

        if best_sector is None:
            logger.warning("No open path found - stopping")
            return 0.0, 0.0

        best_angle = best_sector * self._map.sector_size
        steering = self._angle_to_steering(best_angle)
        reduced_speed = desired_speed * 0.6
        return steering, reduced_speed

    def _find_nearest_open(self, target: int) -> int | None:
        """Find the nearest unblocked sector to the target sector."""
        n = self._map.sector_count
        for offset in range(1, n // 2):
            for direction in [1, -1]:
                candidate = (target + offset * direction) % n
                if self._is_wide_opening(candidate):
                    return candidate
        return None

    def _is_wide_opening(self, sector: int) -> bool:
        """Check if there's a wide enough opening around this sector."""
        half = self._wide_opening // 2
        for i in range(-half, half + 1):
            s = (sector + i) % self._map.sector_count
            if self._map.is_sector_blocked(s, self._threshold):
                return False
        return True

    def _angle_to_steering(self, angle: float) -> float:
        """Convert world angle to steering (-45 to +45). 0 = forward."""
        diff = angle
        if diff > 180:
            diff -= 360
        return max(-45, min(45, diff))
