import 'package:flutter/material.dart';
import 'package:finaproj/FindMentor/page/find_mentor_page.dart';
import 'package:finaproj/Message/page/messages_page.dart';

class BrandingBanner extends StatelessWidget {
  final VoidCallback onTopRatedTap;
  
  const BrandingBanner({super.key, required this.onTopRatedTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D6A65), Color(0xFF4A8B85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A65).withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SkillUp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Connect. Learn. Grow.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Find expert mentors across various fields and accelerate your learning journey. Get personalized guidance from professionals.',
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontSize: 14,
              height: 1.5,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureChip(
                context,
                Icons.verified_user,
                'Verified Mentors',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FindMentorPage()),
                ),
              ),
              _buildFeatureChip(
                context,
                Icons.chat_bubble_outline,
                'Live Chat',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MessagesPage()),
                ),
              ),
              _buildFeatureChip(
                context,
                Icons.star,
                'Top Rated',
                onTopRatedTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(50),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withAlpha(100),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
