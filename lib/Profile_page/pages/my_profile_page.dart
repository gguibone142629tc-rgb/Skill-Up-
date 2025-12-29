import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finaproj/services/database_service.dart';

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
    _loadProfile();
    _initializeControllers();
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
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header (aligned with view screen)
            Center(
              child: Column(
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
                                ? NetworkImage(_profileData!['profileImageUrl'])
                                : null) as ImageProvider?,
                        child: _newImageBytes == null &&
                                (_profileData?['profileImageUrl'] ?? '').isEmpty
                            ? const Icon(Icons.person, size: 50)
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
                  const SizedBox(height: 16),
                  Text(
                    _profileData?['fullName'] ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profileData?['jobTitle'] ?? 'Mentor',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profileData?['location'] ?? 'Location',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Edit/Save CTA to mirror profile view
            ElevatedButton.icon(
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                }
                setState(() => _isEditing = !_isEditing);
              },
              icon: Icon(_isEditing ? Icons.check : Icons.edit, size: 20),
              label: Text(
                _isEditing ? 'Save Changes' : 'Edit Profile',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A65),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 20),

            // About Me section for parity with view page
            _buildSection(
              title: 'About Me',
              isEditing: _isEditing,
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
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _bioController.text.isNotEmpty
                            ? _bioController.text
                            : 'No biography provided yet.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // Expertise Section
            _buildSection(
              title: 'Expertise',
              isEditing: _isEditing,
              child: _isEditing
                  ? Column(
                      children: [
                        TextField(
                          controller: _expertiseController,
                          decoration: InputDecoration(
                            hintText: 'Add expertise',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addExpertise,
                            ),
                          ),
                          onSubmitted: (_) => _addExpertise(),
                        ),
                        const SizedBox(height: 12),
                        if (_expertise.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(_expertise.length, (index) {
                              return _buildChip(_expertise[index],
                                  () => _removeExpertise(index));
                            }),
                          ),
                      ],
                    )
                  : _expertise.isEmpty
                      ? Text(
                          'No information provided',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _expertise.map((exp) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                exp,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                        ),
            ),
            const SizedBox(height: 24),

            // Disciplines Section
            _buildSection(
              title: 'Disciplines',
              isEditing: _isEditing,
              child: _isEditing
                  ? Column(
                      children: [
                        TextField(
                          controller: _disciplinesController,
                          decoration: InputDecoration(
                            hintText: 'Add discipline',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addDiscipline,
                            ),
                          ),
                          onSubmitted: (_) => _addDiscipline(),
                        ),
                        const SizedBox(height: 12),
                        if (_disciplines.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                List.generate(_disciplines.length, (index) {
                              return _buildChip(_disciplines[index],
                                  () => _removeDiscipline(index));
                            }),
                          ),
                      ],
                    )
                  : _disciplines.isEmpty
                      ? Text(
                          'No information provided',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _disciplines.map((disc) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                disc,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                        ),
            ),
            const SizedBox(height: 24),

            // Fluent In Section
            _buildSection(
              title: 'Fluent In',
              isEditing: _isEditing,
              child: _isEditing
                  ? Column(
                      children: [
                        TextField(
                          controller: _languagesController,
                          decoration: InputDecoration(
                            hintText: 'Add language',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addLanguage,
                            ),
                          ),
                          onSubmitted: (_) => _addLanguage(),
                        ),
                        const SizedBox(height: 12),
                        if (_languages.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(_languages.length, (index) {
                              return _buildChip(_languages[index],
                                  () => _removeLanguage(index));
                            }),
                          ),
                      ],
                    )
                  : _languages.isEmpty
                      ? Text(
                          'No information provided',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _languages.map((lang) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Text(
                                lang,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.blue[700]),
                              ),
                            );
                          }).toList(),
                        ),
            ),
            const SizedBox(height: 30),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemove,
      backgroundColor: Colors.grey[200],
      side: BorderSide(color: Colors.grey[300]!),
    );
  }
}
