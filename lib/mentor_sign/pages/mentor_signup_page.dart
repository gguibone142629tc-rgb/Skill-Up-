import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Required for XFile

// Project Imports
import 'package:finaproj/common/primary_button.dart';
import 'package:finaproj/login/widgets/login/login_logo.dart';
import 'package:finaproj/mentor_sign/widget/mentor_signup/mentor_basic_info_step.dart';
import 'package:finaproj/mentor_sign/widget/mentor_signup/mentor_experience_step.dart';
import 'package:finaproj/services/auth_service.dart';
import 'package:finaproj/services/database_service.dart';

class MentorSignUpPage extends StatefulWidget {
  const MentorSignUpPage({super.key});

  @override
  State<MentorSignUpPage> createState() => _MentorSignUpPageState();
}

class _MentorSignUpPageState extends State<MentorSignUpPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  // --- Step 1: Basic Info Controllers ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  
  // 🟢 WEB-SAFE: Use XFile (Works on Web & Mobile)
  XFile? _profileImage; 

  // --- Step 2: Experience Data ---
  int _yearsExp = 0;
  int _monthsExp = 0;
  String _bio = "";
  List<String> _skills = [];
  List<String> _expertise = [];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final next = _pageController.page?.round() ?? 0;
      if (_currentPage != next) setState(() => _currentPage = next);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onCta() async {
    if (_currentPage == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _submitApplication();
    }
  }

  Future<void> _submitApplication() async {
    // Basic Validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create Auth User
      final cred = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (cred.user == null) {
        throw Exception("Failed to create user account.");
      }

      // 2. Save Profile Data to Firestore
      // 🟢 Matches the new Web-Safe DatabaseService signature
      await _dbService.saveMentorProfile(
        uid: cred.user!.uid, 
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        company: _companyController.text.trim(),
        location: _locationController.text.trim(),
        yearsExp: _yearsExp,
        monthsExp: _monthsExp,
        bio: _bio,
        skills: _skills,
        expertise: _expertise,
        profileImage: _profileImage, // Passes XFile directly
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application Submitted Successfully!')),
        );
        // Navigate back to login
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'), 
            backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(child: Center(child: LoginLogo(height: 40))),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 1: Basic Info
                  _buildScrollableStep(
                    child: MentorBasicInfoStep(
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      jobTitleController: _jobTitleController,
                      companyController: _companyController,
                      locationController: _locationController,
                      // 🟢 Callback receives XFile
                      onImageSelected: (XFile? file) {
                        setState(() {
                          _profileImage = file;
                        });
                      },
                    ),
                  ),
                  
                  // Step 2: Experience
                  _buildScrollableStep(
                    child: MentorExperienceStep(
                      onExperienceChanged: (y, m) {
                        _yearsExp = y;
                        _monthsExp = m;
                      },
                      onBioChanged: (val) => _bio = val,
                      onSkillsChanged: (list) => _skills = list,
                      onExpertiseChanged: (list) => _expertise = list,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom CTA Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      label: _currentPage == 0 ? 'Next Step' : 'Become a Mentor',
                      onPressed: _onCta,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableStep({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: child,
        ),
      ),
    );
  }
}