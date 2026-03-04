// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExecutionRow _$ExecutionRowFromJson(Map<String, dynamic> json) => ExecutionRow(
  id: json['id'] as String,
  routineId: json['routine_id'] as String,
  userId: json['user_id'] as String,
  status: json['status'] as String,
  startedAt: json['started_at'] as String,
  completedAt: json['completed_at'] as String?,
  completedSteps: (json['completed_steps'] as num?)?.toInt() ?? 0,
  totalSteps: (json['total_steps'] as num?)?.toInt() ?? 0,
  errorCount: (json['error_count'] as num?)?.toInt() ?? 0,
  stallCount: (json['stall_count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ExecutionRowToJson(ExecutionRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'routine_id': instance.routineId,
      'user_id': instance.userId,
      'status': instance.status,
      'started_at': instance.startedAt,
      'completed_at': instance.completedAt,
      'completed_steps': instance.completedSteps,
      'total_steps': instance.totalSteps,
      'error_count': instance.errorCount,
      'stall_count': instance.stallCount,
    };

NewStepExecution _$NewStepExecutionFromJson(Map<String, dynamic> json) =>
    NewStepExecution(
      executionId: json['execution_id'] as String,
      stepId: json['step_id'] as String,
      status: json['status'] as String,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      errorCount: (json['error_count'] as num?)?.toInt() ?? 0,
      stallCount: (json['stall_count'] as num?)?.toInt() ?? 0,
      rePromptCount: (json['re_prompt_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NewStepExecutionToJson(NewStepExecution instance) =>
    <String, dynamic>{
      'execution_id': instance.executionId,
      'step_id': instance.stepId,
      'status': instance.status,
      'duration_seconds': instance.durationSeconds,
      'error_count': instance.errorCount,
      'stall_count': instance.stallCount,
      're_prompt_count': instance.rePromptCount,
    };
