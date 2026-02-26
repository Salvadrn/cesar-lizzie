import 'package:json_annotation/json_annotation.dart';

part 'appointment.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AppointmentRow {
  final String id;
  final String userId;
  final String doctorName;
  final String? specialty;
  final String? location;
  final String? notes;
  final String appointmentDate;
  final bool isRecurring;
  final int? recurringMonths;
  final String status;
  final String createdAt;

  const AppointmentRow({
    required this.id,
    required this.userId,
    required this.doctorName,
    this.specialty,
    this.location,
    this.notes,
    required this.appointmentDate,
    this.isRecurring = false,
    this.recurringMonths,
    this.status = 'scheduled',
    required this.createdAt,
  });

  factory AppointmentRow.fromJson(Map<String, dynamic> json) =>
      _$AppointmentRowFromJson(json);

  Map<String, dynamic> toJson() => _$AppointmentRowToJson(this);

  /// Parses [appointmentDate] as an ISO 8601 DateTime.
  /// Returns null if parsing fails.
  DateTime? get date => DateTime.tryParse(appointmentDate);

  /// Whether the appointment date is in the past.
  bool get isPast {
    final d = date;
    if (d == null) return false;
    return d.isBefore(DateTime.now());
  }
}
