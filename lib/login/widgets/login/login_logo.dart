import 'package:flutter/material.dart';

class LoginLogo extends StatelessWidget {
  final double height;
  const LoginLogo({super.key, this.height = 60});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2E6F6A);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/skillup_logo.png',
          height: height,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        Text(
          'SkillUp',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
