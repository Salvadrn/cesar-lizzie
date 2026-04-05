// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safety_zone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SafetyZoneRow _$SafetyZoneRowFromJson(Map<String, dynamic> json) =>
    SafetyZoneRow(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 200.0,
      zoneType: json['zone_type'] as String,
      alertOnExit: json['alert_on_exit'] as bool? ?? true,
      alertOnEnter: json['alert_on_enter'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );

Map<String, dynamic> _$SafetyZoneRowToJson(SafetyZoneRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius_meters': instance.radiusMeters,
      'zone_type': instance.zoneType,
      'alert_on_exit': instance.alertOnExit,
      'alert_on_enter': instance.alertOnEnter,
      'is_active': instance.isActive,
    };
