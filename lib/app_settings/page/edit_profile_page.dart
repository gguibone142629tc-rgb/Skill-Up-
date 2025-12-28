import 'dart:typed_data'; // Needed for MemoryImage
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Imports from your project
import 'package:finaproj/common/auth_text_field.dart';
import 'package:finaproj/common/primary_button.dart';
import 'package:finaproj/services/database_service.dart'; // Import DB Service

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool _isLoading = false;

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  // Image State
  String? _currentImageUrl; // The URL currently in Firebase
  Uint8List? _newImageBytes; // The new image data (for preview)
  XFile? _newImageFile;      // The file to send to Cloudinary

  final User? user = FirebaseAuth.instance.currentUser;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch current data to pre-fill fields
  Future<void> _fetchUserData() async {
    if (user == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _jobTitleController.text = data['jobTitle'] ?? '';
          _locationController.text = data['location'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _currentImageUrl = data['profileImageUrl'];
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newImageFile = picked; // Save XFile for upload
        _newImageBytes = bytes; // Save Bytes for display
      });
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;
    setState(() => _isLoading = true);

    try {
      await _dbService.updateUserProfile(
        uid: user!.uid,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        location: _locationController.text.trim(),
        bio: _bioController.text.trim(),
        newImage: _newImageFile, // Pass the XFile (or null)
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated Successfully!')),
        );
        Navigator.pop(context); // Return to Profile Page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic to decide which image to show
    ImageProvider? imageProvider;
    if (_newImageBytes != null) {
      imageProvider = MemoryImage(_newImageBytes!); // Show new pick
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentImageUrl!); // Show existing
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Pic
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
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
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Fields
            Row(
              children: [
                Expanded(
                    child: AuthTextField(
                        label: "First Name",
                        controller: _firstNameController)),
                const SizedBox(width: 12),
                Expanded(
                    child: AuthTextField(
                        label: "Last Name", controller: _lastNameController)),
              ],
            ),
            const SizedBox(height: 16),

            AuthTextField(
              label: "Job Title",
              controller: _jobTitleController,
              hintText: "e.g. Senior Product Designer",
            ),
            const SizedBox(height: 16),

            AuthTextField(
              label: "Location",
              controller: _locationController,
              hintText: "e.g. Manila, Philippines",
            ),
            const SizedBox(height: 16),

            // Bio Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bio", style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _bioController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    hintText: "Tell us a little about yourself...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Save Button
            _isLoading
                ? const CircularProgressIndicator()
                : PrimaryButton(
                    label: "Save Changes",
                    onPressed: _saveProfile,
                  ),
          ],
        ),
      ),
    );
  }
}