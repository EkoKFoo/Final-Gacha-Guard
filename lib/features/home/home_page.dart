import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gacha_guard/util/bottom_nav_helper.dart';

class TransactionModel {
  final String title;
  final DateTime dateTime;
  final double amount;
  final String category;

  TransactionModel({
    required this.title,
    required this.dateTime,
    required this.amount,
    required this.category,
  });

  factory TransactionModel.fromFirestore(Map<String, dynamic> data) {
    return TransactionModel(
      title: data['title'] ?? 'Unknown',
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? 'Others',
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 2;
  
  //color for category
  final Map<String, Color> categoryColors = {
    'Battle Pass': Colors.purple,
    'Monthly Pass': Colors.blue,
    'Premium Currency': Colors.orange,
    'Gacha Pulls': Colors.red,
    'Cosmetics': Colors.green,
    'Other': Colors.brown,
  };

  // Color mapping for categories
  Color _getCategoryColor(String category) {
    return categoryColors[category] ?? Colors.brown;
  }

  // Build bar chart group
  BarChartGroupData _buildBarGroup(String category, double value, int x) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: _getCategoryColor(category),
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(2),
          ),
          backDrawRodData: BackgroundBarChartRodData(show: false),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getCategoryColor(tx.category),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.category, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${tx.dateTime.day}/${tx.dateTime.month}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Text('-RM${tx.amount.toStringAsFixed(2)}',
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<Map<String, double>> fetchSpendingByCategory() async {
    if (user == null) return {};
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('expenditures')
        .get();

    Map<String, double> categoryMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] ?? 'Others';
      final amount = (data['amount'] ?? 0).toDouble();
      categoryMap[category] = (categoryMap[category] ?? 0) + amount;
    }
    return categoryMap;
  }

  Stream<List<TransactionModel>> fetchTransactions() {
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('expenditures')
        .orderBy('dateTime', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc.data()))
            .toList());
  }

  Color _getProgressColor(double ratio) {
    if (ratio < 0.5) return Colors.green;
    if (ratio < 0.8) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("User not logged in"));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(),
        title: const Text('Dashboard',
            style: TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.black),
              onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
                backgroundColor: Colors.grey[300],
                radius: 16,
                child: const Icon(Icons.person, size: 18, color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Card
            _buildBudgetCard(),

            // Budget Summary
            _buildBudgetSummary(),

            // Spending by Category
            _buildSpendingByCategory(),

            // Recent Transactions
            const Text('Recent Transactions',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            StreamBuilder<List<TransactionModel>>(
              stream: fetchTransactions(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final transactions = snapshot.data!;
                if (transactions.isEmpty) return const Text('No transactions yet.');
                return Column(
                  children: transactions.map(_buildTransactionItem).toList(),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavHelper(currentIndex: 2),
    );
  }

  Widget _buildBudgetCard() {
    final now = DateTime.now();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('budget')
          .doc('main')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final data = snapshot.data!.data();
        if (data == null) return const Center(child: Text("Set your budget"));

        final budgetLimit = (data['budgetLimit'] ?? 3000.0).toDouble();
        final budgetType = (data['budgetType'] ?? 'monthly').toString().toLowerCase();
        DateTime start;
        switch (budgetType) {
          case 'daily':
            start = DateTime(now.year, now.month, now.day);
            break;
          case 'weekly':
            start = now.subtract(Duration(days: now.weekday - 1));
            break;
          default:
            start = DateTime(now.year, now.month, 1);
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('expenditures')
              .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
              .get(),
          builder: (context, spendSnapshot) {
            double spending = 0.0;
            if (spendSnapshot.hasData) {
              for (var doc in spendSnapshot.data!.docs) {
                spending += (doc['amount'] ?? 0).toDouble();
              }
            }

            final progress = (spending / budgetLimit).clamp(0.0, 1.0);
            final remaining = (budgetLimit - spending).clamp(0.0, double.infinity);
            final cardColor = progress < 0.8
                ? Colors.blue.shade50
                : progress < 1.0
                    ? Colors.orange.shade100
                    : Colors.red.shade200;
            final textColor = progress < 0.8 ? Colors.black : Colors.black87;

            return Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${budgetType[0].toUpperCase()}${budgetType.substring(1)} Spending',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 12),
                  Text('RM${spending.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(_getProgressColor(progress)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).toStringAsFixed(0)}% of RM${budgetLimit.toStringAsFixed(2)} used    RM${remaining.toStringAsFixed(2)} left',
                      style: TextStyle(fontSize: 12, color: textColor)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBudgetSummary() {
    final now = DateTime.now();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('budget')
          .doc('main')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final budgetData = snapshot.data!.data();
        if (budgetData == null) return const Text("No budget data");

        final budgetLimit = (budgetData['budgetLimit'] ?? 3000.0).toDouble();
        final budgetType = (budgetData['budgetType'] ?? 'monthly').toString().toLowerCase();
        DateTime start;
        switch (budgetType) {
          case 'daily':
            start = DateTime(now.year, now.month, now.day);
            break;
          case 'weekly':
            start = now.subtract(Duration(days: now.weekday - 1));
            break;
          default:
            start = DateTime(now.year, now.month, 1);
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('expenditures')
              .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
              .get(),
          builder: (context, spendSnapshot) {
            double spending = 0.0;
            if (spendSnapshot.hasData) {
              for (var doc in spendSnapshot.data!.docs) {
                spending += (doc['amount'] ?? 0).toDouble();
              }
            }

            final budgetLeft = (budgetLimit - spending).clamp(0.0, double.infinity);
            final overspent = spending > budgetLimit ? (spending - budgetLimit) : 0.0;
            final dailyAvg = (spending / (now.difference(start).inDays + 1)).clamp(0.0, double.infinity);
            final expectedSpending = budgetLimit;

            return Container(
              padding: const EdgeInsets.all(20.0),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Budget Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildSummaryItem(Icons.add_circle_outline, 'Budget Left', 'RM${budgetLeft.toStringAsFixed(2)}')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSummaryItem(Icons.trending_up, 'Overspent', 'RM${overspent.toStringAsFixed(2)}')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildSummaryItem(Icons.calendar_today_outlined, 'Daily Avg', 'RM${dailyAvg.toStringAsFixed(2)}')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSummaryItem(Icons.description_outlined, 'Expected Spending', 'RM${expectedSpending.toStringAsFixed(2)}')),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpendingByCategory() {
    return FutureBuilder<Map<String, double>>(
      future: fetchSpendingByCategory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        final categories = data.keys.toList();
        final values = data.values.toList();

        return Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Spending by Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final category = categories[group.x.toInt()];
                          return BarTooltipItem(
                            '$category\nRM${rod.toY.toStringAsFixed(2)}',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    barGroups: List.generate(
                      categories.length,
                      (index) => _buildBarGroup(categories[index], values[index], index),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
