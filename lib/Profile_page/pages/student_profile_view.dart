import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:finaproj/common/mentor_avatar.dart';

class StudentProfileView extends StatefulWidget {
  final String studentId;

  const StudentProfileView({super.key, required this.studentId});

  @override
  State<StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends State<StudentProfileView> {
  Map<String, dynamic>? _studentData;
  bool _isLoading = true;

  String _bio = '';
  List<String> _interests = [];
  List<String> _goals = [];
  List<String> _learningStyles = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _studentData = data;
          _bio = data['bio'] ?? '';
          _interests = List<String>.from(data['interests'] ?? []);
          _goals = List<String>.from(data['goals'] ?? []);
          _learningStyles = List<String>.from(data['learningStyles'] ?? []);
        });
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final fullName = _studentData?['fullName'] ?? 'Student';
    final location = _studentData?['location'] ?? 'Remote';
    final profileImage = (_studentData?['profileImageUrl'] ??
        _studentData?['photoUrl'] ??
        _studentData?['photoURL'] ??
        '')
      .toString();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = currentUserId == widget.studentId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
              decoration: const BoxDecoration(
                color: Color(0xFF6B9A91),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      const Text(
                        'Student Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Logo/Icon placeholder
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '📚',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Profile Content
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar and Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MentorAvatar(
                            name: fullName,
                            image: profileImage,
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Student',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Edit Profile button (only for own profile)
                          if (isOwnProfile)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  // Navigate to edit profile
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF2D6A65),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    color: Color(0xFF2D6A65),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // About Section
                    _buildSection(
                      title: 'About',
                      child: Text(
                        _bio.isEmpty ? 'No bio provided yet.' : _bio,
                        style: TextStyle(
                          color: _bio.isEmpty
                              ? Colors.grey[500]
                              : Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ),

                    // Interests Section
                    _buildSection(
                      title: 'Interests',
                      child: _interests.isEmpty
                          ? Text(
                              'No interests listed',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _interests.map((interest) {
                                return Chip(
                                  label: Text(interest),
                                  backgroundColor: const Color(0xFFE8F5F3),
                                  side: BorderSide.none,
                                );
                              }).toList(),
                            ),
                    ),

                    // Learning Goals Section
                    _buildSection(
                      title: 'Learning Goals',
                      child: _goals.isEmpty
                          ? Text(
                              'No goals listed',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _goals.map((goal) {
                                return Chip(
                                  label: Text(goal),
                                  backgroundColor: const Color(0xFFE8F5F3),
                                  side: BorderSide.none,
                                );
                              }).toList(),
                            ),
                    ),

                    // Learning Preferences Section
                    _buildSection(
                      title: 'Learning Preferences',
                      child: _learningStyles.isEmpty
                          ? Text(
                              'No preferences listed',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _learningStyles.map((style) {
                                return Chip(
                                  label: Text(style),
                                  backgroundColor: const Color(0xFFE8F5F3),
                                  side: BorderSide.none,
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSectionIcon(title),
                size: 18,
                color: const Color(0xFF2D6A65),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D6A65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'About':
        return Icons.info_outline;
      case 'Interests':
        return Icons.favorite_outline;
      case 'Learning Goals':
        return Icons.flag_outlined;
      case 'Learning Preferences':
        return Icons.tune_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
