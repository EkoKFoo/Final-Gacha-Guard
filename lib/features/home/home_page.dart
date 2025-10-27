import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gacha_guard/route.dart';
import 'package:gacha_guard/features/budget/budget_page.dart';
import 'package:gacha_guard/features/expenditure/manage_expenditure_page.dart';
import 'package:gacha_guard/features/insights/insights_page.dart';
import 'package:gacha_guard/features/profile/profile_page.dart';
import 'package:gacha_guard/util/bottom_nav_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    setState(() {
      _selectedIndex = index;
    });
    
    // Add navigation logic here
    // switch (index) { ... }
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
          'Dashboard',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Spending Card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monthly Spending',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'October 2023',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'RM2345.50',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.78,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7B88FF)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '78% of RM3000.00 budget used    RM654.50 left',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Spending by Game Chart
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Spending by Game',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Last 30 Days',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Chart with Y-axis labels
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Y-axis labels
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildYAxisLabel('RM1000'),
                          const SizedBox(height: 32),
                          _buildYAxisLabel('RM750'),
                          const SizedBox(height: 32),
                          _buildYAxisLabel('RM500'),
                          const SizedBox(height: 32),
                          _buildYAxisLabel('RM250'),
                          const SizedBox(height: 32),
                          _buildYAxisLabel('RM0'),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Chart
                      Expanded(
                        child: SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 1000,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const titles = ['Genshin', 'Arknights', 'Others'];
                                      if (value.toInt() >= 0 && value.toInt() < titles.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            titles[value.toInt()],
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 250,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey[200],
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                _buildBarGroup(0, [850, 800, 750, 650, 600]),
                                _buildBarGroup(1, [700, 650, 550, 450]),
                                _buildBarGroup(2, [400, 350, 300]),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(const Color(0xFF7B88FF), ''),
                      const SizedBox(width: 8),
                      _buildLegend(Colors.red, ''),
                      const SizedBox(width: 8),
                      _buildLegend(Colors.orange, ''),
                      const SizedBox(width: 8),
                      _buildLegend(Colors.green, ''),
                      const SizedBox(width: 8),
                      _buildLegend(Colors.amber, ''),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Budget Summary
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Budget Summary',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          Icons.add_circle_outline,
                          'Budget Left',
                          'RM654.50',
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          Icons.trending_up,
                          'Overspent',
                          'RM0.00',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          Icons.calendar_today_outlined,
                          'Daily Avg',
                          'RM75.00',
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          Icons.description_outlined,
                          'Projected',
                          'RM200.00',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Recent Transactions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7B88FF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Transaction Items
            _buildTransactionItem(
              'Genshin Impact',
              'Oct 28',
              '-RM99.99',
              const Color(0xFFFFE0E7),
            ),
            _buildTransactionItem(
              'Honkai Star Rail',
              'Oct 25',
              '-RM49.99',
              const Color(0xFFD4E4FF),
            ),
            _buildTransactionItem(
              'Arknights',
              'Oct 24',
              '-RM19.99',
              const Color(0xFFE8F5E9),
            ),
            _buildTransactionItem(
              'Punishing: Gray Raven',
              'Oct 23',
              '-RM5.99',
              const Color(0xFFE0E0E0),
            ),
            _buildTransactionItem(
              'Honkai Star Rail',
              'Oct 22',
              '-RM10.00',
              const Color(0xFFD4E4FF),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: Container(
      //   decoration: BoxDecoration(
      //     boxShadow: [
      //       BoxShadow(
      //         color: Colors.grey.withOpacity(0.1),
      //         spreadRadius: 1,
      //         blurRadius: 10,
      //       ),
      //     ],
      //   ),
      //   child: BottomNavigationBar(
      //     currentIndex: _selectedIndex,
      //     onTap: _onItemTapped,
      //     type: BottomNavigationBarType.fixed,
      //     backgroundColor: Colors.white,
      //     selectedItemColor: const Color(0xFF7B88FF),
      //     unselectedItemColor: Colors.grey,
      //     selectedFontSize: 11,
      //     unselectedFontSize: 11,
      //     elevation: 0,
      //     items: const [
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.show_chart),
      //         label: 'Insight',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.receipt_long),
      //         label: 'Expenditures',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.home),
      //         label: 'Home',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.account_balance_wallet),
      //         label: 'Budget',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.person),
      //         label: 'Profile',
      //       ),
      //     ],
      //   ),
      // ),
      //navigation
      bottomNavigationBar: const BottomNavHelper(currentIndex: 2),
      // BottomNavigationBar(
      //   currentIndex: _selectedIndex,
      //   onTap: (index) {
      //     if (index == _selectedIndex) return; // prevent reloading same page

      //     setState(() {
      //       _selectedIndex = index;
      //     });

      //     switch (index) {
      //       case 0:
      //         NavigationHelper.pushReplacement(context, const InsightsPage());
      //         break;
      //       case 1:
      //         NavigationHelper.pushReplacement(context, const ManageExpenditurePage());
      //         break;
      //       case 2:
      //         // already on HomePage
      //         break;
      //       case 3:
      //         NavigationHelper.pushReplacement(context, const BudgetPage());
      //         break;
      //       case 4:
      //         NavigationHelper.pushReplacement(context, const ProfilePage());
      //         break;
      //     }
      //   },
      //   type: BottomNavigationBarType.fixed,
      //   backgroundColor: Colors.white,
      //   selectedItemColor: const Color(0xFF7B88FF),
      //   unselectedItemColor: Colors.grey,
      //   selectedFontSize: 11,
      //   unselectedFontSize: 11,
      //   elevation: 0,
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.show_chart),
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

  Widget _buildYAxisLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 9,
        color: Colors.grey[600],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, List<double> values) {
    final colors = [
      const Color(0xFF7B88FF),
      Colors.red,
      Colors.orange,
      Colors.green,
      Colors.amber,
    ];
    
    return BarChartGroupData(
      x: x,
      barRods: List.generate(
        values.length,
        (index) => BarChartRodData(
          toY: values[index],
          color: colors[index % colors.length],
          width: 6,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(2),
          ),
        ),
      ),
      barsSpace: 2,
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String amount) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[700], size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(String title, String date, String amount, Color bgColor) {
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
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                Icons.games,
                size: 24,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}