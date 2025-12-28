import 'package:cloud_firestore/cloud_firestore.dart'; // Add this
import 'package:finaproj/home_page/model/mentor_model.dart';
import 'package:flutter/material.dart';
import 'mentor_card.dart';

class TopMentorsSection extends StatelessWidget {
  const TopMentorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text(
            'Top Mentors',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        
        // STREAMBUILDER: Pulls data from your "users" collection
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'mentor') // Only show mentors
              .limit(5) // Just show the top 5 on the home page
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No mentors found yet."),
              );
            }

            // Convert Firestore documents into your Mentor model
            final mentors = snapshot.data!.docs.map((doc) {
              return Mentor.fromFirestore(
                doc.data() as Map<String, dynamic>, 
                doc.id
              );
            }).toList();

            return ListView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: mentors.length,
              itemBuilder: (context, index) {
                return MentorCard(mentor: mentors[index]);
              },
            );
          },
        ),
      ],
    );
  }
}