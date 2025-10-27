import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _amountController.text = _budgetAmount.toStringAsFixed(0);
  }

  void _updateBudgetFromSlider(double value) {
    setState(() {
      _budgetAmount = value;
      _amountController.text = value.toStringAsFixed(0);
    });
  }

  void _updateBudgetFromTextField(String value) {
    final parsedValue = double.tryParse(value);
    if (parsedValue != null && parsedValue >= 0 && parsedValue <= 10000) {
      setState(() {
        _budgetAmount = parsedValue;
      });
    }
  }

  void _saveChanges() {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Budget settings saved successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                            max: 10000,
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
                                '\$',
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
      // BottomNavigationBar(
      //   type: BottomNavigationBarType.fixed,
      //   currentIndex: 3, // Change this per page: 0=Insight, 1=Expenditures, 2=Home, 3=Budget, 4=Profile
      //   selectedItemColor: Colors.blue,
      //   unselectedItemColor: Colors.grey,
      //   selectedFontSize: 12,
      //   unselectedFontSize: 12,
      //   onTap: (index) {
      //     // Navigate based on the tapped index
      //     switch (index) {
      //       case 0:
      //         // Navigate to Insight page
      //         // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => InsightPage()));
      //         break;
      //       case 1:
      //         // Navigate to Expenditures page
      //         Navigator.pushReplacement(
      //           context,
      //           MaterialPageRoute(builder: (context) => const ManageExpenditurePage()),
      //         );
      //         break;
      //       case 2:
      //         // Navigate to Home page
      //         // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
      //         break;
      //       case 3:
      //         // Navigate to Budget page
      //         Navigator.pushReplacement(
      //           context,
      //           MaterialPageRoute(builder: (context) => const BudgetPage()),
      //         );
      //         break;
      //       case 4:
      //         // Navigate to Profile page
      //         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfilePage()));
      //         break;
      //     }
      //   },
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.trending_up),
      //       label: 'Insight',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.receipt_long),
      //       label: 'Expenditures',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home),
      //       label: 'Home',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.account_balance_wallet),
      //       label: 'Budget',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.person),
      //       label: 'Profile',
      //     ),
      //   ],
      // ),
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