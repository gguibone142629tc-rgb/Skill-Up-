import 'package:finaproj/app_settings/model/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:finaproj/login/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileListDecor extends StatelessWidget {
  const ProfileListDecor({super.key, required this.profileModel});
  final ProfileModel profileModel;

  @override
  Widget build(BuildContext context) {
    final bool isLogout = profileModel.title.toLowerCase().contains('log');
    final Color logoutColor = const Color(0xFFFF3B30);

    return InkWell(
      // Inside ProfileListDecor widget
// Inside ProfileListDecor -> build -> return InkWell
onTap: () async {
  if (isLogout) {
    // 1. Sign out from Firebase
    await FirebaseAuth.instance.signOut();
    
    // 2. Clear navigation and go back to LoginPage
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  } else {
    // Handle other menu items here
  }
},
      child: Container(
        margin: const EdgeInsets.only(left: 25, right: 25, top: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 1.5),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isLogout ? logoutColor.withOpacity(0.1) : const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset(
                    profileModel.iconPath,
                    color: isLogout ? logoutColor : null,
                    width: 20,
                  ),
                ),
                Text(
                  profileModel.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: isLogout ? logoutColor : Colors.black,
                  ),
                )
              ],
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: isLogout ? logoutColor : Colors.black45),
          ],
        ),
      ),
    );
  }
}