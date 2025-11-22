import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gacha_guard/route.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gacha_guard/features/auth/presentation/pages/signup_page.dart';
import 'package:gacha_guard/features/home/home_page.dart';
import 'package:gacha_guard/features/auth/presentation/components/message_helper.dart';
import 'package:gacha_guard/features/auth/presentation/components/custom_button.dart';
import 'package:gacha_guard/features/auth/presentation/components/custom_text_field.dart';
import 'package:gacha_guard/features/auth/presentation/cubits/auth_cubit.dart';
import 'auth_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  final void Function()? togglePages;

  const LoginPage({super.key, required this.togglePages});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _obscurePassword = true;
  //text controller
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //auth cubit
  late final authcubit = context.read<AuthCubit>();

  void login(){
    //prepare email and pw
    final String email = emailController.text;
    final String pw = passwordController.text;

    //ensure that the fields are filled 
    if (email.isNotEmpty && pw.isNotEmpty) {
      authcubit.login(email, pw);
    }

    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email & password"))
      );
    }
  }

// forgot password box
  void openForgotPasswordBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        //forgot password
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFFF5EFFB), 
        title: const Text(
          "Forgot Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        //email
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 130, 
            maxWidth: 350,  
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CustomTextField(
              controller: emailController,
              hintText: "Enter email",
              label: "Email",
              icon: Icons.email,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 10, right: 10),
        actionsAlignment: MainAxisAlignment.end,
        //cancel
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              // empty Email validation
                if (emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your email'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                //length email validation
                if (emailController.text.length > 255) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email is too long'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                //email structure validation
                final emailRegex = RegExp(r'^[^@]+@[^@]+$');
                if (!emailRegex.hasMatch(emailController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
              String message =
                  await authcubit.forgotPassword(emailController.text);

              if (!context.mounted) return;

              if (message == "Password reset email: Check Your Email.") {
                Navigator.pop(context);
                emailController.clear();
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              "Reset",
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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
              Colors.pink.shade200,
              Colors.blue.shade200,
              Colors.cyan.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 2,
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Welcome Back!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7B88FF),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // email
                          CustomTextField(
                            controller: emailController,
                            hintText: 'Enter your Email',
                            label: 'Email',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 20),
                          
                          //password
                          CustomTextField(
                            controller: passwordController,
                            hintText: 'Enter your password',
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword; // toggle visibility
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => openForgotPasswordBox(),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          //Login button
                          CustomButton(
                            text: "LOGIN",
                            onPressed: login,
                          ),

                          //google login
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                authcubit.signInWithGoogle();
                              },
                              icon: Image.asset(
                                'assets/images/google_icon.png',
                                height: 24,
                                width: 24,
                              ),
                              label: const Text(
                                'Login with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.black12,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: const Color.fromARGB(255, 239, 235, 235),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: widget.togglePages,
                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                    color: Colors.orange,
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
            ],
          ),
        ),
      ),
    );
  }
}
