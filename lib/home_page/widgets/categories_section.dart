import 'package:flutter/material.dart';
import 'category_card.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Categories",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Navigates to the Service Category page
                  Navigator.pushNamed(context, '/service_category');
                },
                child: const Text(
                  "See all",
                  style: TextStyle(color: Color(0xFF2D6A65)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: const [
              CategoryCard(icon: Icons.computer, label: 'Technology'),
              CategoryCard(icon: Icons.palette, label: 'Design'),
              CategoryCard(icon: Icons.business, label: 'Business'),
              CategoryCard(icon: Icons.campaign, label: 'Marketing'),
            ],
          ),
        ],
      ),
    );
  }
}
