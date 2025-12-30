import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../widgets/session_card.dart';

class SessionHistoryPage extends StatelessWidget {
  const SessionHistoryPage({super.key}); // Added const

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Session History",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch sessions where the current user is a participant
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .where('participants', arrayContains: currentUserId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No session history yet.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              
              // Map Firestore data to your Session model
              // NOTE: You might need to adjust fields based on your actual DB structure
              final imageUrl = (data['mentorProfileImageUrl'] ?? data['mentorImage'] ?? data['profileImageUrl'] ?? '') as String;
              final session = Session(
                name: data['mentorName'] ?? 'Mentor', 
                role: data['role'] ?? 'Mentor',
                date: data['date'] ?? '',
                time: data['time'] ?? '',
                imagePath: imageUrl,
                status: _getStatus(data['status']),
              );

              return SessionCard(session: session);
            },
          );
        },
      ),
    );
  }

  // Helper to convert string status to Enum
  SessionStatus _getStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed': return SessionStatus.completed;
      case 'cancelled': return SessionStatus.cancelled;
      default: return SessionStatus.upcoming;
    }
  }
}