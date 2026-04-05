export type RobotState =
  | 'idle'
  | 'following'
  | 'paused'
  | 'error'
  | 'emergency_stop'
  | 'disconnected';

export type RobotStatus = 'online' | 'offline' | 'error' | 'emergency_stop';

export type RobotCommandType =
  | 'start'
  | 'stop'
  | 'pause'
  | 'resume'
  | 'update_config'
  | 'emergency_stop'
  | 'reset';

export interface Robot {
  id: string;
  userId: string;
  serialNumber: string;
  name: string;
  status: RobotStatus;
  lastSeenAt?: string;
  firmwareVersion?: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface RobotConfig {
  id: string;
  robotId: string;
  followDistanceM: number;
  maxSpeed: number;
  emergencyStopCm: number;
  telemetryRateHz: number;
  bleTargetUuid: string;
  lidarEnabled: boolean;
}

export interface RobotTelemetry {
  robotId: string;
  timestamp: string;
  state: RobotState;
  batteryPercent: number;
  bleEstimatedDistance: number | null;
  bleTargetFound: boolean;
  lidarNearestObstacle: number | null;
  ultrasonicFrontLeft: number | null;
  ultrasonicFrontRight: number | null;
  motorSpeed: number;
  steeringAngle: number;
  wifiRssi: number;
  cpuTemp: number;
  uptimeSeconds: number;
}

export interface RobotCommand {
  commandType: RobotCommandType;
  payload?: Record<string, unknown>;
  issuedBy: string;
  issuedAt: string;
}

export type RobotAlertType =
  | 'robot_emergency_stop'
  | 'robot_disconnected'
  | 'robot_low_battery'
  | 'robot_obstacle_stuck'
  | 'robot_target_lost';
