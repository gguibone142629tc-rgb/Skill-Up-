// Location: home_page/pages/home_page.dart

import 'package:finaproj/common/responsive_layout.dart';
import 'package:finaproj/home_page/widgets/branding_banner.dart';
import 'package:finaproj/home_page/widgets/categories_section.dart';
import 'package:finaproj/home_page/widgets/custom_app_bar.dart';
import 'package:finaproj/home_page/widgets/top_mentors_section.dart';
import 'package:finaproj/main.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey topMentorsKey = GlobalKey();

  void scrollToTopMentors() {
    final context = topMentorsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = ResponsiveLayout.verticalSpacing(
      context,
      mobile: 80,
      tablet: 96,
      desktop: 120,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const CustomAppBar(),
              ResponsiveLayout.constrain(
                context: context,
                child: Column(
                  children: [
                    BrandingBanner(onTopRatedTap: scrollToTopMentors),
                    const CategoriesSection(),
                    TopMentorsSection(key: topMentorsKey),
                    SizedBox(height: bottomPadding),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(initialIndex: 0),
    );
  }
}
