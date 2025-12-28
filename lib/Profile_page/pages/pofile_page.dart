import 'package:finaproj/Profile_page/decor/info_card_decor.dart';
import 'package:finaproj/Profile_page/widgets/action_buttons.dart';
import 'package:finaproj/Profile_page/widgets/expertise_chips.dart';
import 'package:finaproj/Profile_page/widgets/profile_header.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> mentorData;

  const ProfileScreen({super.key, required this.mentorData});

  @override
  Widget build(BuildContext context) {
    // Helper to safely get lists
    List<String> getList(String key1, [String? key2]) {
      var list = mentorData[key1] ?? (key2 != null ? mentorData[key2] : []);
      if (list is List) return List<String>.from(list);
      return [];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header
            ProfileHeader(mentorData: mentorData),

            // 2. Action Buttons - CRITICAL: Pass mentorData here!
            ActionButtons(mentorData: mentorData),

            const SizedBox(height: 10),

            // 3. "View Plan" Button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to Plan
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A65),
                    fixedSize: const Size(110, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    "View Plan",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 4. Content Cards
            InfoCard(
              title: "About Me",
              content: mentorData['bio'] ?? "No biography provided yet.",
            ),

            ExpertiseChips(
              title: "Expertise",
              labels: getList('expertise'),
            ),

            ExpertiseChips(
              title: "Disciplines",
              labels: getList('skills'),
            ),

            ExpertiseChips(
              title: "Fluent In",
              labels: getList('languages').isNotEmpty 
                  ? getList('languages') 
                  : const ["English", "Filipino"],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}