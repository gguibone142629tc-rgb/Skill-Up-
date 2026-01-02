import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finaproj/services/database_service.dart';
import 'package:finaproj/Profile_page/pages/mentee_profile_page.dart';

class MyProfilePage extends StatefulWidget {
  final bool startEditing;
  const MyProfilePage({super.key, this.startEditing = false});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  late bool _isEditing;

  // Controllers for editing
  late TextEditingController _expertiseController;
  late TextEditingController _disciplinesController;
  late TextEditingController _languagesController;
  late TextEditingController _bioController;

  List<String> _expertise = [];
  List<String> _disciplines = [];
  List<String> _languages = [];

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
        final role = userData?['role'] ?? 'mentor';

        if (role.toLowerCase() == 'student' && mounted) {
          // Student shouldn't be on mentor profile page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const MenteeProfilePage(startEditing: false)),
          );
        }
      } catch (e) {
        debugPrint('Error checking role: $e');
      }
    }
  }

  void _initializeControllers() {
    _expertiseController = TextEditingController();
    _disciplinesController = TextEditingController();
    _languagesController = TextEditingController();
    _bioController = TextEditingController();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userData = await _dbService.getUserData(userId);
        if (mounted) {
          setState(() {
            _profileData = userData;
            _expertise = List<String>.from(userData?['expertise'] ?? []);
            _disciplines = List<String>.from(userData?['skills'] ?? []);
            _languages = List<String>.from(
                userData?['languages'] ?? ['English', 'Filipino']);
            _bioController.text = userData?['bio'] ?? '';
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
        bio: _bioController.text,
        newImage: _newImageFile,
      );

      // Update custom fields in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'expertise': _expertise,
        'skills': _disciplines,
        'languages': _languages,
        'bio': _bioController.text,
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

  void _addExpertise() {
    if (_expertiseController.text.trim().isNotEmpty) {
      setState(() {
        _expertise.add(_expertiseController.text.trim());
        _expertiseController.clear();
      });
    }
  }

  void _addDiscipline() {
    if (_disciplinesController.text.trim().isNotEmpty) {
      setState(() {
        _disciplines.add(_disciplinesController.text.trim());
        _disciplinesController.clear();
      });
    }
  }

  void _addLanguage() {
    if (_languagesController.text.trim().isNotEmpty) {
      setState(() {
        _languages.add(_languagesController.text.trim());
        _languagesController.clear();
      });
    }
  }

  void _removeExpertise(int index) {
    setState(() => _expertise.removeAt(index));
  }

  void _removeDiscipline(int index) {
    setState(() => _disciplines.removeAt(index));
  }

  void _removeLanguage(int index) {
    setState(() => _languages.removeAt(index));
  }

  @override
  void dispose() {
    _expertiseController.dispose();
    _disciplinesController.dispose();
    _languagesController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String fullName = _profileData?['fullName'] ?? 'Mentor';
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
                        'Mentor Profile',
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
                      '👨‍🏫',
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
                                          'assets/images/default_avatar.png',
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
                            'Mentor',
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

                    // Expertise Section
                    _buildInfoCard(
                      title: 'Expertise',
                      child: _isEditing
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _expertiseController,
                                        decoration: InputDecoration(
                                          hintText: 'Add expertise',
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
                                      onPressed: _addExpertise,
                                      icon: const Icon(Icons.add_circle,
                                          color: Color(0xFF2D6A65)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _expertise.map((item) {
                                    final index = _expertise.indexOf(item);
                                    return Chip(
                                      label: Text(item),
                                      deleteIcon:
                                          const Icon(Icons.close, size: 18),
                                      onDeleted: () => _removeExpertise(index),
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
                              children: _expertise.isEmpty
                                  ? [
                                      Text('No expertise added yet.',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700]))
                                    ]
                                  : _expertise.map((item) {
                                      return Chip(
                                        label: Text(item),
                                        backgroundColor:
                                            const Color(0xFFE8F5F3),
                                        side: BorderSide.none,
                                      );
                                    }).toList(),
                            ),
                    ),

                    // Skills Section
                    _buildInfoCard(
                      title: 'Skills',
                      child: _isEditing
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _disciplinesController,
                                        decoration: InputDecoration(
                                          hintText: 'Add skill',
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
                                      onPressed: _addDiscipline,
                                      icon: const Icon(Icons.add_circle,
                                          color: Color(0xFF2D6A65)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _disciplines.map((item) {
                                    final index = _disciplines.indexOf(item);
                                    return Chip(
                                      label: Text(item),
                                      deleteIcon:
                                          const Icon(Icons.close, size: 18),
                                      onDeleted: () => _removeDiscipline(index),
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
                              children: _disciplines.isEmpty
                                  ? [
                                      Text('No skills added yet.',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700]))
                                    ]
                                  : _disciplines.map((item) {
                                      return Chip(
                                        label: Text(item),
                                        backgroundColor:
                                            const Color(0xFFE8F5F3),
                                        side: BorderSide.none,
                                      );
                                    }).toList(),
                            ),
                    ),

                    // Languages Section
                    _buildInfoCard(
                      title: 'Languages',
                      child: _isEditing
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _languagesController,
                                        decoration: InputDecoration(
                                          hintText: 'Add language',
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
                                      onPressed: _addLanguage,
                                      icon: const Icon(Icons.add_circle,
                                          color: Color(0xFF2D6A65)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _languages.map((item) {
                                    final index = _languages.indexOf(item);
                                    return Chip(
                                      label: Text(item),
                                      deleteIcon:
                                          const Icon(Icons.close, size: 18),
                                      onDeleted: () => _removeLanguage(index),
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
                              children: _languages.isEmpty
                                  ? [
                                      Text('No languages added yet.',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700]))
                                    ]
                                  : _languages.map((item) {
                                      return Chip(
                                        label: Text(item),
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
      case 'Expertise':
        sectionIcon = Icons.stars_outlined;
        break;
      case 'Skills':
        sectionIcon = Icons.construction_outlined;
        break;
      case 'Languages':
        sectionIcon = Icons.language_outlined;
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
