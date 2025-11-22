import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gacha_guard/util/bottom_nav_helper.dart';
import 'add_expenditure_page.dart';
import 'edit_expenditure_page.dart';

class Transaction {
  final String eid;
  final DateTime dateTime;
  final String title;
  final String details;
  final double amount;
  final String category;
  final String merchant;

  Transaction({
    required this.eid,
    required this.dateTime,
    required this.title,
    required this.details,
    required this.amount,
    required this.category,
    required this.merchant,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Transaction(
      eid: doc.id, // Use document ID as eid (primary key)
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      title: data['title'] ?? '',
      details: data['details'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      merchant: data['merchant'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dateTime': Timestamp.fromDate(dateTime),
      'title': title,
      'details': details,
      'amount': amount,
      'category': category,
      'merchant': merchant,
    };
  }

  String getFormattedDate() {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  String getFormattedTime() {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay getTimeOfDay() {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }
}

class ManageExpenditurePage extends StatefulWidget {
  const ManageExpenditurePage({Key? key}) : super(key: key);

  @override
  State<ManageExpenditurePage> createState() => _ManageExpenditurePageState();
}

class _ManageExpenditurePageState extends State<ManageExpenditurePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  String _sortBy = 'date_desc';
  String? _filterCategory;
  bool _isLoading = true;

  final List<String> _categories = [
    'All',
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
    _loadExpenditures();
  }

Future<void> _loadExpenditures() async {
  try {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Load expenditures from nested user collection
    final QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('expenditures')
        .get();

    setState(() {
      _transactions = snapshot.docs
          .map((doc) => Transaction.fromFirestore(doc))
          .toList();
      _applyFiltersAndSort();
      _isLoading = false;
    });
  } catch (e) {
    print('Error loading expenditures: $e');
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load expenditures: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

void _navigateToAddPage() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const AddExpenditurePage(),
    ),
  );

  if (result == true) {
    // Reload expenditures from Firestore
    await _loadExpenditures();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expenditure added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

  void _navigateToEditPage(Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenditurePage(
          eid: transaction.eid,
          title: transaction.title,
          details: transaction.details,
          amount: transaction.amount,
          category: transaction.category,
          dateTime: transaction.dateTime,
          merchant: transaction.merchant,
        ),
      ),
    );

    if (result == true) {
      // Reload expenditures from Firestore
      await _loadExpenditures();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expenditure updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }


void _showDeleteDialog(Transaction transaction) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Delete Expenditure'),
        content: Text(
          'Are you sure you want to delete "${transaction.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final User? currentUser = _auth.currentUser;
                if (currentUser == null) return;

                await _firestore
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('expenditures')
                    .doc(transaction.eid)
                    .delete();

                await _loadExpenditures();

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Expenditure deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete expenditure.'),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

  void _showFilterDialog() {
    String tempSortBy = _sortBy;
    String? tempFilterCategory = _filterCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter & Sort',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Category',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _categories.map((category) {
                                  final isSelected = tempFilterCategory == category || 
                                                    (category == 'All' && tempFilterCategory == null);
                                  return FilterChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setModalState(() {
                                        tempFilterCategory = category == 'All' ? null : category;
                                      });
                                    },
                                    selectedColor: const Color(0xFF5B7FFF).withOpacity(0.2),
                                    checkmarkColor: const Color(0xFF5B7FFF),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              
                              const Text(
                                'Sort By',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              
                              _buildSortOption(
                                'Date (Newest First)',
                                'date_desc',
                                tempSortBy,
                                (value) {
                                  setModalState(() {
                                    tempSortBy = value;
                                  });
                                },
                              ),
                              _buildSortOption(
                                'Date (Oldest First)',
                                'date_asc',
                                tempSortBy,
                                (value) {
                                  setModalState(() {
                                    tempSortBy = value;
                                  });
                                },
                              ),
                              _buildSortOption(
                                'Amount (High to Low)',
                                'amount_desc',
                                tempSortBy,
                                (value) {
                                  setModalState(() {
                                    tempSortBy = value;
                                  });
                                },
                              ),
                              _buildSortOption(
                                'Amount (Low to High)',
                                'amount_asc',
                                tempSortBy,
                                (value) {
                                  setModalState(() {
                                    tempSortBy = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _sortBy = tempSortBy;
                              _filterCategory = tempFilterCategory;
                              _applyFiltersAndSort();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B7FFF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption(String title, String value, String groupValue, Function(String) onChanged) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
              activeColor: const Color(0xFF5B7FFF),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFiltersAndSort() {
    List<Transaction> filtered = _transactions;

    // Apply category filter
    if (_filterCategory != null) {
      filtered = filtered.where((t) => t.category == _filterCategory).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'date_desc':
        filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        break;
      case 'date_asc':
        filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    _filteredTransactions = filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Manage Expenditures',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
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
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _showFilterDialog,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No transactions yet',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Click the + button to add an expenditure',
                                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _filteredTransactions[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    spreadRadius: 0,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '${transaction.getFormattedDate()} ${transaction.getFormattedTime()}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                transaction.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                transaction.details,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.store, size: 12, color: Colors.grey[400]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    transaction.merchant,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF5B7FFF).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      transaction.category,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF5B7FFF),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'RM${transaction.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF5B7FFF),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _navigateToEditPage(transaction),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('Edit'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.grey[700],
                                            side: BorderSide(color: Colors.grey[300]!),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _showDeleteDialog(transaction),
                                          icon: const Icon(Icons.delete, size: 16),
                                          label: const Text('Delete'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPage,
        backgroundColor: const Color(0xFF5B7FFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const BottomNavHelper(currentIndex: 1),
    );
  }
}