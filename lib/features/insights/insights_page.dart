import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:gacha_guard/util/bottom_nav_helper.dart';
import 'package:gacha_guard/services/notification_service.dart';
import 'package:gacha_guard/services/scheduled_notification_service.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({Key? key}) : super(key: key);

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _budgetLimit = 0.0;
  double _totalSpent = 0.0;
  bool _isLoading = true;

  YoutubePlayerController? _youtubeController;
  bool _youtubeError = false;

  @override
  void initState() {
    super.initState();

    // Initialize YouTube player
    _youtubeController = YoutubePlayerController(
      initialVideoId: '1EE-3lk0_7M',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    )..addListener(() {
        if (_youtubeController!.value.hasError) {
          setState(() {
            _youtubeError = true;
          });
        }
      });
    //load user data
    _loadUserData();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    //get current user
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final budgetDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget')
          .doc('main')
          .get();
      //get if budget exist
      if (budgetDoc.exists) {
        _budgetLimit = budgetDoc['budgetLimit'] ?? 0.0;
      }
      //get user expenditure data
      final expenditureSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenditures')
          .get();

      double total = 0.0;
      for (var doc in expenditureSnapshot.docs) {
        total += (doc['amount'] ?? 0.0);
      }

      setState(() {
        _totalSpent = total;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  //check spending ratio
  double get spendingRatio => _budgetLimit > 0 ? _totalSpent / _budgetLimit : 0;
  //give out recommendations depending on user spending ratio
  List<Map<String, String>> getRecommendations() {
    if (spendingRatio < 0.5) {
      return [
        {
          'title': 'Well Managed Spending',
          'description': 'You’re managing your budget well — keep it up!',
        },
        {
          'title': 'Track Your Expenses',
          'description': 'Continue tracking your expenses regularly.',
        },
        {
          'title': 'Save Remaining Budget',
          'description': 'Consider saving the remaining budget early.',
        },
      ];
    } else if (spendingRatio < 0.8) {
      return [
        {
          'title': 'Half Budget Used',
          'description': 'You’ve used over half your budget — review your remaining expenses.',
        },
        {
          'title': 'Set Alerts',
          'description': 'Set alerts to remind you before reaching your budget limit.',
        },
        {
          'title': 'Plan Purchases',
          'description': 'Plan your next purchases carefully to avoid overspending.',
        },
      ];
    } else {
      return [
        {
          'title': 'Budget Exceeded',
          'description': 'You’ve exceeded your budget limit! Pause non-essential spending.',
        },
        {
          'title': 'Review Transactions',
          'description': 'Check your spending categories to identify overspending.',
        },
        {
          'title': 'Adjust Next Budget',
          'description': 'Consider adjusting next month’s budget based on current patterns.',
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final recommendations = getRecommendations();
    final bool exceededBudget = spendingRatio >= 1.0;

    double screenWidth = MediaQuery.of(context).size.width;
    double videoHeight = screenWidth < 600
        ? 200
        : screenWidth < 1200
            ? 300
            : 400;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(),
        title: const Text(
          'Spending Insights &\nSupport',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.3,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (spendingRatio >= 0.8) _buildAlertCard(exceededBudget),
            const SizedBox(height: 16),

            // YouTube Video Section with error handling
            const Text(
              'Awareness Video',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                height: videoHeight,
                child: _youtubeController == null
                    ? Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _youtubeError
                        ? Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Text(
                                "Video unavailable. Please check your internet connection.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.red),
                              ),
                            ),
                          )
                        : YoutubePlayerBuilder(
                            player: YoutubePlayer(
                              controller: _youtubeController!,
                              showVideoProgressIndicator: true,
                              progressColors: const ProgressBarColors(
                                playedColor: Colors.blue,
                                handleColor: Colors.blueAccent,
                              ),
                            ),
                            builder: (context, player) => player,
                          ),
              ),
            ),
            const SizedBox(height: 24),

            // Recommendations
            const Text(
              'Helpful Tips & Recommendations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...recommendations.map(
              (rec) => _buildTipCard(
                Icons.lightbulb_outline,
                rec['title']!,
                rec['description']!,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavHelper(currentIndex: 0),
    );
  }

  Widget _buildAlertCard(bool exceeded) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: exceeded
              ? [Colors.red.shade700, Colors.red.shade400]
              : [Colors.orange.shade600, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            exceeded ? Icons.error_outline : Icons.warning_amber_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              exceeded
                  ? ' You’ve exceeded your budget! Reduce spending now.'
                  : ' You’ve used over 80% of your budget — monitor your spending.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B88FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF7B88FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style:
                      const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }
}
