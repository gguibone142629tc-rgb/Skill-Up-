import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FindMentorSearchWidget extends StatelessWidget {
  // Add this callback to listen for text changes
  final ValueChanged<String> onSearchChanged;

  const FindMentorSearchWidget({super.key, required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20), // Adjusted margin for better look
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                // Call the function whenever text changes
                onChanged: onSearchChanged, 
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search by name or role...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter Icon (Visual only for now)
          Container(
            height: 50,
            width: 50,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A65).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: SvgPicture.asset(
              'assets/icons/tune.svg', 
              color: const Color(0xFF2D6A65),
              // Fallback if svg fails
              placeholderBuilder: (_) => const Icon(Icons.tune, color: Color(0xFF2D6A65)),
            ),
          )
        ],
      ),
    );
  }
}