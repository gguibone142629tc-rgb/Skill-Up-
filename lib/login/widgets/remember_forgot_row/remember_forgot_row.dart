import 'package:flutter/material.dart';

class RememberForgotRow extends StatelessWidget {
  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;

  const RememberForgotRow({
    super.key,
    required this.rememberMe,
    required this.onRememberChanged,
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
      ],
    );
  }
}
