import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/appointment.dart';
import '../data/models/caregiver_link.dart';
import '../data/models/emergency_contact.dart';
import '../data/models/execution.dart';
import '../data/models/medication.dart';
import '../data/models/profile_data.dart';
import '../data/models/routine.dart';
import '../data/models/safety_zone.dart';
import 'supabase_service.dart';

/// Data-transfer object used when updating a profile via [ApiClient.updateProfile].
class ProfileUpdate {
  final String? displayName;
  final String? sensoryMode;
  final String? preferredInput;
  final bool? hapticEnabled;
  final bool? audioEnabled;
  final double? fontScale;
  final String? lostModeName;
  final String? lostModeAddress;
  final String? lostModePhone;
  final String? lostModePhotoUrl;
  final bool? simpleMode;
  final int? currentComplexity;

  const ProfileUpdate({
    this.displayName,
    this.sensoryMode,
    this.preferredInput,
    this.hapticEnabled,
    this.audioEnabled,
    this.fontScale,
    this.lostModeName,
    this.lostModeAddress,
    this.lostModePhone,
    this.lostModePhotoUrl,
    this.simpleMode,
    this.currentComplexity,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (displayName != null) map['display_name'] = displayName;
    if (sensoryMode != null) map['sensory_mode'] = sensoryMode;
    if (preferredInput != null) map['preferred_input'] = preferredInput;
    if (hapticEnabled != null) map['haptic_enabled'] = hapticEnabled;
    if (audioEnabled != null) map['audio_enabled'] = audioEnabled;
    if (fontScale != null) map['font_scale'] = fontScale;
    if (lostModeName != null) map['lost_mode_name'] = lostModeName;
    if (lostModeAddress != null) map['lost_mode_address'] = lostModeAddress;
    if (lostModePhone != null) map['lost_mode_phone'] = lostModePhone;
    if (lostModePhotoUrl != null) map['lost_mode_photo_url'] = lostModePhotoUrl;
    if (simpleMode != null) map['simple_mode'] = simpleMode;
    if (currentComplexity != null) map['current_complexity'] = currentComplexity;
    return map;
  }
}

/// Central API client that wraps all Supabase Postgres queries.
///
/// Ported from the Swift `APIClient`.  Every method throws on error so callers
/// can handle failures at the UI level.
class ApiClient {
  ApiClient._();

  static SupabaseClient get _client => SupabaseService.client;

  static String get _uid => _client.auth.currentUser!.id;

  // ===========================================================================
  // ROUTINES
  // ===========================================================================

  /// Fetches all routines with their nested steps, ordered newest-first.
  static Future<List<RoutineRow>> fetchRoutines() async {
    try {
      final data = await _client
          .from('routines')
          .select('*, routine_steps(*)')
          .order('created_at', ascending: false);

      return (data as List).map((e) => RoutineRow.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[ApiClient] fetchRoutines error: $e');
      rethrow;
    }
  }

  /// Fetches a single routine by [id], including its steps.
  static Future<RoutineRow> fetchRoutine(String id) async {
    try {
      final data = await _client
          .from('routines')
          .select('*, routine_steps(*)')
          .eq('id', id)
          .single();

      return RoutineRow.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] fetchRoutine error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // PROFILE
  // ===========================================================================

  /// Fetches the current user's profile.
  static Future<ProfileData> fetchProfile() async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', _uid)
          .single();

      return ProfileData.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] fetchProfile error: $e');
      rethrow;
    }
  }

  /// Partial-updates the current user's profile with the non-null fields in
  /// [update].
  static Future<ProfileData> updateProfile(ProfileUpdate update) async {
    try {
      final data = await _client
          .from('profiles')
          .update(update.toJson())
          .eq('id', _uid)
          .select()
          .single();

      return ProfileData.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] updateProfile error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // EXECUTIONS
  // ===========================================================================

  /// Creates a new execution row for [routineId] and returns it.
  static Future<ExecutionRow> startExecution(String routineId) async {
    try {
      final data = await _client
          .from('executions')
          .insert({
            'routine_id': routineId,
            'user_id': _uid,
            'status': 'in_progress',
            'started_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      return ExecutionRow.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] startExecution error: $e');
      rethrow;
    }
  }

  /// Records a single step completion inside an execution.
  static Future<void> completeStep({
    required String executionId,
    required String stepId,
    required int durationSeconds,
    int errorCount = 0,
    int stallCount = 0,
    int rePromptCount = 0,
  }) async {
    try {
      await _client.from('step_executions').insert({
        'execution_id': executionId,
        'step_id': stepId,
        'status': 'completed',
        'duration_seconds': durationSeconds,
        'error_count': errorCount,
        'stall_count': stallCount,
        're_prompt_count': rePromptCount,
      });
    } catch (e) {
      debugPrint('[ApiClient] completeStep error: $e');
      rethrow;
    }
  }

  /// Marks an execution as completed.
  static Future<ExecutionRow> completeExecution(String id) async {
    try {
      final data = await _client
          .from('executions')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return ExecutionRow.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] completeExecution error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // SAFETY ZONES
  // ===========================================================================

  /// Fetches all safety zones for the current user.
  static Future<List<SafetyZoneRow>> fetchSafetyZones() async {
    try {
      final data = await _client
          .from('safety_zones')
          .select()
          .eq('user_id', _uid)
          .eq('is_active', true)
          .order('name');

      return (data as List).map((e) => SafetyZoneRow.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[ApiClient] fetchSafetyZones error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // ALERTS
  // ===========================================================================

  /// Fetches all alerts for the current user, newest first.
  static Future<List<Map<String, dynamic>>> fetchAlerts() async {
    try {
      final data = await _client
          .from('alerts')
          .select()
          .eq('user_id', _uid)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[ApiClient] fetchAlerts error: $e');
      rethrow;
    }
  }

  /// Creates a new alert for the current user.
  static Future<Map<String, dynamic>> createAlert({
    required String type,
    required String severity,
    required String title,
    required String message,
  }) async {
    try {
      final data = await _client
          .from('alerts')
          .insert({
            'user_id': _uid,
            'type': type,
            'severity': severity,
            'title': title,
            'message': message,
          })
          .select()
          .single();

      return data;
    } catch (e) {
      debugPrint('[ApiClient] createAlert error: $e');
      rethrow;
    }
  }

  /// Sends an alert to all family members linked to the current user.
  static Future<void> notifyFamilyMembers({
    required String alertType,
    required String title,
    required String message,
  }) async {
    try {
      // Fetch all caregiver links where the current user is the patient.
      final links = await _client
          .from('caregiver_links')
          .select('caregiver_id')
          .eq('user_id', _uid)
          .eq('status', 'active');

      final caregiverIds =
          (links as List).map((e) => e['caregiver_id'] as String).toList();

      // Insert an alert row for each linked caregiver / family member.
      for (final cid in caregiverIds) {
        await _client.from('alerts').insert({
          'user_id': cid,
          'type': alertType,
          'severity': 'high',
          'title': title,
          'message': message,
          'related_user_id': _uid,
        });
      }
    } catch (e) {
      debugPrint('[ApiClient] notifyFamilyMembers error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // MEDICATIONS
  // ===========================================================================

  /// Fetches all active medications for the current user.
  static Future<List<MedicationRow>> fetchMedications() async {
    try {
      final data = await _client
          .from('medications')
          .select()
          .eq('user_id', _uid)
          .eq('is_active', true)
          .order('hour')
          .order('minute');

      return (data as List).map((e) => MedicationRow.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[ApiClient] fetchMedications error: $e');
      rethrow;
    }
  }

  /// Adds a new medication for the current user.
  static Future<MedicationRow> addMedication({
    required String name,
    required String dosage,
    required int hour,
    required int minute,
    List<int>? reminderOffsets,
  }) async {
    try {
      final data = await _client
          .from('medications')
          .insert({
            'user_id': _uid,
            'name': name,
            'dosage': dosage,
            'hour': hour,
            'minute': minute,
            'reminder_offsets': reminderOffsets,
          })
          .select()
          .single();

      return MedicationRow.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] addMedication error: $e');
      rethrow;
    }
  }

  /// Marks a medication as taken today.
  static Future<void> markMedicationTaken(String id) async {
    try {
      await _client
          .from('medications')
          .update({'taken_today': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('[ApiClient] markMedicationTaken error: $e');
      rethrow;
    }
  }

  /// Soft-deletes a medication by deactivating it.
  static Future<void> deleteMedication(String id) async {
    try {
      await _client
          .from('medications')
          .update({'is_active': false})
          .eq('id', id);
    } catch (e) {
      debugPrint('[ApiClient] deleteMedication error: $e');
      rethrow;
    }
  }

  /// Fetches medications for a specific patient (caregiver use-case).
  static Future<List<MedicationRow>> fetchPatientMedications(
    String patientId,
  ) async {
    try {
      final data = await _client
          .from('medications')
          .select()
          .eq('user_id', patientId)
          .eq('is_active', true)
          .order('hour')
          .order('minute');

      return (data as List).map((e) => MedicationRow.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[ApiClient] fetchPatientMedications error: $e');
      rethrow;
    }
  }

  /// Adds a medication on behalf of a patient (caregiver use-case).
  static Future<MedicationRow> addPatientMedication({
    required String patientId,
    required String name,
    required String dosage,
    required int hour,
    required int minute,
    List<int>? reminderOffsets,
  }) async {
    try {
      final data = await _client
          .from('medications')
          .insert({
            'user_id': patientId,
            'name': name,
            'dosage': dosage,
            'hour': hour,
            'minute': minute,
            'reminder_offsets': reminderOffsets,
          })
          .select()
          .single();

      return MedicationRow.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] addPatientMedication error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // EMERGENCY CONTACTS
  // ===========================================================================

  /// Fetches all emergency contacts for the current user.
  static Future<List<EmergencyContactRow>> fetchEmergencyContacts() async {
    try {
      final data = await _client
          .from('emergency_contacts')
          .select()
          .eq('user_id', _uid)
          .order('is_primary', ascending: false);

      return (data as List)
          .map((e) => EmergencyContactRow.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('[ApiClient] fetchEmergencyContacts error: $e');
      rethrow;
    }
  }

  /// Adds a new emergency contact for the current user.
  static Future<EmergencyContactRow> addEmergencyContact({
    required String name,
    required String phone,
    required String relationship,
    bool isPrimary = false,
  }) async {
    try {
      final data = await _client
          .from('emergency_contacts')
          .insert({
            'user_id': _uid,
            'name': name,
            'phone': phone,
            'relationship': relationship,
            'is_primary': isPrimary,
          })
          .select()
          .single();

      return EmergencyContactRow.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] addEmergencyContact error: $e');
      rethrow;
    }
  }

  /// Deletes an emergency contact.
  static Future<void> deleteEmergencyContact(String id) async {
    try {
      await _client.from('emergency_contacts').delete().eq('id', id);
    } catch (e) {
      debugPrint('[ApiClient] deleteEmergencyContact error: $e');
      rethrow;
    }
  }

  /// Sets a contact as the primary emergency contact, un-setting all others.
  static Future<void> setEmergencyContactPrimary(String id) async {
    try {
      // Un-set current primaries.
      await _client
          .from('emergency_contacts')
          .update({'is_primary': false})
          .eq('user_id', _uid);

      // Set the new primary.
      await _client
          .from('emergency_contacts')
          .update({'is_primary': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('[ApiClient] setEmergencyContactPrimary error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // APPOINTMENTS
  // ===========================================================================

  /// Fetches all appointments for the current user.
  static Future<List<AppointmentRow>> fetchAppointments() async {
    try {
      final data = await _client
          .from('appointments')
          .select()
          .eq('user_id', _uid)
          .order('appointment_date');

      return (data as List).map((e) => AppointmentRow.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[ApiClient] fetchAppointments error: $e');
      rethrow;
    }
  }

  /// Adds a new appointment.
  static Future<AppointmentRow> addAppointment({
    required String doctorName,
    String? specialty,
    String? location,
    String? notes,
    required DateTime date,
    bool isRecurring = false,
    int? recurringMonths,
  }) async {
    try {
      final data = await _client
          .from('appointments')
          .insert({
            'user_id': _uid,
            'doctor_name': doctorName,
            'specialty': specialty,
            'location': location,
            'notes': notes,
            'appointment_date': date.toUtc().toIso8601String(),
            'is_recurring': isRecurring,
            'recurring_months': recurringMonths,
          })
          .select()
          .single();

      return AppointmentRow.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] addAppointment error: $e');
      rethrow;
    }
  }

  /// Deletes an appointment.
  static Future<void> deleteAppointment(String id) async {
    try {
      await _client.from('appointments').delete().eq('id', id);
    } catch (e) {
      debugPrint('[ApiClient] deleteAppointment error: $e');
      rethrow;
    }
  }

  /// Marks an appointment as completed.
  static Future<AppointmentRow> completeAppointment(String id) async {
    try {
      final data = await _client
          .from('appointments')
          .update({'status': 'completed'})
          .eq('id', id)
          .select()
          .single();

      return AppointmentRow.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] completeAppointment error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // FAMILY / CAREGIVER LINKS
  // ===========================================================================

  /// Fetches all users linked to the current user -- both directions:
  ///   1. Links where the current user is the caregiver (patients I manage).
  ///   2. Links where the current user is the patient (my caregivers).
  ///
  /// Returns a single merged list.
  static Future<List<CaregiverLinkRow>> fetchLinkedUsers() async {
    try {
      // Links where I am the caregiver (my patients).
      final asCaregiver = await _client
          .from('caregiver_links')
          .select('*, profiles!caregiver_links_user_id_fkey(display_name, email, current_complexity, sensory_mode)')
          .eq('caregiver_id', _uid)
          .eq('status', 'active');

      // Links where I am the patient (my caregivers).
      final asPatient = await _client
          .from('caregiver_links')
          .select('*, profiles!caregiver_links_caregiver_id_fkey(display_name, email, current_complexity, sensory_mode)')
          .eq('user_id', _uid)
          .eq('status', 'active');

      final List<CaregiverLinkRow> results = [];
      for (final row in asCaregiver) {
        results.add(CaregiverLinkRow.fromJson(row));
      }
      for (final row in asPatient) {
        results.add(CaregiverLinkRow.fromJson(row));
      }
      return results;
    } catch (e) {
      debugPrint('[ApiClient] fetchLinkedUsers error: $e');
      rethrow;
    }
  }

  /// Generates a new invite code so another user can link to the current user.
  static Future<String> generateInviteCode() async {
    try {
      final data = await _client
          .from('caregiver_links')
          .insert({
            'user_id': _uid,
            'caregiver_id': _uid, // placeholder until accepted
            'status': 'pending',
            'invite_code': _generateCode(),
          })
          .select()
          .single();

      return data['invite_code'] as String;
    } catch (e) {
      debugPrint('[ApiClient] generateInviteCode error: $e');
      rethrow;
    }
  }

  /// Accepts an invite code, linking the current user as caregiver.
  static Future<CaregiverLinkRow> acceptInvite(String code) async {
    try {
      final data = await _client
          .from('caregiver_links')
          .update({
            'caregiver_id': _uid,
            'status': 'active',
          })
          .eq('invite_code', code)
          .eq('status', 'pending')
          .select()
          .single();

      return CaregiverLinkRow.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] acceptInvite error: $e');
      rethrow;
    }
  }

  /// Revokes (deletes) a caregiver link.
  static Future<void> revokeLink(String linkId) async {
    try {
      await _client.from('caregiver_links').delete().eq('id', linkId);
    } catch (e) {
      debugPrint('[ApiClient] revokeLink error: $e');
      rethrow;
    }
  }

  /// Updates the permission flags on a caregiver link.
  ///
  /// [permissions] keys: `perm_view_activity`, `perm_edit_routines`,
  /// `perm_view_location`, `perm_view_medications`, `perm_view_emergency`.
  static Future<CaregiverLinkRow> updateLinkPermissions(
    String linkId,
    Map<String, bool> permissions,
  ) async {
    try {
      final data = await _client
          .from('caregiver_links')
          .update(permissions)
          .eq('id', linkId)
          .select()
          .single();

      return CaregiverLinkRow.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] updateLinkPermissions error: $e');
      rethrow;
    }
  }

  /// Fetches the profile of a linked patient by [userId].
  static Future<ProfileData> fetchPatientProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return ProfileData.fromJson(data);
    } catch (e) {
      debugPrint('[ApiClient] fetchPatientProfile error: $e');
      rethrow;
    }
  }

  /// Fetches recent executions for a linked patient.
  static Future<List<ExecutionRow>> fetchPatientExecutions(
    String userId,
  ) async {
    try {
      final data = await _client
          .from('executions')
          .select()
          .eq('user_id', userId)
          .order('started_at', ascending: false)
          .limit(50);

      return (data as List).map((e) => ExecutionRow.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[ApiClient] fetchPatientExecutions error: $e');
      rethrow;
    }
  }

  /// Fetches alerts for a linked patient.
  static Future<List<Map<String, dynamic>>> fetchPatientAlerts(
    String userId,
  ) async {
    try {
      final data = await _client
          .from('alerts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[ApiClient] fetchPatientAlerts error: $e');
      rethrow;
    }
  }

  /// Fetches safety zones for a linked patient.
  static Future<List<SafetyZoneRow>> fetchPatientSafetyZones(
    String userId,
  ) async {
    try {
      final data = await _client
          .from('safety_zones')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);

      return (data as List).map((e) => SafetyZoneRow.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[ApiClient] fetchPatientSafetyZones error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  /// Generates a random 6-character uppercase alphanumeric invite code.
  static String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = DateTime.now().microsecondsSinceEpoch;
    return List.generate(6, (i) {
      final idx = (rng + i * 7) % chars.length;
      return chars[idx];
    }).join();
  }
}
