// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MedicationRow _$MedicationRowFromJson(Map<String, dynamic> json) =>
    MedicationRow(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
      takenToday: json['taken_today'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      reminderOffsets: (json['reminder_offsets'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$MedicationRowToJson(MedicationRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'dosage': instance.dosage,
      'hour': instance.hour,
      'minute': instance.minute,
      'taken_today': instance.takenToday,
      'is_active': instance.isActive,
      'reminder_offsets': instance.reminderOffsets,
    };
