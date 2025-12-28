import 'dart:typed_data'; // Needed for Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finaproj/common/auth_text_field.dart'; 
import 'upload_photo_field.dart';

// ❌ NO IMPORT DART:IO HERE!

class MentorBasicInfoStep extends StatefulWidget {
  const MentorBasicInfoStep({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
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
  // We store the image as Bytes (Memory), which works on Web & Mobile
  Uint8List? _imageBytes; 

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    
    if (picked != null) {
      // Read the bytes immediately. Safe for all platforms.
      final bytes = await picked.readAsBytes();
      
      setState(() {
        _imageBytes = bytes;
      });
      
      // Send the XFile back to the parent for uploading later
      widget.onImageSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        
        // 1. Upload Photo Field
        UploadPhotoField(
          onUpload: _pickImage,
          // If we have bytes, use MemoryImage. If not, pass null.
          imageProvider: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
        ),

        const SizedBox(height: 24),
        
        // 2. Form Fields
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