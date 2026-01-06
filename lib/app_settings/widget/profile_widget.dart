import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finaproj/app_settings/decor/profile_list_decor.dart';
import 'package:finaproj/app_settings/model/profile_model.dart';
import 'package:flutter/material.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  bool isMentor = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            isMentor = userDoc.data()?['role'] == 'mentor';
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<ProfileModel> _getMenuItems() {
    List<ProfileModel> items = [
      ProfileModel(
          iconPath: 'assets/icons/person.svg', title: 'Personal Details'),
      ProfileModel(
          iconPath: 'assets/icons/lock.svg', title: 'Change Password'),
    ];

    // Add "My Subscription" for students only
    if (!isMentor) {
      items.add(ProfileModel(
          iconPath: 'assets/icons/history.svg', title: 'My Subscription'));
    }

    // Add "My Subscribers" for mentors only
    if (isMentor) {
      items.add(ProfileModel(
          iconPath: 'assets/icons/favorite.svg', title: 'My Subscribers'));
    }

    // Add "Saved Mentors" for students only
    if (!isMentor) {
      items.add(ProfileModel(
          iconPath: 'assets/icons/favorite.svg', title: 'Saved Mentors'));
    }

    // Privacy Policy available to all users
    items.add(ProfileModel(iconPath: 'assets/icons/note.svg', title: 'Privacy Policy'));

    items.add(ProfileModel(iconPath: 'assets/icons/logout.svg', title: 'Log Out'));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final listInfo = _getMenuItems();

    return ListView.builder(
      shrinkWrap: true, // Crucial!
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listInfo.length,
      itemBuilder: (context, index) {
        return ProfileListDecor(profileModel: listInfo[index]);
      },
    );
  }
}
