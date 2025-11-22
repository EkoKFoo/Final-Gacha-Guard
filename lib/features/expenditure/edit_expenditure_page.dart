import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gacha_guard/services/spending_analysis_service.dart';

class EditExpenditurePage extends StatefulWidget {
  final String eid;
  final String title;
  final String details;
  final double amount;
  final String category;
  final DateTime dateTime;
  final String merchant;

  const EditExpenditurePage({
    Key? key,
    required this.eid,
    required this.title,
    required this.details,
    required this.amount,
    required this.category,
    required this.dateTime,
    required this.merchant,
  }) : super(key: key);

  @override
  State<EditExpenditurePage> createState() => _EditExpenditurePageState();
}

class _EditExpenditurePageState extends State<EditExpenditurePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _detailsController;
  late TextEditingController _amountController;
  late TextEditingController _merchantController;

  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _selectedCategory;

  final List<String> _categories = [
    'Battle Pass',
    'Monthly Pass',
    'Premium Currency',
    'Gacha Pulls',
    'Cosmetics',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _detailsController = TextEditingController(text: widget.details);
    _amountController =
        TextEditingController(text: widget.amount.toStringAsFixed(2));
    _merchantController = TextEditingController(text: widget.merchant);

    _selectedCategory = widget.category;
    _selectedDate = widget.dateTime;
    _selectedTime =
        TimeOfDay(hour: widget.dateTime.hour, minute: widget.dateTime.minute);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

void _updateTransaction() async {
  if (!_formKey.currentState!.validate()) return;
  //category validation
  if (_selectedCategory == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select a category")),
    );
    return;
  }
  
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User not logged in')),
    );
    return;
  }

  final dateTime = DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  // Parse the amount once
  final amount = double.tryParse(_amountController.text) ?? 0.0;

  final updatedTransaction = {
    'title': _titleController.text.trim(),
    'details': _detailsController.text.trim(),
    'amount': amount,
    'merchant': _merchantController.text.trim(),
    'category': _selectedCategory,
    'dateTime': Timestamp.fromDate(dateTime),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenditures')
        .doc(widget.eid)
        .update(updatedTransaction);

    // Trigger overspending and high-risk checks
    await SpendingAnalysisService().checkBudgetOnTransaction(user.uid);
    await SpendingAnalysisService().updateScheduledNotifications(user.uid);

    if (mounted) Navigator.of(context).pop(true);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to update transaction: $e")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Expenditure',
          style:
              TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('e.g., Battle Pass'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a title';
                  if (value.length > 255) return 'Title cannot exceed 255 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Details'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailsController,
                maxLines: 3,
                decoration: _inputDecoration('e.g., Genshin Impact Battle Pass'),
                validator: (value) {
                   if (value != null && value.length > 255) {
                    return 'Details cannot exceed 255 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Amount (RM)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration('0.00'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount';
                  final parsed = double.tryParse(value);
                  if (parsed == null) return 'Enter a valid number';
                  if (parsed <= 0) return 'Amount must be > 0';
                  if (parsed > 999999) return 'Amount cannot exceed RM999,999';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Merchant'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _merchantController,
                decoration: _inputDecoration('e.g., Google Play Store'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a merchant';
                  if (value.length > 255) return 'Merchant cannot exceed 255 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration('Select a category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Date'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('yyyy-MM-dd').format(_selectedDate),
                                    style: const TextStyle(fontSize: 14)),
                                const Icon(Icons.calendar_today, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Time'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_selectedTime.format(context),
                                    style: const TextStyle(fontSize: 14)),
                                const Icon(Icons.access_time, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7FFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Update Transaction',
                    style: TextStyle(
                        fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF5B7FFF)),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }
}
