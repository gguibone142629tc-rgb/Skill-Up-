import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finaproj/app_settings/widget/profile_widget.dart';
import 'package:finaproj/main.dart';
import 'package:finaproj/Profile_page/pages/my_profile_page.dart';
import 'package:finaproj/Profile_page/pages/mentee_profile_page.dart';
import 'package:finaproj/membershipPlan/pages/membership_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text("Account Settings",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ProfileWidget(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Profile not found"));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            userData['uid'] = currentUser!.uid;

            final List<String> expertise =
                List<String>.from(userData['expertise'] ?? []);
            final List<String> skills =
                List<String>.from(userData['skills'] ?? []);
            final String bio = userData['bio'] ?? 'No bio provided.';
            final String fullName =
                '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                    .trim();

            // Normalize role to lowercase to avoid "Mentor" vs "mentor" issues
            final String role =
                (userData['role'] ?? 'student').toString().toLowerCase();

            return Column(
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6B9A91),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 24),
                          Text(
                            role == 'mentor'
                                ? 'Mentor Profile'
                                : 'Student Profile',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined,
                                color: Colors.white),
                            onPressed: _showSettingsMenu,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Icon placeholder
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          role == 'mentor' ? '👨‍🏫' : '📚',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Content
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Avatar and Info Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: (userData['profileImageUrl'] ??
                                            '')
                                        .isNotEmpty
                                    ? NetworkImage(userData['profileImageUrl'])
                                    : null,
                                child:
                                    (userData['profileImageUrl'] ?? '').isEmpty
                                        ? ClipOval(
                                            child: Image.asset(
                                              'assets/images/default_avatar.png',
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) =>
                                                  const Icon(Icons.person,
                                                      size: 50),
                                            ),
                                          )
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                role == 'mentor' ? 'Mentor' : 'Student',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userData['location'] ?? 'Tagum City',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 20),
                              // Edit Profile Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    if (role == 'mentor') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const MyProfilePage(
                                                    startEditing: true)),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const MenteeProfilePage(
                                                    startEditing: true)),
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFF2D6A65), width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: const Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      color: Color(0xFF2D6A65),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              if (role == 'mentor') ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MembershipPage(
                                            isMentorView: true,
                                            mentorData: userData,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2D6A65),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      elevation: 0,
                                    ),
                                    child: const Text("View Plan",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // About Section
                        _buildInfoCard(
                          title: 'About',
                          child: Text(
                            bio,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                          ),
                        ),

                        // Role-specific sections
                        if (role == 'mentor') ...[
                          _buildInfoCard(
                            title: 'Expertise',
                            child: expertise.isEmpty
                                ? Text('No expertise added yet.',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]))
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: expertise.map((item) {
                                      return Chip(
                                        label: Text(item),
                                        backgroundColor:
                                            const Color(0xFFE8F5F3),
                                        side: BorderSide.none,
                                      );
                                    }).toList(),
                                  ),
                          ),
                          _buildInfoCard(
                            title: 'Skills',
                            child: skills.isEmpty
                                ? Text('No skills added yet.',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]))
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: skills.map((item) {
                                      return Chip(
                                        label: Text(item),
                                        backgroundColor:
                                            const Color(0xFFE8F5F3),
                                        side: BorderSide.none,
                                      );
                                    }).toList(),
                                  ),
                          ),
                          _buildInfoCard(
                            title: 'Languages',
                            child: (userData['languages'] ?? []).isEmpty
                                ? Text('No languages added yet.',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]))
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List<String>.from(
                                            userData['languages'] ?? [])
                                        .map((item) {
                                      return Chip(
                                        label: Text(item),
                                        backgroundColor:
                                            const Color(0xFFE8F5F3),
                                        side: BorderSide.none,
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ] else ...[
                          _buildInfoCard(
                            title: 'Interests',
                            child: (userData['interests'] ?? []).isEmpty
                                ? Text('No interests added yet.',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]))
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List<String>.from(
                                            userData['interests'] ?? [])
                                        .map((item) {
                                      return Chip(
                                        label: Text(item),
                                        backgroundColor:
                                            const Color(0xFFE8F5F3),
                                        side: BorderSide.none,
                                      );
                                    }).toList(),
                                  ),
                          ),
                          _buildInfoCard(
                            title: 'Learning Goals',
                            child: (userData['goals'] ?? []).isEmpty
                                ? Text('No learning goals added yet.',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]))
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List<String>.from(
                                            userData['goals'] ?? [])
                                        .map((item) {
                                      return Chip(
                                        label: Text(item),
                                        backgroundColor:
                                            const Color(0xFFE8F5F3),
                                        side: BorderSide.none,
                                      );
                                    }).toList(),
                                  ),
                          ),
                          _buildInfoCard(
                            title: 'Learning Preferences',
                            child: (userData['learningStyles'] ?? []).isEmpty
                                ? Text('No learning preferences added yet.',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]))
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List<String>.from(
                                            userData['learningStyles'] ?? [])
                                        .map((item) {
                                      return Chip(
                                        label: Text(item),
                                        backgroundColor:
                                            const Color(0xFFE8F5F3),
                                        side: BorderSide.none,
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ],

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(initialIndex: 3),
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    IconData sectionIcon;
    switch (title) {
      case 'About':
        sectionIcon = Icons.info_outline;
        break;
      case 'Expertise':
        sectionIcon = Icons.stars_outlined;
        break;
      case 'Skills':
        sectionIcon = Icons.construction_outlined;
        break;
      case 'Languages':
        sectionIcon = Icons.language_outlined;
        break;
      case 'Interests':
        sectionIcon = Icons.favorite_outline;
        break;
      case 'Learning Goals':
        sectionIcon = Icons.flag_outlined;
        break;
      case 'Learning Preferences':
        sectionIcon = Icons.tune_outlined;
        break;
      default:
        sectionIcon = Icons.bookmark_border;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(sectionIcon, size: 18, color: const Color(0xFF2D6A65)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D6A65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
