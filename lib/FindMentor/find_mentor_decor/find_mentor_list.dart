import 'package:finaproj/home_page/model/mentor_model.dart'; // Use the shared Mentor model
import 'package:flutter/material.dart';
import 'package:finaproj/Profile_page/pages/pofile_page.dart'; // Import Profile Page
import 'package:finaproj/app_settings/page/profile_page.dart';
import 'package:finaproj/membershipPlan/model/membership_plan.dart'; // Membership plan helper
import 'package:finaproj/common/mentor_avatar.dart'; // Shared avatar widget
import 'package:firebase_auth/firebase_auth.dart';

class FindMentorList extends StatelessWidget {
  const FindMentorList({super.key, required this.mentor});

  final Mentor mentor; // Changed from FindMentorModel to Mentor

  @override
  Widget build(BuildContext context) {
    // Helper to get skills safely
    String skill1 = mentor.skills.isNotEmpty ? mentor.skills[0] : 'Mentoring';
    String? skill2 = mentor.skills.length > 1 ? mentor.skills[1] : null;

    // Price display helper that prefers membership plan starting price
    String displayPrice(Mentor mentor) {
      if (mentor.planPrice != null && mentor.planPrice! > 0) {
        return '₱${mentor.planPrice}/month';
      }
      if (mentor.planTitle != null && mentor.planTitle!.isNotEmpty) {
        final p = MembershipPlan.getPriceForTitle(mentor.planTitle);
        return '₱$p/month';
      }
      final parsed =
          int.tryParse(mentor.pricePerMonth.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed != null && parsed > 0) return '₱$parsed/month';
      return '₱${MembershipPlan.defaultStartingPrice}/month';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      // height removed to let it grow dynamically
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 5,
              offset: const Offset(0, 5),
            )
          ]),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Image, Name, Job
            Row(
              children: [
                // Unified avatar (circular) — use shared MentorAvatar to keep visuals consistent
                MentorAvatar(
                  image: mentor.image,
                  name: mentor.name,
                  size: 50,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mentor.jobTitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Rating Star
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      mentor.rating.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),

            const SizedBox(height: 16),

            // Row 2: Skills Chips
            Row(
              children: [
                _buildSkillChip(skill1),
                if (skill2 != null) ...[
                  const SizedBox(width: 8),
                  _buildSkillChip(skill2),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Row 3: Price and Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayPrice(mentor),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2D6A65),
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {
                      final currentUserId =
                          FirebaseAuth.instance.currentUser?.uid;
                      final isOwnProfile = mentor.id == currentUserId;

                      if (isOwnProfile) {
                        // Navigate to own profile page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      } else {
                        // Navigate to other mentor's profile
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              mentorData: {
                                'uid': mentor.id,
                                'firstName': mentor.name.split(' ')[0],
                                'lastName': mentor.name.split(' ').length > 1
                                    ? mentor.name.split(' ')[1]
                                    : '',
                                'jobTitle': mentor.jobTitle,
                                'bio':
                                    'Experienced mentor ready to help you grow.',
                                'skills': mentor.skills,
                                'profileImageUrl': mentor.image,
                                'price': displayPrice(mentor),
                                'rating': mentor.rating,
                              },
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A65),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('View Profile',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
      ),
    );
  }
}
