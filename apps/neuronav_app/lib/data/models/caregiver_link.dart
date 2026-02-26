import 'package:json_annotation/json_annotation.dart';

part 'caregiver_link.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class LinkedProfileInfo {
  final String displayName;
  final String? email;
  final int currentComplexity;
  final String sensoryMode;

  const LinkedProfileInfo({
    required this.displayName,
    this.email,
    this.currentComplexity = 3,
    this.sensoryMode = 'default',
  });

  factory LinkedProfileInfo.fromJson(Map<String, dynamic> json) =>
      _$LinkedProfileInfoFromJson(json);

  Map<String, dynamic> toJson() => _$LinkedProfileInfoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CaregiverLinkRow {
  final String id;
  final String userId;
  final String caregiverId;
  final String? relationship;
  final String status;
  final String? inviteCode;
  final bool permViewActivity;
  final bool permEditRoutines;
  final bool permViewLocation;
  final bool permViewMedications;
  final bool permViewEmergency;
  final String createdAt;
  final LinkedProfileInfo? profiles;

  const CaregiverLinkRow({
    required this.id,
    required this.userId,
    required this.caregiverId,
    this.relationship,
    this.status = 'pending',
    this.inviteCode,
    this.permViewActivity = false,
    this.permEditRoutines = false,
    this.permViewLocation = false,
    this.permViewMedications = false,
    this.permViewEmergency = false,
    required this.createdAt,
    this.profiles,
  });

  factory CaregiverLinkRow.fromJson(Map<String, dynamic> json) =>
      _$CaregiverLinkRowFromJson(json);

  Map<String, dynamic> toJson() => _$CaregiverLinkRowToJson(this);
}
