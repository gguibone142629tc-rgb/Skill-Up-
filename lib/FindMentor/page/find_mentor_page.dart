import 'package:flutter/material.dart';

// Imports
import 'package:finaproj/FindMentor/find_mentor_widget/find_mentor_list_view.dart';
import 'package:finaproj/FindMentor/find_mentor_widget/find_mentor_search_widget.dart';
import 'package:finaproj/main.dart'; // For CustomBottomNavBar

class FindMentorPage extends StatefulWidget {
  const FindMentorPage({super.key});

  @override
  State<FindMentorPage> createState() => _FindMentorPageState();
}

class _FindMentorPageState extends State<FindMentorPage> {
  // This variable holds the text you type
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text(
              'Find a Mentor', 
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)
            ),
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
          ),
          
          // 1. Search Widget (Passes text UP to this page)
          SliverToBoxAdapter(
            child: FindMentorSearchWidget(
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value; // Update state when user types
                });
              },
            ),
          ),

          // 2. List Widget (Receives text DOWN to filter results)
          SliverToBoxAdapter(
            child: FindMentorListView(
              searchQuery: _searchQuery, 
            ),
          ),
          
          // Bottom spacer
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(initialIndex: 1), 
    );
  }
}