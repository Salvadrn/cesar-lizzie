// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertRow _$AlertRowFromJson(Map<String, dynamic> json) => AlertRow(
  id: json['id'] as String,
  alertType: json['alert_type'] as String,
  severity: json['severity'] as String? ?? 'info',
  title: json['title'] as String,
  message: json['message'] as String?,
  isRead: json['is_read'] as bool? ?? false,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$AlertRowToJson(AlertRow instance) => <String, dynamic>{
  'id': instance.id,
  'alert_type': instance.alertType,
  'severity': instance.severity,
  'title': instance.title,
  'message': instance.message,
  'is_read': instance.isRead,
  'created_at': instance.createdAt,
};
