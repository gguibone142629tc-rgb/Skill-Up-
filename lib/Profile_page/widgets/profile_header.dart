import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> mentorData;
  const ProfileHeader({super.key, required this.mentorData});

  @override
  Widget build(BuildContext context) {
    // 1. EXTRACT DATA DYNAMICALLY
    final String fName = mentorData['firstName'] ?? 'User';
    final String lName = mentorData['lastName'] ?? '';
    final String job = mentorData['jobTitle'] ?? 'Mentor';
    
    // This is the key: Check if a URL exists in the database
    final String imgUrl = mentorData['profileImageUrl'] ?? '';

    // Default to 5.0 if no rating exists
    final double rating = (mentorData['rating'] ?? 5.0).toDouble(); 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Blue Background Banner
            Container(
              height: 140,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFA9CCE3), // Light Blue
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            // 2. LOGO + "SKILL UP" (Fixed Static Assets)
            Positioned(
              top: 40, 
              left: 125, 
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/skillup_logo.png",
                    height: 100, 
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                   
                  const Text(
                    "SKILL UP",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900, 
                      fontSize: 24, 
                      letterSpacing: 0.5,
                      height: 1.0, 
                    ),
                  ),
                ],
              ),
            ),

            // 3. DYNAMIC AVATAR (Left Aligned)
            Positioned(
              bottom: -50, 
              left: 25,
              child: Container(
                padding: const EdgeInsets.all(5), // White border
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: imgUrl.isNotEmpty ? NetworkImage(imgUrl) : null,
                  // If no URL, show the project's default avatar asset (fallback to Icon if asset missing)
                  child: imgUrl.isEmpty
                      ? ClipOval(
                          child: Image.asset(
                            'assets/images/default_avatar.png',
                            height: 104,
                            width: 104,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: Colors.grey),
                          ),
                        )
                      : null,
                ),
              ),
            ),

            // 6. RATING BADGE (Dynamic Rating)
            Positioned(
              bottom: -40,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4), // Light Yellow
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_border, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.amber,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Spacer
        const SizedBox(height: 60),

        // 7. DYNAMIC NAME & JOB
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$fName $lName",
                style: const TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.w900, 
                  color: Colors.black87,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                job,
                style: const TextStyle(
                  fontSize: 16, 
                  color: Colors.black87,
                  fontWeight: FontWeight.w500
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}