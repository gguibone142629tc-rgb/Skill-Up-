import 'package:flutter/material.dart';

class UploadPhotoField extends StatelessWidget {
  const UploadPhotoField({super.key, this.onUpload, this.imageProvider});

  final VoidCallback? onUpload;
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFE5E7EB),
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person, color: Colors.grey, size: 28)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('Upload Photo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Make sure the file is below 2mb',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}
