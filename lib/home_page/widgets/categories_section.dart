import 'package:finaproj/FindMentor/page/find_mentor_page.dart';
import 'package:flutter/material.dart';
import 'category_card.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                  Navigator.pushNamed(context, '/service_category');
                },
                child: const Text(
                  "See all",
                  style: TextStyle(color: Color(0xFF2D6A65)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 1. Removed "const" and used GridView with children
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.0,
            children: [
              _buildCategory(context, Icons.computer, 'Technology'),
              _buildCategory(context, Icons.palette, 'Design'),
              _buildCategory(context, Icons.business, 'Business'),
              _buildCategory(context, Icons.campaign, 'Marketing'),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Helper method to make cards clickable
  Widget _buildCategory(BuildContext context, IconData icon, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF2D6A65).withOpacity(0.15),
        highlightColor: const Color(0xFF2D6A65).withOpacity(0.08),
        onTap: () {
          // Map simple labels to one or more search categories
          List<String>? mapped;
          if (label == 'Technology') {
            mapped = ['Program & Tech', 'Build AI Service', 'Data'];
          } else if (label == 'Design') {
            mapped = ['Graphic Design'];
          } else if (label == 'Marketing') {
            mapped = ['Digital Marketing'];
          } else {
            mapped = null;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FindMentorPage(initialCategory: label, initialCategories: mapped, hideStudents: true),
            ),
          );
        },
        child: CategoryCard(icon: icon, label: label),
      ),
    );
  }
}