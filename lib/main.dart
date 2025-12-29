import 'package:finaproj/FindMentor/page/find_mentor_page.dart';
import 'package:finaproj/Message/page/messages_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ⚠️ Make sure these imports match your actual file paths
import 'firebase_options.dart';
import 'package:finaproj/login/pages/login_page.dart';
import 'package:finaproj/home_page/pages/home_page.dart';
import 'package:finaproj/Profile_page/pages/my_profile_page.dart';
import 'package:finaproj/Profile_page/pages/mentee_profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkillUp',
      theme: ThemeData(
        primaryColor: const Color(0xFF2D6A65),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A65)),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // 1. Listen to Auth State
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // 2. If User is Logged In
        if (authSnapshot.hasData && authSnapshot.data != null) {
          User currentUser = authSnapshot.data!;

          // 3. LISTEN (Stream) to the User Document to check for profile
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .snapshots(),
            builder: (context, docSnapshot) {
              // Waiting for database connection
              if (docSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              // 4. Check if Document Exists
              if (docSnapshot.hasData && docSnapshot.data!.exists) {
                // User has a profile -> Go Home
                return const HomePage();
              }

              // 5. User exists in Auth, but NO Profile in Database yet.
              // Check if the account is BRAND NEW (created < 30 seconds ago)
              final creationTime =
                  currentUser.metadata.creationTime ?? DateTime.now();
              final isNewUser =
                  DateTime.now().difference(creationTime).inSeconds < 30;

              if (isNewUser) {
                // ALLOW TIME: Shows a loading screen while `saveMentorProfile` finishes running
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text("Setting up your profile..."),
                      ],
                    ),
                  ),
                );
              } else {
                // OLD Ghost Account: It's been > 30 seconds and still no data.
                // Now we can safely log them out.
                Future.microtask(() => FirebaseAuth.instance.signOut());
                return const LoginPage();
              }
            },
          );
        }

        // 6. User is NOT Logged In
        return const LoginPage();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 💡 TIP: If you use this NavBar in other files, move this class to:
// lib/common/custom_bottom_nav_bar.dart to avoid "Circular Import" errors.
// ---------------------------------------------------------------------------

class CustomBottomNavBar extends StatefulWidget {
  final int initialIndex;
  const CustomBottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late int selectedIndex;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void didUpdateWidget(covariant CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      selectedIndex = widget.initialIndex;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF2D6A65);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        iconSize: 26,
        onTap: (index) {
          if (index == selectedIndex) return;

          setState(() => selectedIndex = index);

          // --- FIXED NAVIGATION LOGIC ---
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
            case 3:
              nextPage = const _RoleProfileEntry(startEditing: false);
              break;
            default:
              return;
          }

          // Navigate without animation for instant response
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, anim1, anim2) => nextPage,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
        items: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.search,
            activeIcon: Icons.search,
            label: 'Search',
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.message_outlined,
            activeIcon: Icons.message,
            label: 'Messages',
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;

    return BottomNavigationBarItem(
      icon: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Icon(icon),
      ),
      activeIcon: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2D6A65).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(activeIcon),
        ),
      ),
      label: label,
    );
  }
}

// Small helper page that routes to the correct profile edit screen based on role
class _RoleProfileEntry extends StatelessWidget {
  final bool startEditing;
  const _RoleProfileEntry({required this.startEditing});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Profile not found')),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final role = (data['role'] ?? 'student').toString().toLowerCase();

        if (role == 'mentor') {
          return MyProfilePage(startEditing: startEditing);
        }
        return MenteeProfilePage(startEditing: startEditing);
      },
    );
  }
}
