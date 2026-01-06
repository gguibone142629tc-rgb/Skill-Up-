import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- YOUR PROJECT IMPORTS ---
import 'package:finaproj/common/auth_text_field.dart';
import 'package:finaproj/common/primary_button.dart';
import 'package:finaproj/mentor_sign/pages/mentor_signup_page.dart';
import 'package:finaproj/student_sign/pages/signup_page.dart';
import 'package:finaproj/services/auth_service.dart';
import 'package:finaproj/home_page/pages/home_page.dart';

import '../widgets/login_logo/login_logo.dart';
import '../widgets/role_switcher/role_switcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  int _selectedRole = 0;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper to show the popup
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Login Failed"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Try Again",
                style: TextStyle(color: Color(0xFF2D6A65))),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showErrorDialog("Please enter both email and password.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Authenticate
      UserCredential? userCredential = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        // 2. Fetch the user's document with timeout
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw 'Connection timeout. Please check your internet and try again.';
              },
            );

        if (!userDoc.exists) {
          throw "User profile not found.";
        }

        String actualRole = userDoc.data()?['role'] ?? "";
        // Mapping UI selection: 0 is student (mentee), 1 is mentor
        String selectedRoleString = _selectedRole == 0 ? "student" : "mentor";

        // 3. Compare Roles (using lowercase to avoid mismatch)
        if (actualRole.toLowerCase() == selectedRoleString.toLowerCase()) {
          // Small delay to let widgets settle before navigation
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          }
        } else {
          // Wrong Role: Must sign out immediately
          await _authService.signOut();
          _showErrorDialog(
              "Access Denied: You are registered as a $actualRole. Please select the correct role above.");
        }
      }
    } catch (e) {
      // Catching Firebase Auth errors (wrong password, etc.)
      _showErrorDialog(
          e.toString().contains('timeout') 
            ? e.toString() 
            : "Incorrect credentials. Please check your email and password.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF2D6A65);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LoginLogo(height: 60),
                  const SizedBox(height: 24),
                  RoleSwitcher(
                    selectedIndex: _selectedRole,
                    onChanged: (i) => setState(() => _selectedRole = i),
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    label: 'Email',
                    controller: _emailController,
                    hintText: 'user@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Password',
                    controller: _passwordController,
                    hintText: '●●●●●●●●',
                    obscure: true,
                    showObscureToggle: true,
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: accent))
                      : PrimaryButton(
                          label: 'Login',
                          onPressed: _handleLogin,
                        ),
                  const SizedBox(height: 24),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.black87),
                        children: [
                          const TextSpan(text: "Don't have an account?\n"),
                          TextSpan(
                            text: 'Sign up as mentee',
                            style: const TextStyle(
                                color: accent, fontWeight: FontWeight.w600),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const SignUpPage()));
                              },
                          ),
                          const TextSpan(text: '  or  '),
                          TextSpan(
                            text: 'Apply to be a mentor',
                            style: const TextStyle(
                                color: accent, fontWeight: FontWeight.w600),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const MentorSignUpPage()));
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
