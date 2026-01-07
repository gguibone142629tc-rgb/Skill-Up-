import 'package:finaproj/login/widgets/login/login_logo.dart';
import 'package:finaproj/mentor_sign/pages/mentor_signup_page.dart';
import 'package:finaproj/student_sign/widget/signup/sign_up_form.dart';
import 'package:finaproj/student_sign/widget/signup/sign_up_links.dart';
import 'package:flutter/material.dart';

// Import your services
import 'package:finaproj/services/auth_service.dart';
import 'package:finaproj/services/database_service.dart';
import 'package:finaproj/login/pages/login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Service Instances
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _gender = '';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- THE REAL SIGNUP LOGIC ---
  Future<void> _handleSignUp() async {
    // 1. Validation
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _firstNameController.text.trim().isEmpty ||
        _gender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Create Auth User
      final userCredential = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 3. Save Mentee Profile to Firestore
      await _dbService.saveStudentProfile(
        uid: userCredential.user!.uid,
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _gender,
      );

      // Logout after registration
      await _authService.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      padding: EdgeInsets.zero,
                    ),
                    const Expanded(child: Center(child: LoginLogo(height: 40))),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  'Sign up as mentee',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                // Updated to use the real function and loading state
                SignUpForm(
                  firstNameController: _firstNameController,
                  lastNameController: _lastNameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isLoading: _isLoading, // New parameter
                  onGenderChanged: (gender) => _gender = gender,
                  onSubmit: _handleSignUp, // Swapped _noop for _handleSignUp
                ),

                Center(
                  child: SignUpLinks(
                    onLoginTap: () => Navigator.pop(context),
                    onApplyTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MentorSignUpPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
