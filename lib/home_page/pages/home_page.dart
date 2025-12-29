// Location: home_page/pages/home_page.dart

import 'package:finaproj/home_page/widgets/categories_section.dart';
import 'package:finaproj/home_page/widgets/custom_app_bar.dart';
import 'package:finaproj/home_page/widgets/top_mentors_section.dart';
import 'package:finaproj/main.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        // The fix: Add bottom: false so the scroll view can go behind the nav bar
        // if needed, or wrap the Column in a Container with bottom padding.
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const CustomAppBar(),
              const CategoriesSection(),
              const TopMentorsSection(),
              // Add a small spacer at the bottom so the last card isn't
              // cut off by the navigation bar
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(initialIndex: 0),
    );
  }
}
