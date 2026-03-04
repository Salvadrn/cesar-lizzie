// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_update_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileUpdate _$ProfileUpdateFromJson(Map<String, dynamic> json) =>
    ProfileUpdate(
      displayName: json['display_name'] as String?,
      sensoryMode: json['sensory_mode'] as String?,
      preferredInput: json['preferred_input'] as String?,
      hapticEnabled: json['haptic_enabled'] as bool?,
      audioEnabled: json['audio_enabled'] as bool?,
      fontScale: (json['font_scale'] as num?)?.toDouble(),
      currentComplexity: (json['current_complexity'] as num?)?.toInt(),
      lostModeName: json['lost_mode_name'] as String?,
      lostModeAddress: json['lost_mode_address'] as String?,
      lostModePhone: json['lost_mode_phone'] as String?,
      simpleMode: json['simple_mode'] as bool?,
      alsoCares: json['also_cares'] as bool?,
    );

Map<String, dynamic> _$ProfileUpdateToJson(
  ProfileUpdate instance,
) => <String, dynamic>{
  if (instance.displayName case final value?) 'display_name': value,
  if (instance.sensoryMode case final value?) 'sensory_mode': value,
  if (instance.preferredInput case final value?) 'preferred_input': value,
  if (instance.hapticEnabled case final value?) 'haptic_enabled': value,
  if (instance.audioEnabled case final value?) 'audio_enabled': value,
  if (instance.fontScale case final value?) 'font_scale': value,
  if (instance.currentComplexity case final value?) 'current_complexity': value,
  if (instance.lostModeName case final value?) 'lost_mode_name': value,
  if (instance.lostModeAddress case final value?) 'lost_mode_address': value,
  if (instance.lostModePhone case final value?) 'lost_mode_phone': value,
  if (instance.simpleMode case final value?) 'simple_mode': value,
  if (instance.alsoCares case final value?) 'also_cares': value,
};
