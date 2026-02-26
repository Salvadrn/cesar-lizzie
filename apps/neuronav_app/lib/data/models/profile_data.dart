import 'package:json_annotation/json_annotation.dart';

part 'profile_data.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProfileData {
  final String id;
  final String displayName;
  final String? email;
  final String role;
  final int currentComplexity;
  final int complexityFloor;
  final int complexityCeiling;
  final String sensoryMode;
  final String preferredInput;
  final bool hapticEnabled;
  final bool audioEnabled;
  final double fontScale;
  final String? lostModeName;
  final String? lostModeAddress;
  final String? lostModePhone;
  final String? lostModePhotoUrl;
  final int totalSessions;
  final int totalErrors;
  final double avgResponseTime;
  final String? lastSessionAt;
  final bool simpleMode;
  final bool alsoCares;

  const ProfileData({
    required this.id,
    required this.displayName,
    this.email,
    this.role = 'user',
    this.currentComplexity = 3,
    this.complexityFloor = 1,
    this.complexityCeiling = 5,
    this.sensoryMode = 'default',
    this.preferredInput = 'touch',
    this.hapticEnabled = true,
    this.audioEnabled = true,
    this.fontScale = 1.0,
    this.lostModeName,
    this.lostModeAddress,
    this.lostModePhone,
    this.lostModePhotoUrl,
    this.totalSessions = 0,
    this.totalErrors = 0,
    this.avgResponseTime = 0.0,
    this.lastSessionAt,
    this.simpleMode = false,
    this.alsoCares = false,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) =>
      _$ProfileDataFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileDataToJson(this);

  ProfileData copyWith({
    String? id,
    String? displayName,
    String? email,
    String? role,
    int? currentComplexity,
    int? complexityFloor,
    int? complexityCeiling,
    String? sensoryMode,
    String? preferredInput,
    bool? hapticEnabled,
    bool? audioEnabled,
    double? fontScale,
    String? lostModeName,
    String? lostModeAddress,
    String? lostModePhone,
    String? lostModePhotoUrl,
    int? totalSessions,
    int? totalErrors,
    double? avgResponseTime,
    String? lastSessionAt,
    bool? simpleMode,
    bool? alsoCares,
  }) {
    return ProfileData(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      currentComplexity: currentComplexity ?? this.currentComplexity,
      complexityFloor: complexityFloor ?? this.complexityFloor,
      complexityCeiling: complexityCeiling ?? this.complexityCeiling,
      sensoryMode: sensoryMode ?? this.sensoryMode,
      preferredInput: preferredInput ?? this.preferredInput,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      fontScale: fontScale ?? this.fontScale,
      lostModeName: lostModeName ?? this.lostModeName,
      lostModeAddress: lostModeAddress ?? this.lostModeAddress,
      lostModePhone: lostModePhone ?? this.lostModePhone,
      lostModePhotoUrl: lostModePhotoUrl ?? this.lostModePhotoUrl,
      totalSessions: totalSessions ?? this.totalSessions,
      totalErrors: totalErrors ?? this.totalErrors,
      avgResponseTime: avgResponseTime ?? this.avgResponseTime,
      lastSessionAt: lastSessionAt ?? this.lastSessionAt,
      simpleMode: simpleMode ?? this.simpleMode,
      alsoCares: alsoCares ?? this.alsoCares,
    );
  }
}
