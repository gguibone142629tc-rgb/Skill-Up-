import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finaproj/home_page/model/mentor_model.dart';
import 'package:finaproj/home_page/widgets/mentor_card.dart';
import 'package:finaproj/services/database_service.dart';
import 'package:flutter/material.dart';

class SavedMentorsPage extends StatelessWidget {
  const SavedMentorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final DatabaseService dbService = DatabaseService();

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved Mentors'),
          backgroundColor: const Color(0xFF4A8B85),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view saved mentors'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Saved Mentors',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4A8B85),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dbService.getSavedMentors(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved mentors yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start saving mentors to view them here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // Get list of saved mentor IDs
          final savedMentorIds = snapshot.data!.docs
              .map((doc) => doc['mentorId'] as String)
              .toList();

          return FutureBuilder<List<Mentor>>(
            future: _fetchMentorDetails(savedMentorIds),
            builder: (context, mentorSnapshot) {
              if (mentorSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!mentorSnapshot.hasData || mentorSnapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No mentor details found'),
                );
              }

              final mentors = mentorSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: mentors.length,
                itemBuilder: (context, index) {
                  return MentorCard(mentor: mentors[index]);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Mentor>> _fetchMentorDetails(List<String> mentorIds) async {
    List<Mentor> mentors = [];

    for (String mentorId in mentorIds) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(mentorId)
            .get();

        if (doc.exists) {
          final mentor = Mentor.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
          mentors.add(mentor);
        }
      } catch (e) {
        debugPrint('Error fetching mentor $mentorId: $e');
      }
    }

    return mentors;
  }
}
