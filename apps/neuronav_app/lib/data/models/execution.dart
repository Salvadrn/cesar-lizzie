import 'package:json_annotation/json_annotation.dart';

part 'execution.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ExecutionRow {
  final String id;
  final String routineId;
  final String userId;
  final String status;
  final String startedAt;
  final String? completedAt;
  final int completedSteps;
  final int totalSteps;
  final int errorCount;
  final int stallCount;

  const ExecutionRow({
    required this.id,
    required this.routineId,
    required this.userId,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.completedSteps = 0,
    this.totalSteps = 0,
    this.errorCount = 0,
    this.stallCount = 0,
  });

  factory ExecutionRow.fromJson(Map<String, dynamic> json) =>
      _$ExecutionRowFromJson(json);

  Map<String, dynamic> toJson() => _$ExecutionRowToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class NewStepExecution {
  final String executionId;
  final String stepId;
  final String status;
  final int durationSeconds;
  final int errorCount;
  final int stallCount;
  final int rePromptCount;

  const NewStepExecution({
    required this.executionId,
    required this.stepId,
    required this.status,
    this.durationSeconds = 0,
    this.errorCount = 0,
    this.stallCount = 0,
    this.rePromptCount = 0,
  });

  factory NewStepExecution.fromJson(Map<String, dynamic> json) =>
      _$NewStepExecutionFromJson(json);

  Map<String, dynamic> toJson() => _$NewStepExecutionToJson(this);
}
