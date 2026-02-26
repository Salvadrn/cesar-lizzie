import 'package:json_annotation/json_annotation.dart';

part 'safety_zone.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SafetyZoneRow {
  final String id;
  final String userId;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String zoneType;
  final bool alertOnExit;
  final bool alertOnEnter;
  final bool isActive;

  const SafetyZoneRow({
    required this.id,
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200.0,
    required this.zoneType,
    this.alertOnExit = true,
    this.alertOnEnter = false,
    this.isActive = true,
  });

  factory SafetyZoneRow.fromJson(Map<String, dynamic> json) =>
      _$SafetyZoneRowFromJson(json);

  Map<String, dynamic> toJson() => _$SafetyZoneRowToJson(this);
}
