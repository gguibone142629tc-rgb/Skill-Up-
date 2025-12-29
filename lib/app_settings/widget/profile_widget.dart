import 'package:finaproj/app_settings/decor/profile_list_decor.dart';
import 'package:finaproj/app_settings/model/profile_model.dart';
import 'package:flutter/material.dart';

class ProfileWidget extends StatelessWidget {
  ProfileWidget({super.key});

  final List<ProfileModel> listInfo = [
    ProfileModel(
        iconPath: 'assets/icons/person.svg', title: 'Personal Details'),
    ProfileModel(
        iconPath: 'assets/icons/history.svg', title: 'Session History'),
    ProfileModel(iconPath: 'assets/icons/favorite.svg', title: 'Saved Members'),
    ProfileModel(iconPath: 'assets/icons/logout.svg', title: 'Log Out'),
  ];

  @override
  Widget build(BuildContext context) {
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
