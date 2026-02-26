import 'package:json_annotation/json_annotation.dart';

part 'routine.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StepRow {
  final String id;
  final int stepOrder;
  final String title;
  final String instruction;
  final String? instructionSimple;
  final String? instructionDetailed;
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final int durationHint;
  final bool checkpoint;

  const StepRow({
    required this.id,
    required this.stepOrder,
    required this.title,
    required this.instruction,
    this.instructionSimple,
    this.instructionDetailed,
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.durationHint = 60,
    this.checkpoint = false,
  });

  factory StepRow.fromJson(Map<String, dynamic> json) =>
      _$StepRowFromJson(json);

  Map<String, dynamic> toJson() => _$StepRowToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RoutineRow {
  final String id;
  final String title;
  final String? description;
  final String category;
  final bool isActive;
  final String? assignedTo;
  final int? complexityLevel;
  final List<StepRow>? routineSteps;
  final String? createdAt;

  const RoutineRow({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.isActive = true,
    this.assignedTo,
    this.complexityLevel,
    this.routineSteps,
    this.createdAt,
  });

  factory RoutineRow.fromJson(Map<String, dynamic> json) =>
      _$RoutineRowFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineRowToJson(this);
}
