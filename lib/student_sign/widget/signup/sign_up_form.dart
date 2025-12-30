import 'package:finaproj/common/auth_text_field.dart';
import 'package:finaproj/common/primary_button.dart';
import 'package:flutter/material.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    required this.onGenderChanged,
    this.isLoading = false,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final ValueChanged<String> onGenderChanged;
  final bool isLoading;

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  String _selectedGender = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          label: 'First Name',
          controller: widget.firstNameController,
          hintText: 'John',
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Last Name',
          controller: widget.lastNameController,
          hintText: 'Doe',
        ),
        const SizedBox(height: 16),
        // Gender Dropdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gender',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedGender.isEmpty ? null : _selectedGender,
              decoration: InputDecoration(
                hintText: 'Select Gender',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: ['Male', 'Female', 'Other'].map((gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedGender = value);
                  widget.onGenderChanged(value);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Email',
          controller: widget.emailController,
          hintText: 'john@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Password',
          controller: widget.passwordController,
          hintText: '●●●●●●●●',
          obscure: true,
          showObscureToggle: true,
        ),
        const SizedBox(height: 24),
        // Switch between button and spinner based on state
        widget.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2D6A65)))
            : PrimaryButton(label: 'Sign up', onPressed: widget.onSubmit),
      ],
    );
  }
}
