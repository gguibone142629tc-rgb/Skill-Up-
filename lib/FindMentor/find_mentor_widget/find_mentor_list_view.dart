import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:finaproj/FindMentor/find_mentor_decor/find_mentor_list.dart';
import 'package:finaproj/home_page/model/mentor_model.dart'; 

class FindMentorListView extends StatelessWidget {
  // Add this variable to receive the search text
  final String searchQuery;

  const FindMentorListView({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'mentor') 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 50),
              child: Text("No mentors found.", style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        // 1. Convert to List
        final mentors = snapshot.data!.docs.map((doc) {
          return Mentor.fromFirestore(
            doc.data() as Map<String, dynamic>, 
            doc.id
          );
        }).toList();

        // 2. FILTER LOGIC based on Search Query
        final filteredMentors = mentors.where((mentor) {
          final query = searchQuery.toLowerCase();
          final name = mentor.name.toLowerCase();
          final job = mentor.jobTitle.toLowerCase();
          
          return name.contains(query) || job.contains(query);
        }).toList();

        if (filteredMentors.isEmpty) {
           return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 50),
              child: Text("No matches found.", style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        // 3. Display Filtered List
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredMentors.length,
          itemBuilder: (context, index) {
            return FindMentorList(mentor: filteredMentors[index]);
          },
        );
      },
    );
  }
}