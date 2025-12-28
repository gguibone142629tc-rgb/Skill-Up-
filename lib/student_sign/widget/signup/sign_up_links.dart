import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SignUpLinks extends StatelessWidget {
  const SignUpLinks({
    super.key,
    required this.onLoginTap,
    required this.onApplyTap,
  });

  final VoidCallback onLoginTap;
  final VoidCallback onApplyTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF7C4DFF);

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
        children: [
          const TextSpan(text: 'Already have an account? '),
          TextSpan(
            text: 'Log in',
            style: const TextStyle(color: accent, fontWeight: FontWeight.w600),
            recognizer: TapGestureRecognizer()..onTap = onLoginTap,
          ),
          const TextSpan(text: '\nLooking to join us as a mentor? '),
          TextSpan(
            text: 'Apply now',
            style: const TextStyle(color: accent, fontWeight: FontWeight.w600),
            recognizer: TapGestureRecognizer()..onTap = onApplyTap,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
