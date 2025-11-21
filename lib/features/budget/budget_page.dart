import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gacha_guard/features/expenditure/manage_expenditure_page.dart';
import 'package:gacha_guard/features/profile/profile_page.dart';
import 'package:gacha_guard/util/bottom_nav_helper.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({Key? key}) : super(key: key);

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  double _budgetAmount = 2500.0;
  String _selectedPeriod = 'Monthly';
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = true;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadUserBudget();
  }

  Future<void> _loadUserBudget() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _uid = user.uid;

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('budget')
            .doc('main') // access the single budget document
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _budgetAmount = (data['budgetLimit'] ?? 2500.0).toDouble();
            _selectedPeriod = data['budgetType'] ?? 'Monthly';
            _amountController.text = _budgetAmount.toStringAsFixed(0);
          });
        } else {
          // default if user has no budget document yet
          setState(() {
            _amountController.text = _budgetAmount.toStringAsFixed(0);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading budget: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateBudgetFromSlider(double value) {
    setState(() {
      _budgetAmount = value;
      _amountController.text = value.toStringAsFixed(0);
    });
  }

  void _updateBudgetFromTextField(String value) {
    final parsedValue = double.tryParse(value);
    if (parsedValue != null && parsedValue >= 0 && parsedValue <= 100000) {
      setState(() {
        _budgetAmount = parsedValue;
      });
    }
  }

  DateTime _calculateStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Daily':
        return DateTime(now.year, now.month, now.day);
      case 'Weekly':
        // Start of current week (Monday)
        final weekday = now.weekday;
        return now.subtract(Duration(days: weekday - 1));
      case 'Monthly':
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime _calculateLastDate() {
    final startDate = _calculateStartDate();
    switch (_selectedPeriod) {
      case 'Daily':
        return DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
      case 'Weekly':
        return startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      case 'Monthly':
      default:
        // Last day of the month
        final nextMonth = DateTime(startDate.year, startDate.month + 1, 1);
        return nextMonth.subtract(const Duration(seconds: 1));
    }
  }

  DateTime _calculateResetDate() {
    final lastDate = _calculateLastDate();
    switch (_selectedPeriod) {
      case 'Daily':
        return lastDate.add(const Duration(seconds: 1));
      case 'Weekly':
        return lastDate.add(const Duration(seconds: 1));
      case 'Monthly':
      default:
        return lastDate.add(const Duration(seconds: 1));
    }
  }

  Future<void> _saveChanges() async {
    if (_uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final startDate = _calculateStartDate();
      final lastDate = _calculateLastDate();
      final resetDate = _calculateResetDate();

      final budgetRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('budget')
          .doc('main'); // only one budget per user

      final budgetDoc = await budgetRef.get();

      if (budgetDoc.exists) {
        // Update existing budget
        await budgetRef.update({
          'budgetType': _selectedPeriod,
          'budgetLimit': _budgetAmount,
          'budgetStartDate': Timestamp.fromDate(startDate),
          'budgetLastDate': Timestamp.fromDate(lastDate),
          'budgetResetDate': Timestamp.fromDate(resetDate),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new budget (first time)
        await budgetRef.set({
          'budgetType': _selectedPeriod,
          'budgetLimit': _budgetAmount,
          'budgetStartDate': Timestamp.fromDate(startDate),
          'budgetLastDate': Timestamp.fromDate(lastDate),
          'budgetResetDate': Timestamp.fromDate(resetDate),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget limit saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving budget: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const SizedBox(),
          title: const Text(
            'Budget Settings',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(),
        title: const Text(
          'Set Budget Limit',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 16,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Monthly Budget Limit Card
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly Budget Limit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Budget Amount Display
                        Center(
                          child: Text(
                            'RM${_budgetAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.blue,
                            inactiveTrackColor: Colors.grey[300],
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 14,
                              elevation: 2,
                            ),
                            overlayColor: Colors.blue.withOpacity(0.2),
                            trackHeight: 6,
                          ),
                          child: Slider(
                            value: _budgetAmount,
                            min: 0,
                            max: 100000,
                            onChanged: _updateBudgetFromSlider,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Editable Amount Field
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'RM',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: _updateBudgetFromTextField,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Budget Period Card
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Budget Period',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPeriodButton('Daily'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildPeriodButton('Weekly'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildPeriodButton('Monthly'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Save Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavHelper(currentIndex: 3),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            period,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}