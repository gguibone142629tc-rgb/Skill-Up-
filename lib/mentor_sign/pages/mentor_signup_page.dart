import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Required for the fix
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- YOUR PROJECT IMPORTS ---
import 'package:finaproj/common/primary_button.dart';
import 'package:finaproj/login/widgets/login/login_logo.dart';
import 'package:finaproj/mentor_sign/widget/mentor_signup/mentor_basic_info_step.dart';
import 'package:finaproj/mentor_sign/widget/mentor_signup/mentor_experience_step.dart';
import 'package:finaproj/services/auth_service.dart';
import 'package:finaproj/services/database_service.dart';
import 'package:finaproj/login/pages/login_page.dart';

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
  XFile? _profileImage;
  String _gender = ''; // Gender field

  // --- Step 2: Experience Data ---
  int _yearsExp = 0;
  int _monthsExp = 0;
  String _bio = "";
  String _category = ""; // ✅ NEW: Variable to hold category
  List<String> _skills = [];
  List<String> _expertise = [];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- Navigation Logic ---
  void _nextPage() {
    if (_currentPage == 0) {
      if (_firstNameController.text.isEmpty ||
          _lastNameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _jobTitleController.text.isEmpty ||
          _companyController.text.isEmpty ||
          _locationController.text.isEmpty ||
          _gender.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage = 1);
    }
  }

  // --- SUBMIT LOGIC ---
  Future<void> _onCta() async {
    // If on Step 1, go to Step 2
    if (_currentPage == 0) {
      _nextPage();
      return;
    }

    // If on Step 2, Validate
    if (_bio.isEmpty || _category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a category and write a bio')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create User in Firebase Auth
      UserCredential? cred = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (cred.user != null) {
        String uid = cred.user!.uid;

        // 2. Save Basic Profile to Firestore
        await _dbService.saveMentorProfile(
          uid: uid,
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          jobTitle: _jobTitleController.text.trim(),
          company: _companyController.text.trim(),
          location: _locationController.text.trim(),
          gender: _gender,
          yearsExp: _yearsExp,
          monthsExp: _monthsExp,
          bio: _bio,
          skills: _skills,
          expertise: _expertise,
          profileImage: _profileImage,
        );

        // 3. ✅ CRITICAL FIX: Save the Category Field Manually
        // This ensures the filter logic works (mentor.categories.contains(...))
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'categories': [_category], // Save as a List
        });

        // 4. Logout after registration
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
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_currentPage == 1) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() => _currentPage = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const LoginLogo(height: 32),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      color: const Color(0xFF2E6F6A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      color: _currentPage == 1
                          ? const Color(0xFF2E6F6A)
                          : Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),

            // Step Title
            Text(
              _currentPage == 0 ? "Basic Information" : "Experience & Skills",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Form Pages
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
                      onImageSelected: (file) => _profileImage = file,
                      onGenderChanged: (gender) => _gender = gender,
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
                      // ✅ Capture the category
                      onCategoryChanged: (val) {
                        _category = val;
                      },
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
                      label:
                          _currentPage == 0 ? 'Next Step' : 'Become a Mentor',
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
