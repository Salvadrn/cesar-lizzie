export const ALERT_SEVERITY_ORDER = {
  info: 0,
  warning: 1,
  critical: 2,
} as const;

export const ALERT_TYPE_CONFIG = {
  geofence_exit: { severity: 'critical' as const, emoji: '📍' },
  geofence_enter: { severity: 'info' as const, emoji: '📍' },
  routine_abandoned: { severity: 'warning' as const, emoji: '⚠️' },
  prolonged_stall: { severity: 'warning' as const, emoji: '⏱️' },
  emergency_activated: { severity: 'critical' as const, emoji: '🚨' },
  lost_mode_activated: { severity: 'critical' as const, emoji: '🆘' },
  missed_routine: { severity: 'info' as const, emoji: '📋' },
  low_completion_trend: { severity: 'warning' as const, emoji: '📉' },
  robot_emergency_stop: { severity: 'critical' as const, emoji: '🛑' },
  robot_disconnected: { severity: 'warning' as const, emoji: '🤖' },
  robot_low_battery: { severity: 'warning' as const, emoji: '🔋' },
  robot_obstacle_stuck: { severity: 'warning' as const, emoji: '⚠️' },
  robot_target_lost: { severity: 'info' as const, emoji: '📡' },
} as const;
