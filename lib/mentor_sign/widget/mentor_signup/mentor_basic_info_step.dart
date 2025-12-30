import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// --- IMPORTS ---
// Ensure these paths match your project structure
import 'package:finaproj/common/auth_text_field.dart';
import 'package:finaproj/mentor_sign/widget/mentor_signup/upload_photo_field.dart'; 

class MentorBasicInfoStep extends StatefulWidget {
  const MentorBasicInfoStep({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,       // <--- REQUIRED
    required this.passwordController,    // <--- REQUIRED
    required this.jobTitleController,
    required this.companyController,
    required this.locationController,
    this.onImageSelected,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;     
  final TextEditingController passwordController;  
  final TextEditingController jobTitleController;
  final TextEditingController companyController;
  final TextEditingController locationController;
  final ValueChanged<XFile?>? onImageSelected;

  @override
  State<MentorBasicInfoStep> createState() => _MentorBasicInfoStepState();
}

class _MentorBasicInfoStepState extends State<MentorBasicInfoStep> {
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _imageBytes = bytes);
        widget.onImageSelected?.call(pickedFile);
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Profile Photo ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UploadPhotoField(
              imageProvider: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
              onUpload: _pickImage,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- Names ---
        Row(
          children: [
            Expanded(
              child: AuthTextField(
                label: 'First Name',
                controller: widget.firstNameController,
                hintText: 'John',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AuthTextField(
                label: 'Last Name',
                controller: widget.lastNameController,
                hintText: 'Doe',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- Email & Password ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AuthTextField(
                label: 'Email',
                controller: widget.emailController,
                hintText: 'john@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AuthTextField(
                label: 'Password',
                controller: widget.passwordController,
                hintText: '******',
                obscure: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- Job Details ---
        AuthTextField(
            label: 'Job Title',
            controller: widget.jobTitleController,
            hintText: 'e.g. Product Designer'),
        const SizedBox(height: 16),
        AuthTextField(
            label: 'Company',
            controller: widget.companyController,
            hintText: 'e.g. Google'),
        const SizedBox(height: 16),
        AuthTextField(
            label: 'Location',
            controller: widget.locationController,
            hintText: 'e.g. New York'),
        const SizedBox(height: 20),
      ],
    );
  }
}