// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caregiver_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkedProfileInfo _$LinkedProfileInfoFromJson(Map<String, dynamic> json) =>
    LinkedProfileInfo(
      displayName: json['display_name'] as String,
      email: json['email'] as String?,
      currentComplexity: (json['current_complexity'] as num?)?.toInt() ?? 3,
      sensoryMode: json['sensory_mode'] as String? ?? 'default',
    );

Map<String, dynamic> _$LinkedProfileInfoToJson(LinkedProfileInfo instance) =>
    <String, dynamic>{
      'display_name': instance.displayName,
      'email': instance.email,
      'current_complexity': instance.currentComplexity,
      'sensory_mode': instance.sensoryMode,
    };

CaregiverLinkRow _$CaregiverLinkRowFromJson(Map<String, dynamic> json) =>
    CaregiverLinkRow(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      caregiverId: json['caregiver_id'] as String,
      relationship: json['relationship'] as String?,
      status: json['status'] as String? ?? 'pending',
      inviteCode: json['invite_code'] as String?,
      permViewActivity: json['perm_view_activity'] as bool? ?? false,
      permEditRoutines: json['perm_edit_routines'] as bool? ?? false,
      permViewLocation: json['perm_view_location'] as bool? ?? false,
      permViewMedications: json['perm_view_medications'] as bool? ?? false,
      permViewEmergency: json['perm_view_emergency'] as bool? ?? false,
      createdAt: json['created_at'] as String,
      profiles: json['profiles'] == null
          ? null
          : LinkedProfileInfo.fromJson(
              json['profiles'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$CaregiverLinkRowToJson(CaregiverLinkRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'caregiver_id': instance.caregiverId,
      'relationship': instance.relationship,
      'status': instance.status,
      'invite_code': instance.inviteCode,
      'perm_view_activity': instance.permViewActivity,
      'perm_edit_routines': instance.permEditRoutines,
      'perm_view_location': instance.permViewLocation,
      'perm_view_medications': instance.permViewMedications,
      'perm_view_emergency': instance.permViewEmergency,
      'created_at': instance.createdAt,
      'profiles': instance.profiles,
    };
