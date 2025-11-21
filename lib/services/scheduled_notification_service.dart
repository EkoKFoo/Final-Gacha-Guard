import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class ScheduledNotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final ScheduledNotificationService _instance =
      ScheduledNotificationService._internal();
  factory ScheduledNotificationService() => _instance;

  ScheduledNotificationService._internal() {
    _initializeTimezone();
  }

  // Notification IDs
  static const int highRiskNotificationId = 2;
  static const int timeDelayNotificationId = 3;

  Future<void> initialize() async {
    if (kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    //shared notification tap handler from NotificationService
    await _notifications.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: NotificationService.onNotificationTapped,
    );
  }

  Future<void> _initializeTimezone() async {
    if (!kIsWeb) {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    }
  }

  /// Schedules both High-Risk and Time-Delay notifications
  Future<void> scheduleHighRiskAndTimeDelayNotifications(String uid) async {
    if (kIsWeb) return;

    try {
      await _notifications.cancel(highRiskNotificationId);
      await _notifications.cancel(timeDelayNotificationId);

      final expenditures = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenditures')
          .get();

      if (expenditures.docs.length < 5) {
        print('ℹ️ Not enough transactions (need 5+) for notifications');
        return;
      }

      // Calculate total spent and frequency per hour
      final totalSpentPerHour = <int, double>{};
      final frequencyPerHour = <int, int>{};
      final transactionsByHour = <int, List<int>>{};

      for (var doc in expenditures.docs) {
        final data = doc.data();
        final ts = data['dateTime'] as Timestamp?;
        final amount = (data['amount'] ?? 0.0) as num;
        if (ts != null) {
          final dt = ts.toDate();
          final hour = dt.hour;
          final minute = dt.minute;

          totalSpentPerHour[hour] =
              (totalSpentPerHour[hour] ?? 0) + amount.toDouble();
          frequencyPerHour[hour] = (frequencyPerHour[hour] ?? 0) + 1;

          transactionsByHour[hour] = (transactionsByHour[hour] ?? [])..add(minute);
        }
      }

      // Compute normalized risk score
      final maxAmount = totalSpentPerHour.values.reduce((a, b) => a > b ? a : b);
      final maxFrequency =
          frequencyPerHour.values.reduce((a, b) => a > b ? a : b);

      final riskScore = <int, double>{};
      for (var hour in totalSpentPerHour.keys) {
        final normAmount = maxAmount > 0 ? totalSpentPerHour[hour]! / maxAmount : 0;
        final normFreq = maxFrequency > 0 ? (frequencyPerHour[hour]! / maxFrequency) : 0;
        riskScore[hour] = normAmount * 0.7 + normFreq * 0.3;
      }

      // High-risk hour
      final highRiskHour = riskScore.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      // Compute average minute for that hour
      final minutesInHour = transactionsByHour[highRiskHour] ?? [];
      final highRiskMinute = minutesInHour.isNotEmpty
          ? (minutesInHour.reduce((a, b) => a + b) ~/ minutesInHour.length)
          : 0;

      // Schedule high-risk notification 15 minutes before
      final now = tz.TZDateTime.now(tz.local);
      var highRiskTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        highRiskHour,
        highRiskMinute,
      ).subtract(const Duration(minutes: 15));

      // If the time has passed today, schedule for tomorrow
      if (highRiskTime.isBefore(now)) {
        highRiskTime = highRiskTime.add(const Duration(days: 1));
      }

      // Schedule High-Risk notification with insights_page payload
      await scheduleNotification(
        id: highRiskNotificationId,
        scheduledDate: highRiskTime,
        title: '⚠️ High-Risk Spending Period Approaching',
        body:
            'You usually spend more around ${_formatHour(highRiskHour, highRiskMinute)}. Stay mindful!',
        channelId: 'high_risk_channel',
        channelName: 'Spending Pattern Alerts',
        payload: 'insights_page',
      );

      // ✅ Schedule Time-Delay notification 5 seconds after high-risk
      final timeDelayTime = highRiskTime.add(const Duration(seconds: 5));
      await scheduleNotification(
        id: timeDelayNotificationId,
        scheduledDate: timeDelayTime,
        title: '💡 Mindful Spending Reminder',
        body:
            'Before buying something, consider taking a short pause. Tap to learn strategies.',
        channelId: 'time_delay_channel',
        channelName: 'Mindful Spending Tips',
        payload: 'insights_page',
      );

      print('✅ High-risk scheduled at $highRiskTime');
      print('✅ Time-delay scheduled at $timeDelayTime');
    } catch (e) {
      print(' Error scheduling notifications: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required tz.TZDateTime scheduledDate,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    String? channelDescription,
    String? payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload, 
    );
  }

  String _formatHour(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute $period';
  }
}