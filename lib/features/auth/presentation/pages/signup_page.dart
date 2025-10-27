import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gacha_guard/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:gacha_guard/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_page.dart';
import 'package:gacha_guard/features/auth/presentation/components/custom_text_field.dart';
import 'package:gacha_guard/features/auth/presentation/components/custom_button.dart';

class SignUpPage extends StatefulWidget {
  final void Function()? togglePages;

  const SignUpPage({super.key, required this.togglePages});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  //text controller
  final  nameController = TextEditingController();
  final  emailController = TextEditingController();
  final  pwController = TextEditingController();
  final  confirmPwController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String errorMessage = '';

  //Signup button pressed
  void signUp() async{
    //user credential
    final String name = nameController.text;
    final String email = emailController.text;
    final String pw = pwController.text;
    final String confirmPw = confirmPwController.text;

    //auth cubit
    final authCubit = context.read<AuthCubit>();

    //ensure credential is not empty
    if (name.isNotEmpty && email.isNotEmpty && pw.isNotEmpty && confirmPw.isNotEmpty){
      //ensure pw match
      if (pw == confirmPw){
        authCubit.register(name, email, pw);
      }
      
      //pw do not match
      else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password do not match")));
      }
    }

    // credentials are empty -> display error
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter all fields")));
    }    
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    pwController.dispose();
    confirmPwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade200,
              Colors.blue.shade200,
              Colors.cyan.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.purple.shade200,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create Your Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            errorMessage,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      //username
                      CustomTextField(
                        controller: nameController,
                        label: 'Username',
                        hintText: 'Choose a username',
                        icon: Icons.person,
                      ),
                      //email
                      CustomTextField(
                        controller: emailController,
                        label: 'Email',
                        hintText: 'name@example.com',
                        icon: Icons.email,
                      ),
                      //password
                      CustomTextField(
                        controller: pwController,
                        label: 'Password',
                        hintText: 'Enter your password',
                        icon: Icons.lock,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                          setState(() {
                          _obscurePassword = !_obscurePassword; // toggle visibility
                              }
                            );
                          },
                        ),
                      ),
                      //comfirm password
                      CustomTextField(
                        controller: confirmPwController,
                        label: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        icon: Icons.lock,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                          setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword; // toggle visibility
                              }
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sign up button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: CustomButton(
                          text: 'SignUp',
                          onPressed: signUp,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.togglePages,
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}