import 'package:finaproj/Profile_page/widgets/action_buttons.dart';
import 'package:finaproj/Profile_page/widgets/expertise_chips.dart';
import 'package:finaproj/Profile_page/widgets/profile_header.dart';
import 'package:finaproj/Profile_page/decor/info_card_decor.dart';
import 'package:finaproj/Profile_page/pages/my_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const ProfileScreen({super.key, required this.mentorData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _displayData;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _displayData = widget.mentorData;
    _loadFreshDataIfOwnProfile();
    // Also attempt to load fuller data for other users when a uid is provided
    _loadProfileFromUidIfNeeded();
  }

  /// If a uid is provided in the incoming mentorData, fetch the full user document
  /// and merge it with the provided data so fields like `bio` and `expertise` are available
  Future<void> _loadProfileFromUidIfNeeded() async {
    final String? uid = widget.mentorData['uid'] as String?;
    if (uid == null) return;

    // Skip if we already have meaningful bio/expertise data
    final hasBio = (_displayData['bio'] ?? '').toString().trim().isNotEmpty;
    final hasExpertise = (_displayData['expertise'] ?? []).isNotEmpty;
    if (hasBio && hasExpertise) return;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            // Merge incoming data with the fresh document data
            _displayData = {..._displayData, ...data};
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile for uid $uid: $e");
    }
  }

  Future<void> _loadFreshDataIfOwnProfile() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = widget.mentorData['uid'] == currentUserId;

    if (isOwnProfile && currentUserId != null) {
      try {
        DocumentSnapshot doc = await _db.collection('users').doc(currentUserId).get();
        if (doc.exists) {
          if (mounted) {
            setState(() {
              _displayData = doc.data() as Map<String, dynamic>;
            });
          }
        }
      } catch (e) {
        debugPrint("Error loading fresh profile data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // Check if looking at own profile
    final bool isOwnProfile = _displayData['uid'] == currentUserId; 
    
    // ✅ Extract Lists Safely
    final List<String> skills = List<String>.from(_displayData['skills'] ?? []);
    final List<String> expertise = List<String>.from(_displayData['expertise'] ?? []);
    final String bio = _displayData['bio'] ?? 'No bio provided.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyProfilePage(startEditing: true),
                  ),
                );
                _loadFreshDataIfOwnProfile();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            ProfileHeader(mentorData: _displayData),

            // Action Buttons (Only if not your own profile)
            if (!isOwnProfile)
              ActionButtons(mentorData: _displayData),
            
            const SizedBox(height: 20),

            // Bio
            InfoCard(title: "About", content: bio),
            
            // ✅ Expertise Chips
            ExpertiseChips(title: "Expertise", labels: expertise),

            // ✅ Skills Chips
            ExpertiseChips(title: "Skills & Tools", labels: skills),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}