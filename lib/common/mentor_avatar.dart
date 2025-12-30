import 'package:flutter/material.dart';

class MentorAvatar extends StatelessWidget {
  final String image; // network URL or asset path
  final String name; // used to derive initials fallback
  final double size; // width/height in pixels

  const MentorAvatar({super.key, required this.image, required this.name, this.size = 64});

  String get _initials {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: const Color(0xFF2D6A65),
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (image.isNotEmpty) {
      // Network image
      if (image.startsWith('http')) {
        return ClipOval(
          child: Image.network(
            image,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(context),
          ),
        );
      }

      // Asset image (local)
      return ClipOval(
        child: Image.asset(
          image,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholder(context),
        ),
      );
    }

    // No image provided: show initials circle
    return _placeholder(context);
  }
}
