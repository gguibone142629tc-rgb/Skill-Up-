import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// --- IMPORTS ---
import 'package:finaproj/common/auth_text_field.dart';
import 'package:finaproj/common/primary_button.dart';
import 'package:finaproj/mentor_sign/pages/mentor_signup_page.dart';
import 'package:finaproj/student_sign/pages/signup_page.dart';
import 'package:finaproj/services/auth_service.dart';

// ⚠️ IMPORTANT: Import your Home Page here so we can navigate to it directly
import 'package:finaproj/home_page/pages/home_page.dart';

import '../widgets/login/login_logo.dart';
import '../widgets/login/role_switcher.dart';
import '../widgets/login/remember_forgot_row.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  int _selectedRole = 0; 
  bool _rememberMe = false;
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

  Future<void> _handleLogin() async {
    // 1. Validate Input
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Perform Login
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        // 3. SUCCESS! Navigate to Home Page Directly
        // We use MaterialPageRoute instead of '/home' to avoid "Route Not Found" errors.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()), 
          (route) => false,
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                    hintText: 'emanmartos@gmail.com',
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

                  const SizedBox(height: 8),
                  RememberForgotRow(
                    rememberMe: _rememberMe,
                    onRememberChanged: (v) => setState(() => _rememberMe = v),
                    onForgot: () {},
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                        ),
                        children: [
                          const TextSpan(text: "Don't have an account?\n"),
                          TextSpan(
                            text: 'Sign up as mentee',
                            style: const TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpPage(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: '  or  '),
                          TextSpan(
                            text: 'Apply to be a mentor',
                            style: const TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MentorSignUpPage(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),
                  _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        label: 'Login', 
                        onPressed: _handleLogin,
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