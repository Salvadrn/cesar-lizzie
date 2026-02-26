import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/medication.dart';

/// Manages all local notifications: medication reminders, doctor appointments,
/// stall alerts, emergency alerts, and fall-detection alerts.
///
/// Ported from the Swift `NotificationService`.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Notification channel / category IDs
  // ---------------------------------------------------------------------------

  static const String _medicationChannelId = 'medication_reminder';
  static const String _medicationChannelName = 'Recordatorio de Medicamentos';
  static const String _appointmentChannelId = 'appointment_reminder';
  static const String _appointmentChannelName = 'Recordatorio de Citas';
  static const String _emergencyChannelId = 'emergency';
  static const String _emergencyChannelName = 'Emergencias';

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the local notification plugin with platform-specific settings.
  /// Safe to call multiple times; subsequent calls are no-ops.
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          _medicationChannelId,
          actions: [
            DarwinNotificationAction.plain(
              'taken',
              'Tomada',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              'snooze',
              'Recordar en 10 min',
            ),
          ],
        ),
        DarwinNotificationCategory(
          _appointmentChannelId,
          actions: [
            DarwinNotificationAction.plain(
              'view',
              'Ver detalles',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
        DarwinNotificationCategory(
          _emergencyChannelId,
          actions: [
            DarwinNotificationAction.plain(
              'cancel_emergency',
              'Estoy bien',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create Android notification channels.
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _medicationChannelId,
          _medicationChannelName,
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _appointmentChannelId,
          _appointmentChannelName,
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _emergencyChannelId,
          _emergencyChannelName,
          importance: Importance.max,
        ),
      );
    }

    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Authorization
  // ---------------------------------------------------------------------------

  /// Requests notification permissions from the OS.
  static Future<bool> requestAuthorization() async {
    if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );
      return granted ?? false;
    }

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // Medication Reminders
  // ---------------------------------------------------------------------------

  /// Schedules the full set of medication reminders for [id]:
  ///   1. Offset reminders (e.g. 15 min before).
  ///   2. The main reminder at [hour]:[minute].
  ///   3. A 10-minute follow-up in case the user did not act.
  static Future<void> scheduleMedicationReminder({
    required String id,
    required String name,
    required String dosage,
    required int hour,
    required int minute,
    List<int> offsets = const [],
  }) async {
    await initialize();

    final baseId = id.hashCode.abs();

    // -- Offset reminders (before the main time) --
    for (var i = 0; i < offsets.length; i++) {
      final offsetMinutes = offsets[i];
      final offsetTime = _adjustTime(hour, minute, -offsetMinutes);

      await _scheduleDailyNotification(
        id: baseId + 100 + i,
        channelId: _medicationChannelId,
        channelName: _medicationChannelName,
        categoryId: _medicationChannelId,
        title: 'Medicamento en $offsetMinutes min',
        body: '$name - $dosage',
        hour: offsetTime.hour,
        minute: offsetTime.minute,
        critical: false,
      );
    }

    // -- Main reminder --
    await _scheduleDailyNotification(
      id: baseId,
      channelId: _medicationChannelId,
      channelName: _medicationChannelName,
      categoryId: _medicationChannelId,
      title: 'Hora de tu medicamento',
      body: '$name - $dosage',
      hour: hour,
      minute: minute,
      critical: Platform.isIOS,
    );

    // -- 10-minute follow-up --
    final followUp = _adjustTime(hour, minute, 10);
    await _scheduleDailyNotification(
      id: baseId + 999,
      channelId: _medicationChannelId,
      channelName: _medicationChannelName,
      categoryId: _medicationChannelId,
      title: 'No olvides tu medicamento',
      body: '$name - $dosage. Han pasado 10 minutos.',
      hour: followUp.hour,
      minute: followUp.minute,
      critical: false,
    );
  }

  /// Cancels the 10-minute follow-up for a medication that was just taken.
  static Future<void> medicationWasTaken(String id) async {
    final baseId = id.hashCode.abs();
    await _plugin.cancel(baseId + 999);
  }

  /// Reschedules all medication reminders (e.g. after app restart).
  static Future<void> rescheduleAllMedications(
    List<MedicationRow> meds,
  ) async {
    // Cancel only medication-related notifications (not appointments/emergency)
    for (final med in meds) {
      final baseId = med.id.hashCode.abs();
      await _plugin.cancel(baseId); // main reminder
      await _plugin.cancel(baseId + 999); // follow-up
      for (var i = 0; i < 5; i++) {
        await _plugin.cancel(baseId + 100 + i); // offset reminders
      }
    }

    for (final med in meds) {
      await scheduleMedicationReminder(
        id: med.id,
        name: med.name,
        dosage: med.dosage,
        hour: med.hour,
        minute: med.minute,
        offsets: med.reminderOffsets ?? [],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Doctor Appointment Reminders
  // ---------------------------------------------------------------------------

  /// Schedules two reminders for a doctor appointment:
  ///   1. One day before.
  ///   2. One hour before.
  static Future<void> scheduleDoctorAppointment({
    required String id,
    required String doctorName,
    required DateTime date,
  }) async {
    await initialize();

    final baseId = id.hashCode.abs() + 50000;
    final tzDate = tz.TZDateTime.from(date, tz.local);

    // -- 1 day before --
    final dayBefore = tzDate.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(tz.TZDateTime.now(tz.local))) {
      await _plugin.zonedSchedule(
        baseId,
        'Cita manana',
        'Recuerda tu cita con $doctorName manana.',
        dayBefore,
        _notificationDetails(
          channelId: _appointmentChannelId,
          channelName: _appointmentChannelName,
          categoryId: _appointmentChannelId,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
    }

    // -- 1 hour before --
    final hourBefore = tzDate.subtract(const Duration(hours: 1));
    if (hourBefore.isAfter(tz.TZDateTime.now(tz.local))) {
      await _plugin.zonedSchedule(
        baseId + 1,
        'Cita en 1 hora',
        'Tu cita con $doctorName es en 1 hora.',
        hourBefore,
        _notificationDetails(
          channelId: _appointmentChannelId,
          channelName: _appointmentChannelName,
          categoryId: _appointmentChannelId,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
    }
  }

  /// Cancels both appointment reminders.
  static Future<void> cancelDoctorAppointment(String id) async {
    final baseId = id.hashCode.abs() + 50000;
    await _plugin.cancel(baseId);
    await _plugin.cancel(baseId + 1);
  }

  // ---------------------------------------------------------------------------
  // Immediate Alerts
  // ---------------------------------------------------------------------------

  /// Fires an immediate high-priority alert when a stall is detected.
  static Future<void> sendStallAlert() async {
    await initialize();
    await _plugin.show(
      90001,
      'Necesitas ayuda?',
      'Parece que llevas un rato sin avanzar. Toca para volver a la rutina.',
      _notificationDetails(
        channelId: _emergencyChannelId,
        channelName: _emergencyChannelName,
        categoryId: _emergencyChannelId,
        critical: true,
      ),
    );
  }

  /// Fires an immediate critical alert for a generic emergency.
  static Future<void> sendEmergencyAlert() async {
    await initialize();
    await _plugin.show(
      90002,
      'Alerta de Emergencia',
      'Se ha activado una alerta de emergencia. Verificando estado del usuario.',
      _notificationDetails(
        channelId: _emergencyChannelId,
        channelName: _emergencyChannelName,
        categoryId: _emergencyChannelId,
        critical: true,
      ),
    );
  }

  /// Fires an immediate critical alert when a fall / crash is detected.
  static Future<void> sendFallDetectionAlert() async {
    await initialize();
    await _plugin.show(
      90003,
      'Caida Detectada',
      'Se detecto un posible impacto. Si estas bien, cancela la cuenta regresiva.',
      _notificationDetails(
        channelId: _emergencyChannelId,
        channelName: _emergencyChannelName,
        categoryId: _emergencyChannelId,
        critical: true,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Routine Reminders
  // ---------------------------------------------------------------------------

  /// Schedules a daily routine reminder at a specific time.
  static Future<void> scheduleRoutineReminder({
    required String id,
    required String routineName,
    required int hour,
    required int minute,
  }) async {
    await initialize();

    final baseId = id.hashCode.abs() + 70000;

    await _scheduleDailyNotification(
      id: baseId,
      channelId: _medicationChannelId,
      channelName: 'Recordatorio de Rutinas',
      title: 'Hora de tu rutina',
      body: '$routineName - Es momento de completar tu rutina.',
      hour: hour,
      minute: minute,
      critical: false,
    );
  }

  /// Cancels a routine reminder.
  static Future<void> cancelRoutineReminder(String id) async {
    final baseId = id.hashCode.abs() + 70000;
    await _plugin.cancel(baseId);
  }

  // ---------------------------------------------------------------------------
  // Missed Medication Alert
  // ---------------------------------------------------------------------------

  /// Sends an immediate alert when a medication was not taken after the follow-up.
  static Future<void> sendMedicationMissedAlert({
    required String name,
    required String dosage,
  }) async {
    await initialize();
    await _plugin.show(
      90004,
      'Medicamento no tomado',
      'No has tomado $name ($dosage). Por favor tomalo lo antes posible.',
      _notificationDetails(
        channelId: _medicationChannelId,
        channelName: _medicationChannelName,
        categoryId: _medicationChannelId,
        critical: true,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Notification response handler
  // ---------------------------------------------------------------------------

  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
      '[NotificationService] action=${response.actionId} '
      'payload=${response.payload}',
    );
    // Action routing is handled at the app level via a stream / callback
    // injected at init.  This stub logs for debugging.
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static NotificationDetails _notificationDetails({
    required String channelId,
    required String channelName,
    String? categoryId,
    bool critical = false,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: critical ? Importance.max : Importance.high,
        priority: critical ? Priority.max : Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: categoryId,
        interruptionLevel: critical
            ? InterruptionLevel.critical
            : InterruptionLevel.timeSensitive,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Schedules a daily repeating notification at the given [hour]:[minute].
  static Future<void> _scheduleDailyNotification({
    required int id,
    required String channelId,
    required String channelName,
    String? categoryId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    bool critical = false,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // If the time already passed today, schedule for tomorrow.
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(
        channelId: channelId,
        channelName: channelName,
        categoryId: categoryId,
        critical: critical,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Returns a new ({hour, minute}) offset by [deltaMinutes] from the given
  /// [hour]:[minute].  Handles day wraparound.
  static ({int hour, int minute}) _adjustTime(
    int hour,
    int minute,
    int deltaMinutes,
  ) {
    var totalMinutes = hour * 60 + minute + deltaMinutes;
    // Wrap around midnight.
    totalMinutes = totalMinutes % (24 * 60);
    if (totalMinutes < 0) totalMinutes += 24 * 60;
    return (hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }
}
