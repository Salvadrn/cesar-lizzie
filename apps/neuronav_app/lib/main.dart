import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await SupabaseService.initialize();

  // Initialize local notifications (medication reminders, stall alerts, etc.)
  await NotificationService.initialize();
  await NotificationService.requestAuthorization();

  // Initialize push notifications (FCM)
  await PushNotificationService.initialize();
  await PushNotificationService.checkInitialMessage();

  runApp(const ProviderScope(child: NeuroNavApp()));
}
