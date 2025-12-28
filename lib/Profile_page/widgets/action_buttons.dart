import 'package:finaproj/Message/page/chat_room_page.dart';
import 'package:finaproj/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final Map<String, dynamic> mentorData;

  const ActionButtons({super.key, required this.mentorData});

  void _handleMessage(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final String mentorId = mentorData['uid'] ?? '';
    final String mentorName = "${mentorData['firstName'] ?? 'Mentor'}";
    // Get the profile image from mentorData to pass it to the chat room
    final String? profileImg = mentorData['profileImageUrl']; 

    try {
      final db = DatabaseService();
      
      // CHANGE THIS LINE: from getOrCreateChatRoom to getChatRoomId
      String roomId = await db.getChatRoomId(currentUser.uid, mentorId);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              chatRoomId: roomId,
              otherUserName: mentorName,
              currentUserId: currentUser.uid,
              otherUserProfileImage: profileImg, // Pass the image here!
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Left Button: Message (Dark Teal)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleMessage(context),
              icon: const Icon(Icons.send, size: 18, color: Colors.white),
              label: const Text(
                "Message",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF356966), // Dark Teal
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(), // Perfect pill shape
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Right Button: Save Mentor (Light Grey)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // You can add your save logic here now!
              },
              icon: const Icon(Icons.bookmark_border, size: 20, color: Colors.black),
              label: const Text(
                "Save Mentor",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F5F5), // Light Grey
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(), // Perfect pill shape
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}