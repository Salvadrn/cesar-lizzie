import 'package:json_annotation/json_annotation.dart';

part 'emergency_contact.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class EmergencyContactRow {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;

  const EmergencyContactRow({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isPrimary = false,
  });

  factory EmergencyContactRow.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactRowFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyContactRowToJson(this);
}
