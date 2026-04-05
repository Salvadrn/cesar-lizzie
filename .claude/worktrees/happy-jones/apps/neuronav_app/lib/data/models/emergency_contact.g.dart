// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_contact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmergencyContactRow _$EmergencyContactRowFromJson(Map<String, dynamic> json) =>
    EmergencyContactRow(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      relationship: json['relationship'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
    );

Map<String, dynamic> _$EmergencyContactRowToJson(
  EmergencyContactRow instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'phone': instance.phone,
  'relationship': instance.relationship,
  'is_primary': instance.isPrimary,
};
