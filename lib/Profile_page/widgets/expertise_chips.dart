import 'package:flutter/material.dart';

class ExpertiseChips extends StatelessWidget {
  final String title;
  final List<String> labels;

  const ExpertiseChips({
    super.key,
    required this.title,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          
          // If labels are empty, show a fallback text
          labels.isEmpty 
          ? const Text("No information provided", style: TextStyle(color: Colors.grey, fontSize: 13))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: labels.map((label) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueGrey.shade50),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2D6A65), fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}