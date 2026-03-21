// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppointmentRow _$AppointmentRowFromJson(Map<String, dynamic> json) =>
    AppointmentRow(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      doctorName: json['doctor_name'] as String,
      specialty: json['specialty'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      appointmentDate: json['appointment_date'] as String,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringMonths: (json['recurring_months'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'scheduled',
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$AppointmentRowToJson(AppointmentRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'doctor_name': instance.doctorName,
      'specialty': instance.specialty,
      'location': instance.location,
      'notes': instance.notes,
      'appointment_date': instance.appointmentDate,
      'is_recurring': instance.isRecurring,
      'recurring_months': instance.recurringMonths,
      'status': instance.status,
      'created_at': instance.createdAt,
    };
