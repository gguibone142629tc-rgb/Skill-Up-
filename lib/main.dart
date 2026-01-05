import 'package:finaproj/FindMentor/page/find_mentor_page.dart';
import 'package:finaproj/Message/page/messages_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- IMPORTS ---
import 'firebase_options.dart';
import 'package:finaproj/login/pages/login_page.dart';
import 'package:finaproj/home_page/pages/home_page.dart';
import 'services/fresh_start.dart';
import 'package:finaproj/app_settings/page/profile_page.dart'; // 1. IMPORT THIS
import 'package:finaproj/Service_Category/category_page/category.dart'; // Category page
import 'package:finaproj/services/cleanup_duplicates.dart'; // Cleanup script

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // UNCOMMENT TO DELETE ALL SUBSCRIPTIONS AND RATINGS (fresh start)
  // await freshStart();
  
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
      routes: {
        '/service_category': (context) => const Category(),
      },
      // Check if user is logged in
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const HomePage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}

// --- CUSTOM BOTTOM NAVIGATION BAR ---
class CustomBottomNavBar extends StatelessWidget {
  final int initialIndex;
  const CustomBottomNavBar({super.key, required this.initialIndex});

  void _onItemTapped(BuildContext context, int index) {
    // Avoid reloading the same page
    if (index == initialIndex) return;

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
        // 2. NAVIGATE TO PROFILE MENU
        nextPage = const ProfilePage(); 
        break;
      default:
        return;
    }

    // Navigate without animation for a "tab" feel
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => nextPage,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2D6A65);
    const inactiveColor = Colors.grey;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: initialIndex,
      onTap: (index) => _onItemTapped(context, index),
      selectedItemColor: activeColor,
      unselectedItemColor: inactiveColor,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          activeIcon: Icon(Icons.search, weight: 600),
          label: 'Find Mentor',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile', // 3. ENSURE LABEL IS CORRECT
        ),
      ],
    );
  }
}