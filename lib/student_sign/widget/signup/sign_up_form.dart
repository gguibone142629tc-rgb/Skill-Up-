import 'package:finaproj/common/auth_text_field.dart';
import 'package:finaproj/common/primary_button.dart';
import 'package:flutter/material.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    this.isLoading = false, // Added isLoading property
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final bool isLoading; // New variable

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          label: 'First Name',
          controller: firstNameController,
          hintText: 'John',
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Last Name',
          controller: lastNameController,
          hintText: 'Doe',
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Email',
          controller: emailController,
          hintText: 'john@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Password',
          controller: passwordController,
          hintText: '●●●●●●●●',
          obscure: true,
          showObscureToggle: true,
        ),
        const SizedBox(height: 24),
        // Switch between button and spinner based on state
        isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A65)))
          : PrimaryButton(label: 'Sign up', onPressed: onSubmit),
      ],
    );
  }
}