import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finaproj/services/database_service.dart';

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
    _loadProfile();
    _initializeControllers();
  }

  void _initializeControllers() {
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
        bio: '',
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

        // Exit edit mode and reload profile
        setState(() => _isEditing = false);
        await _loadProfile();
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A65),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                _isEditing ? 'Save' : 'Edit',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _newImageBytes != null
                          ? MemoryImage(_newImageBytes!)
                          : ((_profileData?['profileImageUrl'] ?? '').isNotEmpty
                              ? NetworkImage(_profileData!['profileImageUrl'])
                              : null) as ImageProvider?,
                      child: _newImageBytes == null &&
                              (_profileData?['profileImageUrl'] ?? '').isEmpty
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2D6A65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profileData?['fullName'] ?? 'User',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Student',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profileData?['location'] ?? 'Location',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Interests Section
            _buildSection(
              title: 'Interests',
              isEditing: _isEditing,
              child: _isEditing
                  ? Column(
                      children: [
                        TextField(
                          controller: _interestsController,
                          decoration: InputDecoration(
                            hintText: 'Add interest',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addInterest,
                            ),
                          ),
                          onSubmitted: (_) => _addInterest(),
                        ),
                        const SizedBox(height: 12),
                        if (_interests.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(_interests.length, (index) {
                              return _buildChip(_interests[index],
                                  () => _removeInterest(index));
                            }),
                          ),
                      ],
                    )
                  : _interests.isEmpty
                      ? Text(
                          'No information provided',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _interests.map((interest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                interest,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                        ),
            ),
            const SizedBox(height: 24),

            // Goals Section
            _buildSection(
              title: 'Learning Goals',
              isEditing: _isEditing,
              child: _isEditing
                  ? Column(
                      children: [
                        TextField(
                          controller: _goalsController,
                          decoration: InputDecoration(
                            hintText: 'Add goal',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addGoal,
                            ),
                          ),
                          onSubmitted: (_) => _addGoal(),
                        ),
                        const SizedBox(height: 12),
                        if (_goals.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(_goals.length, (index) {
                              return _buildChip(
                                  _goals[index], () => _removeGoal(index));
                            }),
                          ),
                      ],
                    )
                  : _goals.isEmpty
                      ? Text(
                          'No information provided',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _goals.map((goal) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                goal,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                        ),
            ),
            const SizedBox(height: 24),

            // Learning Style Section
            _buildSection(
              title: 'Learning Preferences',
              isEditing: _isEditing,
              child: _isEditing
                  ? Column(
                      children: [
                        TextField(
                          controller: _learningStyleController,
                          decoration: InputDecoration(
                            hintText: 'Add learning preference',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addLearningStyle,
                            ),
                          ),
                          onSubmitted: (_) => _addLearningStyle(),
                        ),
                        const SizedBox(height: 12),
                        if (_learningStyles.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                List.generate(_learningStyles.length, (index) {
                              return _buildChip(_learningStyles[index],
                                  () => _removeLearningStyle(index));
                            }),
                          ),
                      ],
                    )
                  : _learningStyles.isEmpty
                      ? Text(
                          'No information provided',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _learningStyles.map((style) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                style,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                        ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isEditing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSectionIcon(title),
                size: 20,
                color: const Color(0xFF2D6A65),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
      case 'Interests':
        return Icons.interests_outlined;
      case 'Learning Goals':
        return Icons.flag_outlined;
      case 'Learning Preferences':
        return Icons.school_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A65).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2D6A65).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: Color(0xFF2D6A65),
            ),
          ),
        ],
      ),
    );
  }
}
