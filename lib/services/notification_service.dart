import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gacha_guard/main.dart' show navigatorKey;

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const int overspendingNotificationId = 1;
  static const int highRiskNotificationId = 2;
  static const int timeDelayNotificationId = 3;

  //INIT

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onNotificationTapped,
    );

    _initialized = true;
    print(" NotificationService initialized");
  }

  // Get launch details
  Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    return await _notifications.getNotificationAppLaunchDetails();
  }

  // NOTIFICATION TAP

  static void onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    handlePayload(response.payload!);
  }

  static void handlePayload(String payload) {
    print("Handling payload: $payload");

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 250));

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/insights',
        (route) => false,
      );

      print("Navigated to Insights");
    });
  }

  //PERMISSIONS

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    //notifications permission
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final granted = await androidPlugin?.requestNotificationsPermission();

    if (granted == false) {
      print("Notification permission denied");
    } else {
      print("Notification permission granted");
    }

    // exact alarm permission
    final alarm = await Permission.scheduleExactAlarm.request();
    if (!alarm.isGranted) print("Exact alarm not granted");
  }

  //SHOW NOTIFICATIONS

  Future<void> showOverspendingAlert(String title, String body) async {
    await init();

    final androidDetails = AndroidNotificationDetails(
      'overspending_channel',
      'Budget Alerts',
      channelDescription: 'Alerts when you exceed spending',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    await _notifications.show(
      overspendingNotificationId,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: 'overspending',
    );
  }

  Future<void> showNotificationWithId(int id, String title, String body) async {
    await init();

    String channelId;
    String channelName;
    String? payload;

    if (id == overspendingNotificationId) {
      channelId = 'overspending_channel';
      channelName = 'Budget Alerts';
      payload = 'overspending';
    } else if (id == highRiskNotificationId) {
      channelId = 'high_risk_channel';
      channelName = 'Risk Alerts';
      payload = 'high_risk';
    } else if (id == timeDelayNotificationId) {
      channelId = 'time_delay_channel';
      channelName = 'Mindful Spending Tips';
      payload = 'insights_page'; 
    } else {
      channelId = 'general_channel';
      channelName = 'General Notifications';
      payload = null;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  //CANCEL

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
