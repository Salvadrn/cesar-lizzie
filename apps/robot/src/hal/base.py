from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass
class BLEDevice:
    address: str
    name: str | None
    rssi: int


@dataclass
class LidarPoint:
    angle: float  # degrees 0-360
    distance: float  # millimeters


class BLETrackerBase(ABC):
    @abstractmethod
    async def start(self) -> None:
        pass

    @abstractmethod
    async def stop(self) -> None:
        pass

    @abstractmethod
    async def scan(self) -> list[BLEDevice]:
        pass

    @abstractmethod
    def get_target_rssi(self) -> float | None:
        """Returns filtered RSSI for the configured target, or None if not found."""
        pass

    @abstractmethod
    def is_target_found(self) -> bool:
        pass


class LiDARBase(ABC):
    @abstractmethod
    async def start(self) -> None:
        pass

    @abstractmethod
    async def stop(self) -> None:
        pass

    @abstractmethod
    async def get_scan(self) -> list[LidarPoint]:
        """Returns a full 360-degree scan as list of (angle, distance) points."""
        pass

    @abstractmethod
    def get_nearest_obstacle(self) -> float | None:
        """Returns distance in mm to the nearest detected obstacle."""
        pass


class UltrasonicBase(ABC):
    @abstractmethod
    def start(self) -> None:
        pass

    @abstractmethod
    def stop(self) -> None:
        pass

    @abstractmethod
    def get_distance_cm(self, sensor: str) -> float:
        """Returns current distance in cm for the named sensor."""
        pass

    @abstractmethod
    def is_emergency(self) -> bool:
        """Returns True if any sensor reads below emergency threshold."""
        pass


class MotorControllerBase(ABC):
    @abstractmethod
    def start(self) -> None:
        pass

    @abstractmethod
    def stop(self) -> None:
        pass

    @abstractmethod
    def set_drive(self, speed: float) -> None:
        """Set drive motor speed. Range: -1.0 (reverse) to 1.0 (forward)."""
        pass

    @abstractmethod
    def set_steering(self, angle: float) -> None:
        """Set steering angle. Range: -45 to +45 degrees."""
        pass

    @abstractmethod
    def emergency_stop(self) -> None:
        """Immediately cut all motor power."""
        pass

    @abstractmethod
    def get_speed(self) -> float:
        pass

    @abstractmethod
    def get_steering_angle(self) -> float:
        pass
