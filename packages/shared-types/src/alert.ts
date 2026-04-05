export type AlertType =
  | 'geofence_exit'
  | 'geofence_enter'
  | 'routine_abandoned'
  | 'prolonged_stall'
  | 'emergency_activated'
  | 'lost_mode_activated'
  | 'missed_routine'
  | 'low_completion_trend'
  | 'robot_emergency_stop'
  | 'robot_disconnected'
  | 'robot_low_battery'
  | 'robot_obstacle_stuck'
  | 'robot_target_lost';

export type AlertSeverity = 'info' | 'warning' | 'critical';

export interface Alert {
  id: string;
  userId: string;
  caregiverId?: string;
  alertType: AlertType;
  severity: AlertSeverity;
  title: string;
  message?: string;
  metadata?: Record<string, unknown>;
  isRead: boolean;
  acknowledgedAt?: string;
  createdAt: string;
}
