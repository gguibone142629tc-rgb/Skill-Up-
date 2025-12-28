import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../widgets/session_card.dart';

class SessionHistoryPage extends StatelessWidget {
  SessionHistoryPage({super.key});

  final List<Session> sessions = [
    Session(
      name: "Priya Patel",
      role: "Data Scientist",
      date: "Today",
      time: "2:00 PM",
      imagePath: "assets/images/Ellipse 2057.png", // Matches your file exactly
      status: SessionStatus.upcoming,
    ),
    Session(
      name: "David Chen",
      role: "Product Design Lead",
      date: "Today",
      time: "2:00 PM",
      imagePath: "assets/images/Ellipse 2057.png", 
      status: SessionStatus.completed,
    ),
    Session(
      name: "Sarah Miller",
      role: "Senior Software Engineer",
      date: "Today",
      time: "2:00 PM",
      imagePath: "assets/images/Ellipse 2057.png", 
      status: SessionStatus.cancelled,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text("Session History", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sessions.length,
        itemBuilder: (context, index) => SessionCard(session: sessions[index]),
      ),
    );
  }
}