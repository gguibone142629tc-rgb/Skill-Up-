import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Imports from your project
import 'package:finaproj/common/auth_text_field.dart';
import 'package:finaproj/common/primary_button.dart';
import 'package:finaproj/services/database_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool _isLoading = false;
  bool _isFetchingData = true;

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _locationController = TextEditingController();

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
    setState(() => _isFetchingData = true);
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
          _isFetchingData = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) setState(() => _isFetchingData = false);
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
        bio: '',
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
    if (_isFetchingData) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2D6A65),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Personal Details"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Fields
            Row(
              children: [
                Expanded(
                    child: AuthTextField(
                        label: "First Name", controller: _firstNameController)),
                const SizedBox(width: 12),
                Expanded(
                    child: AuthTextField(
                        label: "Last Name", controller: _lastNameController)),
              ],
            ),
            const SizedBox(height: 16),

            AuthTextField(
              label: "Location",
              controller: _locationController,
              hintText: "e.g. Manila, Philippines",
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
