import 'package:flutter/material.dart';

class RememberForgotRow extends StatelessWidget {
  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onForgot;

  const RememberForgotRow({
    super.key,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C4DFF);
    return Row(
      children: [
        Checkbox(
          value: rememberMe,
          onChanged: (v) => onRememberChanged(v ?? false),
          activeColor: accent,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const Text('Remember me'),
        const Spacer(),
        TextButton(
          onPressed: onForgot,
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Text('Forgot Password?'),
        ),
      ],
    );
  }
}
