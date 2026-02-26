import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase Cloud Messaging (FCM) for push notifications.
///
/// Works alongside [NotificationService] which handles local notifications.
/// This service handles remote push notifications from the server.
class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;
  static String? _fcmToken;

  /// The current FCM token, or null if not yet obtained.
  static String? get fcmToken => _fcmToken;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes FCM. Requests permissions and obtains the device token.
  /// Safe to call multiple times.
  static Future<void> initialize() async {
    if (_initialized) return;

    // Request permission (iOS requires explicit permission)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
      provisional: false,
    );

    debugPrint(
      '[PushNotificationService] Permission status: ${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _setupToken();
      _setupForegroundHandler();
      _setupBackgroundHandler();
    }

    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Token Management
  // ---------------------------------------------------------------------------

  /// Gets the FCM token and listens for refreshes.
  static Future<void> _setupToken() async {
    try {
      // For iOS, get APNS token first
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        debugPrint('[PushNotificationService] APNS token: ${apnsToken != null ? "obtained" : "null"}');
      }

      _fcmToken = await _messaging.getToken();
      debugPrint('[PushNotificationService] FCM token: ${_fcmToken?.substring(0, 20)}...');

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('[PushNotificationService] Token refreshed');
        // TODO: Send new token to your backend (Supabase)
        _sendTokenToServer(newToken);
      });
    } catch (e) {
      debugPrint('[PushNotificationService] Error getting token: $e');
    }
  }

  /// Sends the FCM token to the backend for targeting this device.
  static Future<void> _sendTokenToServer(String token) async {
    // TODO: Implement when backend endpoint is ready
    // await ApiClient.updateFcmToken(token);
    debugPrint('[PushNotificationService] Token ready to send to server: ${token.substring(0, 20)}...');
  }

  // ---------------------------------------------------------------------------
  // Message Handlers
  // ---------------------------------------------------------------------------

  /// Handles messages received while the app is in the foreground.
  static void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '[PushNotificationService] Foreground message: ${message.notification?.title}',
      );

      // Show a local notification for foreground messages
      // since FCM doesn't show them automatically when app is open
      _showLocalNotification(message);
    });
  }

  /// Sets up the handler for when user taps a notification (app was in background).
  static void _setupBackgroundHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '[PushNotificationService] Opened from background: ${message.notification?.title}',
      );
      _handleNotificationTap(message);
    });
  }

  /// Checks if the app was opened from a terminated state via notification.
  static Future<void> checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '[PushNotificationService] Opened from terminated: ${initialMessage.notification?.title}',
      );
      _handleNotificationTap(initialMessage);
    }
  }

  // ---------------------------------------------------------------------------
  // Topic Subscriptions
  // ---------------------------------------------------------------------------

  /// Subscribe to a topic for targeted push notifications.
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[PushNotificationService] Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic.
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[PushNotificationService] Unsubscribed from topic: $topic');
  }

  /// Subscribe to user-specific topics after login.
  static Future<void> subscribeUserTopics(String userId, String role) async {
    await subscribeToTopic('user_$userId');
    await subscribeToTopic('role_$role');
    await subscribeToTopic('all_users');
  }

  /// Unsubscribe from all user topics on logout.
  static Future<void> unsubscribeUserTopics(String userId, String role) async {
    await unsubscribeFromTopic('user_$userId');
    await unsubscribeFromTopic('role_$role');
    await unsubscribeFromTopic('all_users');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Shows a local notification for a foreground FCM message.
  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Import and use NotificationService to show local notification
    // This bridges FCM with the existing local notification system
    debugPrint(
      '[PushNotificationService] Would show local: ${notification.title} - ${notification.body}',
    );
    // NotificationService can be called here to display the notification
    // using flutter_local_notifications
  }

  /// Handles navigation when user taps a notification.
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    debugPrint('[PushNotificationService] Notification data: $data');

    // Route based on notification type
    final type = data['type'];
    switch (type) {
      case 'medication_reminder':
        // Navigate to medications screen
        break;
      case 'appointment_reminder':
        // Navigate to appointments screen
        break;
      case 'emergency_alert':
        // Navigate to emergency screen
        break;
      case 'family_alert':
        // Navigate to family screen
        break;
      default:
        // Navigate to home
        break;
    }
  }
}

/// Top-level function for handling background messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[PushNotificationService] Background message: ${message.notification?.title}',
  );
  // Handle background message (e.g., update badge count, store data)
}
