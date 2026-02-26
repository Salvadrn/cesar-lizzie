import 'package:json_annotation/json_annotation.dart';

part 'medication.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class MedicationRow {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final int hour;
  final int minute;
  final bool takenToday;
  final bool isActive;
  final List<int>? reminderOffsets;

  const MedicationRow({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.hour,
    required this.minute,
    this.takenToday = false,
    this.isActive = true,
    this.reminderOffsets,
  });

  MedicationRow copyWith({
    String? id,
    String? userId,
    String? name,
    String? dosage,
    int? hour,
    int? minute,
    bool? takenToday,
    bool? isActive,
    List<int>? reminderOffsets,
  }) {
    return MedicationRow(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      takenToday: takenToday ?? this.takenToday,
      isActive: isActive ?? this.isActive,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
    );
  }

  factory MedicationRow.fromJson(Map<String, dynamic> json) =>
      _$MedicationRowFromJson(json);

  Map<String, dynamic> toJson() => _$MedicationRowToJson(this);
}
