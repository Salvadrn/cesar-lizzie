// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StepRow _$StepRowFromJson(Map<String, dynamic> json) => StepRow(
  id: json['id'] as String,
  stepOrder: (json['step_order'] as num).toInt(),
  title: json['title'] as String,
  instruction: json['instruction'] as String,
  instructionSimple: json['instruction_simple'] as String?,
  instructionDetailed: json['instruction_detailed'] as String?,
  imageUrl: json['image_url'] as String?,
  audioUrl: json['audio_url'] as String?,
  videoUrl: json['video_url'] as String?,
  durationHint: (json['duration_hint'] as num?)?.toInt() ?? 60,
  checkpoint: json['checkpoint'] as bool? ?? false,
);

Map<String, dynamic> _$StepRowToJson(StepRow instance) => <String, dynamic>{
  'id': instance.id,
  'step_order': instance.stepOrder,
  'title': instance.title,
  'instruction': instance.instruction,
  'instruction_simple': instance.instructionSimple,
  'instruction_detailed': instance.instructionDetailed,
  'image_url': instance.imageUrl,
  'audio_url': instance.audioUrl,
  'video_url': instance.videoUrl,
  'duration_hint': instance.durationHint,
  'checkpoint': instance.checkpoint,
};

RoutineRow _$RoutineRowFromJson(Map<String, dynamic> json) => RoutineRow(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  category: json['category'] as String,
  isActive: json['is_active'] as bool? ?? true,
  assignedTo: json['assigned_to'] as String?,
  complexityLevel: (json['complexity_level'] as num?)?.toInt(),
  routineSteps: (json['routine_steps'] as List<dynamic>?)
      ?.map((e) => StepRow.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$RoutineRowToJson(RoutineRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'is_active': instance.isActive,
      'assigned_to': instance.assignedTo,
      'complexity_level': instance.complexityLevel,
      'routine_steps': instance.routineSteps,
      'created_at': instance.createdAt,
    };
