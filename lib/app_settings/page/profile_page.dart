import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finaproj/app_settings/page/edit_profile_page.dart';
import 'package:finaproj/SavedMentors/saved_mentors_page.dart';
// ⚠️ Check these imports match your folder structure
import 'package:finaproj/login/pages/login_page.dart';
import 'package:finaproj/home_page/pages/home_page.dart';
import 'package:finaproj/FindMentor/page/find_mentor_page.dart';
import 'package:finaproj/Message/page/messages_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- LOGOUT LOGIC ---
  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging out: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Defines the "Teal" look from your other pages
    const primaryColor = Color(0xFF2D6A65);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. BIG HEADER ---
              const SizedBox(height: 10),
              const Text(
                "Profile",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),

              // --- 2. MENU OPTIONS ---
              // Each item matches the specific UI of your screenshot

              _buildMenuOption(
                icon: Icons.person_outline,
                label: "Personal Details",
                onTap: () {
                  // Navigate to the new Edit Profile Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EditProfilePage()),
                  ).then((_) {
                    // Optional: Refresh state when coming back if needed
                    setState(() {});
                  });
                },
              ),

              _buildMenuOption(
                icon: Icons.history, // Clock/History icon
                label: "Session History",
                onTap: () {},
              ),

              _buildMenuOption(
                icon: Icons.favorite_border, // Heart icon
                label: "Saved Mentors",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedMentorsPage(),
                    ),
                  );
                },
              ),

              _buildMenuOption(
                icon: Icons.settings_outlined, // Gear icon
                label: "Settings",
                onTap: () {},
              ),

              _buildMenuOption(
                icon: Icons.lock_outline, // Lock icon
                label: "Privacy & Security",
                onTap: () {},
              ),

              const SizedBox(height: 10), // Extra spacing before logout

              // --- 3. LOGOUT BUTTON (Red Style) ---
              _buildMenuOption(
                icon: Icons.logout, // Exit icon
                label: "Log Out",
                isDestructive: true, // Triggers red styling
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Log Out"),
                      content: const Text("Are you sure you want to log out?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _handleLogout();
                          },
                          child: const Text("Log Out",
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Profile Tab
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0, // Flat look like screenshot
        onTap: (index) {
          if (index == 3) return; // Already on Profile

          Widget nextPage;
          switch (index) {
            case 0:
              nextPage = const HomePage();
              break;
            case 1:
              nextPage = const FindMentorPage();
              break;
            case 2:
              nextPage = const MessagesPage();
              break;
            default:
              return;
          }

          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, anim1, anim2) => nextPage,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              activeIcon: Icon(Icons.message),
              label: 'Message'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }

  // --- HELPER WIDGET FOR THE MENU ITEMS ---
  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0), // Spacing between items
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // 1. The Square Icon Container
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                // If destructive (Logout), use light red, else use light grey
                color: isDestructive
                    ? const Color(0xFFFFE5E5) // Light Red
                    : const Color(0xFFF5F6F9), // Light Grey
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : Colors.black87,
                size: 24,
              ),
            ),

            const SizedBox(width: 20),

            // 2. The Text Label
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // Semi-bold like screenshot
                  color: isDestructive ? Colors.red : Colors.black87,
                ),
              ),
            ),

            // 3. The Arrow Icon (Only show if NOT destructive, usually logout doesn't have an arrow)
            // But if you want the arrow on logout too, remove the condition.
            // Based on screenshot, Logout HAS an arrow.
            Icon(
              Icons.chevron_right,
              color: isDestructive ? Colors.red : Colors.black54,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
