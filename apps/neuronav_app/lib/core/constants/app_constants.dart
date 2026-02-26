/// Core application constants for NeuroNav.
///
/// Ported from Swift AppConstants to Dart/Flutter.
library;

// ---------------------------------------------------------------------------
// Supabase
// ---------------------------------------------------------------------------

const String supabaseUrl = 'https://fornsbnwtrorqkmfabri.supabase.co';

const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvcm5zYm53dHJvcnFrbWZhYnJpIiw'
    'icm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MTQ1MjIsImV4cCI6MjA4NjQ5MDUyMn0.'
    'kp3ywqW-4S4M8tysNRGLLVgBSXQkwRswPRefEuRp_u8';

// ---------------------------------------------------------------------------
// Platform identifiers
// ---------------------------------------------------------------------------

const String appGroupIdentifier = 'group.com.neuronav.shared';
const String keychainService = 'com.neuronav.keychain';

// ---------------------------------------------------------------------------
// UserRole
// ---------------------------------------------------------------------------

enum UserRole {
  guest,
  patient,
  caregiver,
  family,
  admin;

  /// Human-readable name in Spanish.
  String get displayName {
    switch (this) {
      case UserRole.guest:
        return 'Invitado';
      case UserRole.patient:
        return 'Paciente';
      case UserRole.caregiver:
        return 'Cuidador';
      case UserRole.family:
        return 'Familiar';
      case UserRole.admin:
        return 'Administrador';
    }
  }

  /// Whether the role is allowed to create / edit / delete data.
  bool get canModifyData {
    switch (this) {
      case UserRole.guest:
        return false;
      case UserRole.patient:
        return true;
      case UserRole.caregiver:
        return true;
      case UserRole.family:
        return false;
      case UserRole.admin:
        return true;
    }
  }

  /// Build a [UserRole] from a raw string coming from the backend.
  ///
  /// The backend may send `"user"` which maps to [UserRole.patient].
  /// Unknown strings default to [UserRole.guest].
  factory UserRole.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'guest':
        return UserRole.guest;
      case 'patient':
      case 'user':
        return UserRole.patient;
      case 'caregiver':
        return UserRole.caregiver;
      case 'family':
        return UserRole.family;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.guest;
    }
  }
}

// ---------------------------------------------------------------------------
// RoutineCategory
// ---------------------------------------------------------------------------

enum RoutineCategory {
  cooking,
  hygiene,
  laundry,
  medication,
  transit,
  shopping,
  cleaning,
  social,
  custom;

  /// Material Icons name suitable for use with [Icons] or icon fonts.
  String get icon {
    switch (this) {
      case RoutineCategory.cooking:
        return 'restaurant';
      case RoutineCategory.hygiene:
        return 'shower';
      case RoutineCategory.laundry:
        return 'local_laundry_service';
      case RoutineCategory.medication:
        return 'medication';
      case RoutineCategory.transit:
        return 'directions_bus';
      case RoutineCategory.shopping:
        return 'shopping_cart';
      case RoutineCategory.cleaning:
        return 'cleaning_services';
      case RoutineCategory.social:
        return 'people';
      case RoutineCategory.custom:
        return 'tune';
    }
  }

  /// Human-readable label in Spanish.
  String get displayName {
    switch (this) {
      case RoutineCategory.cooking:
        return 'Cocina';
      case RoutineCategory.hygiene:
        return 'Higiene';
      case RoutineCategory.laundry:
        return 'Lavanderia';
      case RoutineCategory.medication:
        return 'Medicacion';
      case RoutineCategory.transit:
        return 'Transporte';
      case RoutineCategory.shopping:
        return 'Compras';
      case RoutineCategory.cleaning:
        return 'Limpieza';
      case RoutineCategory.social:
        return 'Social';
      case RoutineCategory.custom:
        return 'Personalizada';
    }
  }

  /// Build a [RoutineCategory] from a raw backend string.
  factory RoutineCategory.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cooking':
        return RoutineCategory.cooking;
      case 'hygiene':
        return RoutineCategory.hygiene;
      case 'laundry':
        return RoutineCategory.laundry;
      case 'medication':
        return RoutineCategory.medication;
      case 'transit':
        return RoutineCategory.transit;
      case 'shopping':
        return RoutineCategory.shopping;
      case 'cleaning':
        return RoutineCategory.cleaning;
      case 'social':
        return RoutineCategory.social;
      case 'custom':
      default:
        return RoutineCategory.custom;
    }
  }
}

// ---------------------------------------------------------------------------
// ScheduleType
// ---------------------------------------------------------------------------

enum ScheduleType {
  daily,
  weekdays,
  weekends,
  specific,
  once;

  String get value {
    return name;
  }

  factory ScheduleType.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'daily':
        return ScheduleType.daily;
      case 'weekdays':
        return ScheduleType.weekdays;
      case 'weekends':
        return ScheduleType.weekends;
      case 'specific':
        return ScheduleType.specific;
      case 'once':
        return ScheduleType.once;
      default:
        return ScheduleType.daily;
    }
  }
}

// ---------------------------------------------------------------------------
// ExecutionStatus
// ---------------------------------------------------------------------------

enum ExecutionStatus {
  inProgress,
  completed,
  aborted,
  paused;

  /// The raw string sent to / received from the backend.
  String get value {
    switch (this) {
      case ExecutionStatus.inProgress:
        return 'in_progress';
      case ExecutionStatus.completed:
        return 'completed';
      case ExecutionStatus.aborted:
        return 'aborted';
      case ExecutionStatus.paused:
        return 'paused';
    }
  }

  factory ExecutionStatus.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'in_progress':
        return ExecutionStatus.inProgress;
      case 'completed':
        return ExecutionStatus.completed;
      case 'aborted':
        return ExecutionStatus.aborted;
      case 'paused':
        return ExecutionStatus.paused;
      default:
        return ExecutionStatus.inProgress;
    }
  }
}

// ---------------------------------------------------------------------------
// StepExecutionStatus
// ---------------------------------------------------------------------------

enum StepExecutionStatus {
  pending,
  inProgress,
  completed,
  skipped,
  needsHelp;

  /// The raw string sent to / received from the backend.
  String get value {
    switch (this) {
      case StepExecutionStatus.pending:
        return 'pending';
      case StepExecutionStatus.inProgress:
        return 'in_progress';
      case StepExecutionStatus.completed:
        return 'completed';
      case StepExecutionStatus.skipped:
        return 'skipped';
      case StepExecutionStatus.needsHelp:
        return 'needs_help';
    }
  }

  factory StepExecutionStatus.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return StepExecutionStatus.pending;
      case 'in_progress':
        return StepExecutionStatus.inProgress;
      case 'completed':
        return StepExecutionStatus.completed;
      case 'skipped':
        return StepExecutionStatus.skipped;
      case 'needs_help':
        return StepExecutionStatus.needsHelp;
      default:
        return StepExecutionStatus.pending;
    }
  }
}
