import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FindMentorSearchWidget extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap; // ✅ Added Callback
  final String initialText;

  const FindMentorSearchWidget({
    super.key,
    required this.onSearchChanged,
    required this.onFilterTap, // ✅ Required
    this.initialText = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Builder(
                builder: (context) {
                  final controller = TextEditingController(text: initialText);
                  return TextField(
                    controller: controller,
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      hintText: 'Search mentors or students...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Filter Button
          GestureDetector(
            onTap: onFilterTap, // ✅ Opens the Filter Modal
            child: Container(
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
                placeholderBuilder: (_) =>
                    const Icon(Icons.tune, color: Color(0xFF2D6A65)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
