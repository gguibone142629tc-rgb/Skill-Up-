import 'package:finaproj/Profile_page/widgets/action_buttons.dart';
import 'package:finaproj/Profile_page/pages/my_profile_page.dart';
import 'package:finaproj/common/mentor_avatar.dart';
import 'package:finaproj/membershipPlan/pages/membership_page.dart';
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
        DocumentSnapshot doc =
            await _db.collection('users').doc(currentUserId).get();
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
    final List<String> expertise =
        List<String>.from(_displayData['expertise'] ?? []);
    final String bio = _displayData['bio'] ?? 'No bio provided.';
    final String fullName =
        '${_displayData['firstName'] ?? ''} ${_displayData['lastName'] ?? ''}'
            .trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child:
                            const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Text(
                        'Mentor Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isOwnProfile)
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MyProfilePage(startEditing: true),
                              ),
                            );
                            _loadFreshDataIfOwnProfile();
                          },
                          child: const Icon(Icons.edit, color: Colors.white),
                        )
                      else
                        const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Logo/Icon placeholder
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '👨‍🏫',
                      style: TextStyle(fontSize: 32),
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
                          MentorAvatar(
                            name: fullName,
                            image: _displayData['profileImageUrl'] ?? '',
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayData['jobTitle'] ?? 'Mentor',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayData['location'] ?? 'Remote',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Action Buttons (Message and Save)
                          if (!isOwnProfile)
                            ActionButtons(mentorData: _displayData)
                          else
                            const SizedBox.shrink(),
                          const SizedBox(height: 12),
                          // Plan Management Button
                          SizedBox(
                            width: double.infinity,
                            child: isOwnProfile
                                ? ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MembershipPage(
                                            isMentorView: true,
                                            mentorData: _displayData,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2D6A65),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      'Manage Plans',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MembershipPage(
                                            isMentorView: false,
                                            mentorData: _displayData,
                                          ),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFF2D6A65),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      'View Plans & Subscribe',
                                      style: TextStyle(
                                        color: Color(0xFF2D6A65),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // About Section
                    _buildSection(
                      title: 'About',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          bio,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[800]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Expertise Section
                    _buildSection(
                      title: 'Expertise',
                      child: expertise.isEmpty
                          ? Text(
                              'No expertise listed',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: expertise.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(
                                    item,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Skills Section
                    _buildSection(
                      title: 'Skills & Tools',
                      child: skills.isEmpty
                          ? Text(
                              'No skills listed',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: skills.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(
                                    item,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSectionIcon(title),
                size: 20,
                color: const Color(0xFF2D6A65),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Expertise':
        return Icons.school_outlined;
      case 'Skills & Tools':
        return Icons.build_outlined;
      case 'About':
        return Icons.info_outline;
      default:
        return Icons.info_outline;
    }
  }
}
