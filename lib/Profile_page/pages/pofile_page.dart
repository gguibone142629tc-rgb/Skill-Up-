import 'package:finaproj/Profile_page/widgets/action_buttons.dart';
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
  bool _isLoading = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _displayData = widget.mentorData;
    _loadFreshDataIfOwnProfile();
  }

  Future<void> _loadFreshDataIfOwnProfile() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = widget.mentorData['uid'] == currentUserId;

    if (isOwnProfile) {
      try {
        setState(() => _isLoading = true);
        final doc = await _db.collection('users').doc(currentUserId).get();
        if (doc.exists && mounted) {
          setState(() {
            _displayData = doc.data() as Map<String, dynamic>;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Helper to safely get lists
    List<String> getList(String key1, [String? key2]) {
      var list = _displayData[key1] ?? (key2 != null ? _displayData[key2] : []);
      if (list is List) return List<String>.from(list);
      return [];
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
            // 1. Profile Info Card
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Image
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        (_displayData['profileImageUrl'] ?? '').isNotEmpty
                            ? NetworkImage(_displayData['profileImageUrl'])
                            : null,
                    child: (_displayData['profileImageUrl'] ?? '').isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    _displayData['fullName'] ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Job Title
                  Text(
                    _displayData['jobTitle'] ?? 'Mentor',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Location
                  Text(
                    _displayData['location'] ?? 'Location',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Action Buttons or Edit Button
            _buildActionSection(context, _displayData),

            const SizedBox(height: 20),

            // 3. "View Plan" Button (only for other mentors)
            if (_displayData['uid'] != FirebaseAuth.instance.currentUser?.uid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to Plan
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A65),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "View Plan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 4. Content Cards with better styling
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // About Me
                  _buildInfoSection(
                    title: "About Me",
                    icon: Icons.info_outline,
                    content:
                        _displayData['bio'] ?? "No biography provided yet.",
                  ),
                  const SizedBox(height: 20),

                  // Expertise
                  _buildChipsSection(
                    title: "Expertise",
                    icon: Icons.star_outline,
                    labels: getList('expertise'),
                    emptyMessage: "No expertise added yet",
                  ),
                  const SizedBox(height: 20),

                  // Disciplines
                  _buildChipsSection(
                    title: "Disciplines",
                    icon: Icons.school_outlined,
                    labels: getList('skills'),
                    emptyMessage: "No disciplines added yet",
                  ),
                  const SizedBox(height: 20),

                  // Fluent In
                  _buildChipsSection(
                    title: "Fluent In",
                    icon: Icons.language,
                    labels: getList('languages').isNotEmpty
                        ? getList('languages')
                        : const ["English", "Filipino"],
                    isLanguage: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper method to build action section
  Widget _buildActionSection(
      BuildContext context, Map<String, dynamic> mentorData) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = mentorData['uid'] == currentUserId;

    if (isOwnProfile) {
      // Show Edit button for own profile with improved styling
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const MyProfilePage(startEditing: true)),
            ).then((_) {
              // Refresh data when returning from edit page
              _loadFreshDataIfOwnProfile();
            });
          },
          icon: const Icon(Icons.edit, size: 20),
          label: const Text(
            'Edit Profile',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D6A65),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    } else {
      // Show action buttons for other mentors
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: ActionButtons(mentorData: mentorData),
      );
    }
  }

  // Build info section with better styling
  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF2D6A65), size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color:
                  content.contains('No ') ? Colors.grey[500] : Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // Build chips section with better styling
  Widget _buildChipsSection({
    required String title,
    required IconData icon,
    required List<String> labels,
    String emptyMessage = "No information provided",
    bool isLanguage = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF2D6A65), size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (labels.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: labels
                .map((label) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLanguage
                            ? Colors.blue[50]
                            : const Color(0xFF2D6A65).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isLanguage
                              ? Colors.blue[200]!
                              : const Color(0xFF2D6A65).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isLanguage
                              ? Colors.blue[700]
                              : const Color(0xFF2D6A65),
                        ),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }
}
