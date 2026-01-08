import 'package:finaproj/app_settings/model/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- IMPORTS FOR NAVIGATION ---
import 'package:finaproj/login/pages/login_page.dart';
import 'package:finaproj/app_settings/page/edit_profile_page.dart'; // Personal Details
import 'package:finaproj/SessionHistory/pages/session_history_screen.dart'; // My Mentorship
import 'package:finaproj/SavedMentors/saved_mentors_page.dart'; // Saved Mentors
import 'package:finaproj/app_settings/page/my_subscribers_page.dart'; // My Subscribers
import 'package:finaproj/app_settings/page/change_password_page.dart'; // Change Password
import 'package:finaproj/app_settings/page/privacy_policy_page.dart'; // Privacy Policy
import 'package:finaproj/mentor_dashboard/pages/mentor_dashboard_page.dart';

class ProfileListDecor extends StatelessWidget {
  const ProfileListDecor({super.key, required this.profileModel});
  final ProfileModel profileModel;

  @override
  Widget build(BuildContext context) {
    final bool isLogout = profileModel.title.toLowerCase().contains('log');
    final Color brandGreen = const Color(0xFF2D6A65);
    final Color logoutColor = const Color(0xFFFF3B30);
    final Color iconBg = isLogout 
        ? logoutColor.withOpacity(0.1) 
        : brandGreen.withOpacity(0.08);
    final Color iconColor = isLogout ? logoutColor : brandGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (isLogout) {
            // --- LOGOUT LOGIC ---
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            }
          } else {
            // --- NAVIGATION LOGIC ---
            Widget? nextPage;

            switch (profileModel.title) {
              case 'Personal Details':
                nextPage = const EditProfilePage();
                break;
              case 'My Subscription':
                nextPage = const MySubscriptionPage();
                break;
              case 'My Subscribers':
                nextPage = const MySubscribersPage();
                break;
              case 'Dashboard':
                nextPage = const MentorDashboardPage();
                break;
              case 'Saved Mentors':
                nextPage = const SavedMentorsPage();
                break;
              case 'Change Password':
                nextPage = const ChangePasswordPage();
                break;
              case 'Privacy Policy':
                nextPage = const PrivacyPolicyPage();
                break;
              default:
                // Handle unknown cases or show a "Coming Soon" snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${profileModel.title} coming soon!')),
                );
            }

            if (nextPage != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => nextPage!),
              );
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          profileModel.iconPath,
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      profileModel.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isLogout ? logoutColor : Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    )
                  ],
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, 
                    color: isLogout ? logoutColor : Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
