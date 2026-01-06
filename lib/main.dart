import 'package:finaproj/FindMentor/page/find_mentor_page.dart';
import 'package:finaproj/Message/page/messages_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- IMPORTS ---
import 'firebase_options.dart';
import 'package:finaproj/login/pages/login_page.dart';
import 'package:finaproj/home_page/pages/home_page.dart';
import 'package:finaproj/app_settings/page/profile_page.dart'; // 1. IMPORT THIS
import 'package:finaproj/Service_Category/category_page/category.dart'; // Category page
// Cleanup script
import 'package:finaproj/services/notification_service.dart';
import 'package:finaproj/services/unread_messages_service.dart';
import 'package:finaproj/services/subscription_service.dart';
import 'package:finaproj/services/subscription_expiry_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // UNCOMMENT TO DELETE ALL SUBSCRIPTIONS AND RATINGS (fresh start)
  // await freshStart();
  
  // Initialize notifications
  await NotificationService().initializeNotifications();
  
  // Check for expired subscriptions on app start (run async without blocking)
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      // Run in background without blocking UI
      Future.delayed(const Duration(milliseconds: 500), () {
        SubscriptionService().checkAllSubscriptionsForExpiration();
        SubscriptionExpiryChecker().checkSubscriptionsForExpiration();
      });
    }
  });
  
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
class CustomBottomNavBar extends StatefulWidget {
  final int initialIndex;
  const CustomBottomNavBar({super.key, required this.initialIndex});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  void _onItemTapped(BuildContext context, int index) {
    // Avoid reloading the same page
    if (index == widget.initialIndex) return;

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
      currentIndex: widget.initialIndex,
      onTap: (index) => _onItemTapped(context, index),
      selectedItemColor: activeColor,
      unselectedItemColor: inactiveColor,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          activeIcon: Icon(Icons.search, weight: 600),
          label: 'Find Mentor',
        ),
        BottomNavigationBarItem(
          icon: _buildMessagesIconWithBadge(widget.initialIndex == 2),
          activeIcon: _buildMessagesIconWithBadge(true),
          label: 'Messages',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile', // 3. ENSURE LABEL IS CORRECT
        ),
      ],
    );
  }

  Widget _buildMessagesIconWithBadge(bool isActive) {
    return StreamBuilder<int>(
      stream: UnreadMessagesService().getUnreadMessagesCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return Stack(
          children: [
            Icon(
              isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}