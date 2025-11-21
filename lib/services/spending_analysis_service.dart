import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'scheduled_notification_service.dart';

class SpendingAnalysisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notifier = NotificationService();
  final ScheduledNotificationService _scheduledNotifier =
      ScheduledNotificationService();

  // Notification IDs
  static const int overspendingNotificationId = 1;

  /// Triggers IMMEDIATE overspending alerts
  Future<void> checkBudgetOnTransaction(String uid) async {
    try {
      final budgetRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('budget')
          .doc('main');

      final budgetSnapshot = await budgetRef.get();
      if (!budgetSnapshot.exists) return;

      final budgetData = budgetSnapshot.data()!;
      final double budgetLimit = (budgetData['budgetLimit'] ?? 0.0).toDouble();
      if (budgetLimit <= 0) return;

      // Current period spending (month)
      final now = DateTime.now();
      final periodStart = DateTime(now.year, now.month, 1);

      final expendituresSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenditures')
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
          .get();

      double totalSpending = 0.0;
      for (var doc in expendituresSnapshot.docs) {
        totalSpending += ((doc.data()['amount'] ?? 0.0) as num).toDouble();
      }

      final double threshold = budgetLimit * 0.9;

      // Trigger immediate notifications
      if (totalSpending >= budgetLimit) {
        await _notifier.showOverspendingAlert(
          'Budget Exceeded!',
          'You\'ve spent RM${totalSpending.toStringAsFixed(2)} of your RM${budgetLimit.toStringAsFixed(2)} budget!',
        );
        await _storeAlert(uid, 'overspending', 'Budget exceeded',
            'Total spending: RM${totalSpending.toStringAsFixed(2)}');
      } else if (totalSpending >= threshold) {
        final remaining = budgetLimit - totalSpending;
        await _notifier.showOverspendingAlert(
          'Budget Warning',
          'Only RM${remaining.toStringAsFixed(2)} left in your RM${budgetLimit.toStringAsFixed(2)} budget!',
        );
      }
    } catch (e) {
      print('Error in checkBudgetOnTransaction: $e');
    }
  }

  /// Update scheduled notifications based on spending patterns
  Future<void> updateScheduledNotifications(String uid) async {
    try {
      print('Updating scheduled notifications...');
      await _scheduledNotifier.scheduleHighRiskAndTimeDelayNotifications(uid);
      print('Scheduled notifications updated');
    } catch (e) {
      print('Error updating scheduled notifications: $e');
    }
  }

  /// Store alert in Firestore for history tracking
  Future<void> _storeAlert(
      String uid, String type, String title, String message) async {
    try {
      await _firestore.collection('users').doc(uid).collection('alerts').add({
        'type': type,
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error storing alert: $e');
    }
  }

  /// Get spending statistics for current period
  Future<Map<String, dynamic>> getSpendingStats(String uid) async {
    try {
      final budgetSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('budget')
          .doc('main')
          .get();

      if (!budgetSnapshot.exists) return {'error': 'No budget found'};

      final budgetLimit = (budgetSnapshot.data()!['budgetLimit'] ?? 0.0).toDouble();

      final now = DateTime.now();
      final periodStart = DateTime(now.year, now.month, 1);

      final expendituresSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenditures')
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
          .get();

      double totalSpending = 0.0;
      for (var doc in expendituresSnapshot.docs) {
        totalSpending += ((doc.data()['amount'] ?? 0.0) as num).toDouble();
      }

      return {
        'budgetLimit': budgetLimit,
        'totalSpending': totalSpending,
        'remaining': budgetLimit - totalSpending,
        'percentUsed': budgetLimit > 0 ? (totalSpending / budgetLimit * 100) : 0,
        'transactionCount': expendituresSnapshot.docs.length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
