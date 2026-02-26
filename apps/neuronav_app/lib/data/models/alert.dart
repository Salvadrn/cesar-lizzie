import 'package:json_annotation/json_annotation.dart';

part 'alert.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AlertRow {
  final String id;
  final String alertType;
  final String severity;
  final String title;
  final String? message;
  final bool isRead;
  final String createdAt;

  const AlertRow({
    required this.id,
    required this.alertType,
    this.severity = 'info',
    required this.title,
    this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory AlertRow.fromJson(Map<String, dynamic> json) =>
      _$AlertRowFromJson(json);

  Map<String, dynamic> toJson() => _$AlertRowToJson(this);
}
