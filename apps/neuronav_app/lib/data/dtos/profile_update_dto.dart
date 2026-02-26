import 'package:json_annotation/json_annotation.dart';

part 'profile_update_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ProfileUpdate {
  final String? displayName;
  final String? sensoryMode;
  final String? preferredInput;
  final bool? hapticEnabled;
  final bool? audioEnabled;
  final double? fontScale;
  final int? currentComplexity;
  final String? lostModeName;
  final String? lostModeAddress;
  final String? lostModePhone;
  final bool? simpleMode;
  final bool? alsoCares;

  const ProfileUpdate({
    this.displayName,
    this.sensoryMode,
    this.preferredInput,
    this.hapticEnabled,
    this.audioEnabled,
    this.fontScale,
    this.currentComplexity,
    this.lostModeName,
    this.lostModeAddress,
    this.lostModePhone,
    this.simpleMode,
    this.alsoCares,
  });

  factory ProfileUpdate.fromJson(Map<String, dynamic> json) =>
      _$ProfileUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileUpdateToJson(this);
}
