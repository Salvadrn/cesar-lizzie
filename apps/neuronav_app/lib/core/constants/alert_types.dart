/// Alert type and severity definitions for the NeuroNav alert system.
library;

// ---------------------------------------------------------------------------
// AlertType
// ---------------------------------------------------------------------------

enum AlertType {
  stallDetected,
  zoneExit,
  zoneEnter,
  fallDetected,
  emergency,
  medicationMissed,
  routineOverdue;

  /// The raw string representation sent to / received from the backend.
  String get value {
    switch (this) {
      case AlertType.stallDetected:
        return 'stall_detected';
      case AlertType.zoneExit:
        return 'zone_exit';
      case AlertType.zoneEnter:
        return 'zone_enter';
      case AlertType.fallDetected:
        return 'fall_detected';
      case AlertType.emergency:
        return 'emergency';
      case AlertType.medicationMissed:
        return 'medication_missed';
      case AlertType.routineOverdue:
        return 'routine_overdue';
    }
  }

  /// Human-readable label in Spanish.
  String get displayName {
    switch (this) {
      case AlertType.stallDetected:
        return 'Estancamiento detectado';
      case AlertType.zoneExit:
        return 'Salida de zona';
      case AlertType.zoneEnter:
        return 'Entrada a zona';
      case AlertType.fallDetected:
        return 'Caida detectada';
      case AlertType.emergency:
        return 'Emergencia';
      case AlertType.medicationMissed:
        return 'Medicacion no tomada';
      case AlertType.routineOverdue:
        return 'Rutina atrasada';
    }
  }

  /// The default severity associated with this alert type.
  AlertSeverity get defaultSeverity {
    switch (this) {
      case AlertType.stallDetected:
        return AlertSeverity.warning;
      case AlertType.zoneExit:
        return AlertSeverity.warning;
      case AlertType.zoneEnter:
        return AlertSeverity.info;
      case AlertType.fallDetected:
        return AlertSeverity.critical;
      case AlertType.emergency:
        return AlertSeverity.critical;
      case AlertType.medicationMissed:
        return AlertSeverity.warning;
      case AlertType.routineOverdue:
        return AlertSeverity.info;
    }
  }

  factory AlertType.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'stall_detected':
        return AlertType.stallDetected;
      case 'zone_exit':
        return AlertType.zoneExit;
      case 'zone_enter':
        return AlertType.zoneEnter;
      case 'fall_detected':
        return AlertType.fallDetected;
      case 'emergency':
        return AlertType.emergency;
      case 'medication_missed':
        return AlertType.medicationMissed;
      case 'routine_overdue':
        return AlertType.routineOverdue;
      default:
        return AlertType.emergency;
    }
  }
}

// ---------------------------------------------------------------------------
// AlertSeverity
// ---------------------------------------------------------------------------

enum AlertSeverity {
  info,
  warning,
  critical;

  /// The raw string representation sent to / received from the backend.
  String get value => name;

  /// Human-readable label in Spanish.
  String get displayName {
    switch (this) {
      case AlertSeverity.info:
        return 'Informativo';
      case AlertSeverity.warning:
        return 'Advertencia';
      case AlertSeverity.critical:
        return 'Critico';
    }
  }

  factory AlertSeverity.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'info':
        return AlertSeverity.info;
      case 'warning':
        return AlertSeverity.warning;
      case 'critical':
        return AlertSeverity.critical;
      default:
        return AlertSeverity.info;
    }
  }
}
