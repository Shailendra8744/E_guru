
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_guru/core/auth_store.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._ref) {
    _init();
  }

  Future<void> _init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings: initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message.notification!);
      }
    });
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _showLocalNotification(RemoteNotification notification) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'eguru_main_channel',
      'e-Guru Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
    );
  }

  Future<void> uploadFcmToken() async {
    try {
      if (kDebugMode) print('Attempting to get FCM token...');
      final token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode) print('FCM Token found: $token');
        final api = _ref.read(apiClientProvider);
        final response = await api.post('/auth/fcm-token', {'token': token});
        if (kDebugMode) {
          print('FCM Token uploaded successfully. Server response: $response');
        }
      } else {
        if (kDebugMode) print('FCM Token is NULL. Check google-services.json and Firebase setup.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading FCM token: $e');
      }
    }
  }
}
