import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './auth_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'bluetalk_general',
    'BlueTalk Notifications',
    description: 'General notifications for BlueTalk',
    importance: Importance.max,
    sound: null,
    showBadge: true,
  );

  Future<void> initialize() async {
    if (!kIsWeb) {
      // Create the notification channel on Android
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Init local notifications
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotif.initialize(initSettings);
    }

    // Handle FCM messages while app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Token management
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    // Extract sender name and body from the message payload
    final senderName = data['sender_name'] as String? ??
        notification?.title ??
        'BlueTalk';
    final body = data['body'] as String? ??
        notification?.body ??
        'New message';

    if (kIsWeb) {
      debugPrint('Foreground notification: $senderName - $body');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body,
          contentTitle: senderName,
          summaryText: 'BlueTalk'),
      icon: '@mipmap/ic_launcher',
    );

    final notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      senderName,
      body,
      notifDetails,
    );
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({'fcm_token': token});
      debugPrint('FCM token saved.');
    } catch (_) {}
  }
}
