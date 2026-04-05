// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileData _$ProfileDataFromJson(Map<String, dynamic> json) => ProfileData(
  id: json['id'] as String,
  displayName: json['display_name'] as String,
  email: json['email'] as String?,
  role: json['role'] as String? ?? 'user',
  currentComplexity: (json['current_complexity'] as num?)?.toInt() ?? 3,
  complexityFloor: (json['complexity_floor'] as num?)?.toInt() ?? 1,
  complexityCeiling: (json['complexity_ceiling'] as num?)?.toInt() ?? 5,
  sensoryMode: json['sensory_mode'] as String? ?? 'default',
  preferredInput: json['preferred_input'] as String? ?? 'touch',
  hapticEnabled: json['haptic_enabled'] as bool? ?? true,
  audioEnabled: json['audio_enabled'] as bool? ?? true,
  fontScale: (json['font_scale'] as num?)?.toDouble() ?? 1.0,
  lostModeName: json['lost_mode_name'] as String?,
  lostModeAddress: json['lost_mode_address'] as String?,
  lostModePhone: json['lost_mode_phone'] as String?,
  lostModePhotoUrl: json['lost_mode_photo_url'] as String?,
  totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
  totalErrors: (json['total_errors'] as num?)?.toInt() ?? 0,
  avgResponseTime: (json['avg_response_time'] as num?)?.toDouble() ?? 0.0,
  lastSessionAt: json['last_session_at'] as String?,
  simpleMode: json['simple_mode'] as bool? ?? false,
  alsoCares: json['also_cares'] as bool? ?? false,
);

Map<String, dynamic> _$ProfileDataToJson(ProfileData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display_name': instance.displayName,
      'email': instance.email,
      'role': instance.role,
      'current_complexity': instance.currentComplexity,
      'complexity_floor': instance.complexityFloor,
      'complexity_ceiling': instance.complexityCeiling,
      'sensory_mode': instance.sensoryMode,
      'preferred_input': instance.preferredInput,
      'haptic_enabled': instance.hapticEnabled,
      'audio_enabled': instance.audioEnabled,
      'font_scale': instance.fontScale,
      'lost_mode_name': instance.lostModeName,
      'lost_mode_address': instance.lostModeAddress,
      'lost_mode_phone': instance.lostModePhone,
      'lost_mode_photo_url': instance.lostModePhotoUrl,
      'total_sessions': instance.totalSessions,
      'total_errors': instance.totalErrors,
      'avg_response_time': instance.avgResponseTime,
      'last_session_at': instance.lastSessionAt,
      'simple_mode': instance.simpleMode,
      'also_cares': instance.alsoCares,
    };
