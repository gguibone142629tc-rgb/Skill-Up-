import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finaproj/services/database_service.dart';
import 'package:finaproj/Profile_page/pages/my_profile_page.dart';

class MenteeProfilePage extends StatefulWidget {
  final bool startEditing;
  const MenteeProfilePage({super.key, this.startEditing = false});

  @override
  State<MenteeProfilePage> createState() => _MenteeProfilePageState();
}

class _MenteeProfilePageState extends State<MenteeProfilePage> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  late bool _isEditing;

  // Controllers for editing
  late TextEditingController _bioController;
  late TextEditingController _interestsController;
  late TextEditingController _goalsController;
  late TextEditingController _learningStyleController;

  List<String> _interests = [];
  List<String> _goals = [];
  List<String> _learningStyles = [];

  // Image state
  Uint8List? _newImageBytes;
  XFile? _newImageFile;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startEditing;
    _checkRoleAndNavigate();
    _loadProfile();
    _initializeControllers();
  }

  Future<void> _checkRoleAndNavigate() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        final userData = await _dbService.getUserData(userId);
        final role = userData?['role'] ?? 'student';

        if (role.toLowerCase() == 'mentor' && mounted) {
          // Mentor shouldn't be on student profile page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MyProfilePage(startEditing: false)),
          );
        }
      } catch (e) {
        debugPrint('Error checking role: $e');
      }
    }
  }

  void _initializeControllers() {
    _bioController = TextEditingController();
    _interestsController = TextEditingController();
    _goalsController = TextEditingController();
    _learningStyleController = TextEditingController();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userData = await _dbService.getUserData(userId);
        if (mounted) {
          setState(() {
            _profileData = userData;
            _bioController.text = userData?['bio'] ?? '';
            _interests = List<String>.from(userData?['interests'] ?? []);
            _goals = List<String>.from(userData?['goals'] ?? []);
            _learningStyles =
                List<String>.from(userData?['learningStyles'] ?? []);
          });
        }
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newImageFile = picked;
        _newImageBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // ✅ FIX: Add any pending text in controllers to their lists before saving
      if (_interestsController.text.trim().isNotEmpty) {
        _interests.add(_interestsController.text.trim());
        _interestsController.clear();
      }
      if (_goalsController.text.trim().isNotEmpty) {
        _goals.add(_goalsController.text.trim());
        _goalsController.clear();
      }
      if (_learningStyleController.text.trim().isNotEmpty) {
        _learningStyles.add(_learningStyleController.text.trim());
        _learningStyleController.clear();
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving profile...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await _dbService.updateUserProfile(
        uid: userId,
        firstName: _profileData?['firstName'] ?? '',
        lastName: _profileData?['lastName'] ?? '',
        jobTitle: _profileData?['jobTitle'] ?? '',
        location: _profileData?['location'] ?? '',
        bio: _bioController.text,
        newImage: _newImageFile,
      );

      // Update custom fields in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'interests': _interests,
        'goals': _goals,
        'learningStyles': _learningStyles,
      });

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profile updated successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        // Redirect back to previous page after a short delay
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _addInterest() {
    if (_interestsController.text.trim().isNotEmpty) {
      setState(() {
        _interests.add(_interestsController.text.trim());
        _interestsController.clear();
      });
    }
  }

  void _addGoal() {
    if (_goalsController.text.trim().isNotEmpty) {
      setState(() {
        _goals.add(_goalsController.text.trim());
        _goalsController.clear();
      });
    }
  }

  void _addLearningStyle() {
    if (_learningStyleController.text.trim().isNotEmpty) {
      setState(() {
        _learningStyles.add(_learningStyleController.text.trim());
        _learningStyleController.clear();
      });
    }
  }

  void _removeInterest(int index) {
    setState(() => _interests.removeAt(index));
  }

  void _removeGoal(int index) {
    setState(() => _goals.removeAt(index));
  }

  void _removeLearningStyle(int index) {
    setState(() => _learningStyles.removeAt(index));
  }

  @override
  void dispose() {
    _bioController.dispose();
    _interestsController.dispose();
    _goalsController.dispose();
    _learningStyleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String fullName = _profileData?['fullName'] ?? 'User';
    final String bio = _bioController.text.isNotEmpty
        ? _bioController.text
        : 'No biography provided yet.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
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
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child:
                            const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Text(
                        'Student Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_isEditing) {
                            _saveProfile();
                          } else {
                            setState(() => _isEditing = true);
                          }
                        },
                        child: Icon(
                          _isEditing ? Icons.save : Icons.edit,
                          color: Colors.white,
                        ),
                      ),
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
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _newImageBytes != null
                                    ? MemoryImage(_newImageBytes!)
                                    : ((_profileData?['profileImageUrl'] ?? '')
                                            .isNotEmpty
                                        ? NetworkImage(
                                            _profileData!['profileImageUrl'])
                                        : null) as ImageProvider?,
                                child: _newImageBytes == null &&
                                        (_profileData?['profileImageUrl'] ?? '')
                                            .isEmpty
                                    ? ClipOval(
                                        child: Image.asset(
                                          'images/default_avatar.png',
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => const Icon(
                                              Icons.person,
                                              size: 50),
                                        ),
                                      )
                                    : null,
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2D6A65),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Student',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _profileData?['location'] ?? 'Tagum City',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 20),
                          // Edit Profile Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                if (_isEditing) {
                                  _saveProfile();
                                } else {
                                  setState(() => _isEditing = true);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0xFF2D6A65), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                _isEditing ? 'Save Profile' : 'Edit Profile',
                                style: const TextStyle(
                                  color: Color(0xFF2D6A65),
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

                    // About Section
                    _buildInfoCard(
                      title: 'About',
                      child: _isEditing
                          ? TextField(
                              controller: _bioController,
                              minLines: 3,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'Write something about yourself',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            )
                          : Text(
                              bio,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700]),
                            ),
                    ),

                    // Interests Section
                    _buildInfoCard(
                      title: 'Interests',
                      child: _isEditing
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _interestsController,
                                        decoration: InputDecoration(
                                          hintText: 'Add interest',
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _addInterest,
                                      icon: const Icon(Icons.add_circle,
                                          color: Color(0xFF2D6A65)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _interests.map((interest) {
                                    final index = _interests.indexOf(interest);
                                    return Chip(
                                      label: Text(interest),
                                      deleteIcon:
                                          const Icon(Icons.close, size: 18),
                                      onDeleted: () => _removeInterest(index),
                                      backgroundColor: const Color(0xFFE8F5F3),
                                      side: BorderSide.none,
                                    );
                                  }).toList(),
                                ),
                              ],
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _interests.isEmpty
                                  ? [
                                      Text('No interests added yet.',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700]))
                                    ]
                                  : _interests.map((interest) {
                                      return Chip(
                                        label: Text(interest),
                                        backgroundColor:
                                            const Color(0xFFE8F5F3),
                                        side: BorderSide.none,
                                      );
                                    }).toList(),
                            ),
                    ),

                    // Learning Goals Section
                    _buildInfoCard(
                      title: 'Learning Goals',
                      child: _isEditing
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _goalsController,
                                        decoration: InputDecoration(
                                          hintText: 'Add learning goal',
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _addGoal,
                                      icon: const Icon(Icons.add_circle,
                                          color: Color(0xFF2D6A65)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _goals.map((goal) {
                                    final index = _goals.indexOf(goal);
                                    return Chip(
                                      label: Text(goal),
                                      deleteIcon:
                                          const Icon(Icons.close, size: 18),
                                      onDeleted: () => _removeGoal(index),
                                      backgroundColor: const Color(0xFFE8F5F3),
                                      side: BorderSide.none,
                                    );
                                  }).toList(),
                                ),
                              ],
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _goals.isEmpty
                                  ? [
                                      Text('No learning goals added yet.',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700]))
                                    ]
                                  : _goals.map((goal) {
                                      return Chip(
                                        label: Text(goal),
                                        backgroundColor:
                                            const Color(0xFFE8F5F3),
                                        side: BorderSide.none,
                                      );
                                    }).toList(),
                            ),
                    ),

                    // Learning Preferences Section
                    _buildInfoCard(
                      title: 'Learning Preferences',
                      child: _isEditing
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _learningStyleController,
                                        decoration: InputDecoration(
                                          hintText: 'Add learning preference',
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _addLearningStyle,
                                      icon: const Icon(Icons.add_circle,
                                          color: Color(0xFF2D6A65)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _learningStyles.map((style) {
                                    final index =
                                        _learningStyles.indexOf(style);
                                    return Chip(
                                      label: Text(style),
                                      deleteIcon:
                                          const Icon(Icons.close, size: 18),
                                      onDeleted: () =>
                                          _removeLearningStyle(index),
                                      backgroundColor: const Color(0xFFE8F5F3),
                                      side: BorderSide.none,
                                    );
                                  }).toList(),
                                ),
                              ],
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _learningStyles.isEmpty
                                  ? [
                                      Text('No learning preferences added yet.',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700]))
                                    ]
                                  : _learningStyles.map((style) {
                                      return Chip(
                                        label: Text(style),
                                        backgroundColor:
                                            const Color(0xFFE8F5F3),
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

  Widget _buildInfoCard({required String title, required Widget child}) {
    IconData sectionIcon;
    switch (title) {
      case 'About':
        sectionIcon = Icons.info_outline;
        break;
      case 'Interests':
        sectionIcon = Icons.favorite_outline;
        break;
      case 'Learning Goals':
        sectionIcon = Icons.flag_outlined;
        break;
      case 'Learning Preferences':
        sectionIcon = Icons.tune_outlined;
        break;
      default:
        sectionIcon = Icons.bookmark_border;
    }

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
              Icon(sectionIcon, size: 18, color: const Color(0xFF2D6A65)),
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
}
