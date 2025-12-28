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
import 'package:finaproj/app_settings/page/profile_page.dart';

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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // 4. Check if Document Exists
              if (docSnapshot.hasData && docSnapshot.data!.exists) {
                 // User has a profile -> Go Home
                return const HomePage();
              }
              
              // 5. User exists in Auth, but NO Profile in Database yet.
              // Check if the account is BRAND NEW (created < 30 seconds ago)
              final creationTime = currentUser.metadata.creationTime ?? DateTime.now();
              final isNewUser = DateTime.now().difference(creationTime).inSeconds < 30;

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

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF2D6A65);

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: accentColor,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      onTap: (index) {
        if (index == selectedIndex) return;
        
        // --- FIXED NAVIGATION LOGIC ---
        Widget nextPage;
        switch (index) {
          case 0:
            nextPage = const HomePage();
            break;
          case 1:
            nextPage = const FindMentorPage(); // Now connected!
            break;
          case 2:
            nextPage = const MessagesPage();   // Now connected!
            break;
          case 3:
            nextPage = const ProfilePage();
            break;
          default:
            return;
        }

        // Navigate without animation for a "Tab" feel
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
          label: 'Home'
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search), 
          activeIcon: Icon(Icons.search, weight: 600), // Thicker when active
          label: 'Search'
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message_outlined), 
          activeIcon: Icon(Icons.message), 
          label: 'Messages'
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline), 
          activeIcon: Icon(Icons.person), 
          label: 'Profile'
        ),
      ],
    );
  }
}