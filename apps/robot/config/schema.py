from pydantic import BaseModel


class RobotId(BaseModel):
    id: str
    api_key: str


class ServerConfig(BaseModel):
    url: str = "http://localhost:3001"
    namespace: str = "/robot"
    heartbeat_interval_s: float = 3


class BLEConfig(BaseModel):
    target_uuid: str = ""
    scan_interval_s: float = 0.2
    rssi_kalman_q: float = 0.1
    rssi_kalman_r: float = 1.0


class LidarConfig(BaseModel):
    port: str = "/dev/ttyUSB0"
    enabled: bool = True


class PinPair(BaseModel):
    trigger_pin: int
    echo_pin: int


class UltrasonicConfig(BaseModel):
    front_left: PinPair
    front_right: PinPair
    emergency_stop_cm: float = 30
    poll_rate_hz: float = 20


class SparkMaxMotor(BaseModel):
    pin: int = 18


class MotorsConfig(BaseModel):
    drive: SparkMaxMotor = SparkMaxMotor(pin=18)
    steering: SparkMaxMotor = SparkMaxMotor(pin=12)


class PIDConfig(BaseModel):
    kp: float = 0.8
    ki: float = 0.05
    kd: float = 0.2


class VFHConfig(BaseModel):
    sector_count: int = 72
    threshold: float = 500
    wide_opening: int = 5


class NavigationConfig(BaseModel):
    follow_distance_m: float = 1.5
    max_speed: float = 0.5
    pid: PIDConfig = PIDConfig()
    vfh: VFHConfig = VFHConfig()


class SafetyConfig(BaseModel):
    watchdog_timeout_s: float = 5
    max_cpu_temp: float = 80
    min_battery_percent: float = 10


class VoiceConfig(BaseModel):
    enabled: bool = True
    jarvis_url: str = ""
    jarvis_api_key: str = ""
    openai_api_key: str = ""
    user_id: str = ""
    tts_rate: int = 150
    language: str = "es"


class LoopConfig(BaseModel):
    rate_hz: float = 10
    telemetry_rate_hz: float = 2
    mock: bool = False


class AppConfig(BaseModel):
    robot: RobotId
    server: ServerConfig = ServerConfig()
    ble: BLEConfig = BLEConfig()
    lidar: LidarConfig = LidarConfig()
    ultrasonic: UltrasonicConfig
    motors: MotorsConfig = MotorsConfig()
    navigation: NavigationConfig = NavigationConfig()
    safety: SafetyConfig = SafetyConfig()
    voice: VoiceConfig = VoiceConfig()
    loop: LoopConfig = LoopConfig()
