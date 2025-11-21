import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gacha_guard/util/bottom_nav_helper.dart';
import 'package:gacha_guard/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:gacha_guard/features/auth/presentation/pages/auth_page.dart';
import 'package:gacha_guard/features/profile/profile_information_page.dart';
import 'package:gacha_guard/features/profile/change_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 4;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Account Settings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: const NetworkImage(
                'https://via.placeholder.com/150',
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildProfileCard(
                icon: Icons.person_outline,
                title: 'Profile Information',
                subtitle: 'Manage your name, email, and personal details.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileInformationPage(),
                    ),
                  );
                },
                hasArrow: true,
              ),
              const SizedBox(height: 32),
              const Text(
                'Security',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildProfileCard(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: "Update your account's security password.",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordPage(),
                    ),
                  );
                },
                hasArrow: true,
              ),
              const SizedBox(height: 32),
              const Text(
                'Account Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danger Zone',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Deleting your account is a permanent action and cannot be undone. All spending data will be lost.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showDeleteDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: const Text(
                          'Delete Account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showLogoutDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE57373),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavHelper(currentIndex: 4),
    );
  }

  Widget _buildProfileCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool hasArrow = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (hasArrow)
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final authCubit = context.read<AuthCubit>();
              authCubit.logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    final passwordController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Account',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFFD32F2F),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent and cannot be undone. All your data will be lost.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 20),
              const Text(
                'Please enter your password to confirm:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () {
                passwordController.dispose();
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isDeleting ? null : () async {
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() => isDeleting = true);

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null || user.email == null) {
                    throw Exception('No user logged in');
                  }

                  // Re-authenticate user
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: passwordController.text,
                  );
                  await user.reauthenticateWithCredential(credential);

                  final firestore = FirebaseFirestore.instance;

                  // Delete expenditures subcollection
                  final expenditures = await firestore
                      .collection('users')
                      .doc(user.uid)
                      .collection('expenditures')
                      .get();
                  for (var doc in expenditures.docs) {
                    await doc.reference.delete();
                  }

                  // Delete budget subcollection
                  final budgets = await firestore
                      .collection('users')
                      .doc(user.uid)
                      .collection('budget')
                      .get();
                  for (var doc in budgets.docs) {
                    await doc.reference.delete();
                  }

                  // Delete alerts subcollection if exists
                  final alerts = await firestore
                      .collection('users')
                      .doc(user.uid)
                      .collection('alerts')
                      .get();
                  for (var doc in alerts.docs) {
                    await doc.reference.delete();
                  }

                  // Delete main user document
                  await firestore.collection('users').doc(user.uid).delete();

                  // Delete Firebase Auth user
                  await user.delete();

                  // Close dialog
                  passwordController.dispose();
                  Navigator.pop(dialogContext);

                  // Logout and navigate to auth page
                  final authCubit = context.read<AuthCubit>();
                  authCubit.logout();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                    (route) => false,
                  );

                  // Show success message on new page
                  Future.delayed(const Duration(milliseconds: 500), () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  });

                } on FirebaseAuthException catch (e) {
                  setState(() => isDeleting = false);
                  String message;
                  switch (e.code) {
                    case 'wrong-password':
                      message = 'Incorrect password';
                      break;
                    case 'requires-recent-login':
                      message = 'Please logout and login again before deleting account';
                      break;
                    default:
                      message = 'Error: ${e.message}';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  setState(() => isDeleting = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting account: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isDeleting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Delete',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}