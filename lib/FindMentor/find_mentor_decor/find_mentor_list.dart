import 'package:finaproj/home_page/model/mentor_model.dart'; // Use the shared Mentor model
import 'package:flutter/material.dart';
import 'package:finaproj/Profile_page/pages/pofile_page.dart'; // Import Profile Page

class FindMentorList extends StatelessWidget {
  const FindMentorList({super.key, required this.mentor});

  final Mentor mentor; // Changed from FindMentorModel to Mentor

  @override
  Widget build(BuildContext context) {
    // Helper to get skills safely
    String skill1 = mentor.skills.isNotEmpty ? mentor.skills[0] : 'Mentoring';
    String skill2 = mentor.skills.length > 1 ? mentor.skills[1] : 'Leadership';

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
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Image, Name, Job
            Row(
              children: [
                // Dynamic Image Handling
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: mentor.image.isNotEmpty
                          ? NetworkImage(mentor.image) // Use URL if available
                          : const AssetImage('assets/images/Ellipse 2057.png') as ImageProvider, // Fallback
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                const SizedBox(width: 8),
                _buildSkillChip(skill2),
              ],
            ),

            const SizedBox(height: 16),

            // Row 3: Price and Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mentor.pricePerMonth, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Profile with real data
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            mentorData: {
                              'firstName': mentor.name.split(' ')[0],
                              'lastName': mentor.name.split(' ').length > 1 ? mentor.name.split(' ')[1] : '',
                              'jobTitle': mentor.jobTitle,
                              'bio': 'Experienced mentor ready to help you grow.',
                              'skills': mentor.skills,
                              'profileImageUrl': mentor.image,
                              'price': mentor.pricePerMonth,
                              'rating': mentor.rating,
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A65),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('View Profile', style: TextStyle(color: Colors.white, fontSize: 12)),
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