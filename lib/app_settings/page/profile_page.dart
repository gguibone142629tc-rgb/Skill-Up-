import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finaproj/Profile_page/decor/info_card_decor.dart';
import 'package:finaproj/Profile_page/widgets/expertise_chips.dart';
import 'package:finaproj/Profile_page/widgets/profile_header.dart';
import 'package:finaproj/app_settings/widget/profile_widget.dart';
import 'package:finaproj/main.dart';
import 'package:finaproj/Profile_page/pages/my_profile_page.dart';
import 'package:finaproj/membershipPlan/pages/membership_page.dart'; // 1. Import Membership Page
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
    if (currentUser == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Profile",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
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

            // Normalize role to lowercase to avoid "Mentor" vs "mentor" issues
            final String role =
                (userData['role'] ?? 'student').toString().toLowerCase();

            return Column(
              children: [
                ProfileHeader(mentorData: userData),

                // --- BUTTON ROW ---
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      // 1. EDIT PROFILE BUTTON
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MyProfilePage(startEditing: true)),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            side: const BorderSide(color: Color(0xFF2D6A65)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text("Edit Profile",
                              style: TextStyle(color: Color(0xFF2D6A65))),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // 2. VIEW PLAN BUTTON (Visible to Mentors)
                      // Logic: Show if role is mentor OR if you want to test it regardless
                      if (role == 'mentor')
                        Expanded(
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
                                  borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                            ),
                            child: const Text("View Plan",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                ),

                if (role == 'mentor') ...[
                  InfoCard(title: "About", content: bio),
                  ExpertiseChips(title: "Expertise", labels: expertise),
                  ExpertiseChips(title: "Skills", labels: skills),
                ] else ...[
                  InfoCard(title: "About", content: bio),
                  ExpertiseChips(
                      title: "Interests",
                      labels: List<String>.from(userData['interests'] ?? [])),
                  ExpertiseChips(
                      title: "Learning Goals",
                      labels: List<String>.from(userData['goals'] ?? [])),
                  ExpertiseChips(
                      title: "Learning Preferences",
                      labels:
                          List<String>.from(userData['learningStyles'] ?? [])),
                ],
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(initialIndex: 3),
    );
  }
}
