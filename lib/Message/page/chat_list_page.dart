import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_room_page.dart'; // Ensure this matches your filename

class ChatListPage extends StatelessWidget {
  final String currentUserId;

  const ChatListPage({super.key, required this.currentUserId});

@override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF356966);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text("Messages", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query chat rooms where current user is a participant
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('users', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: brandGreen));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No conversations yet.", style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var chatData = doc.data() as Map<String, dynamic>;
              String roomId = doc.id;

              // Extracting the other user's name from displayNames array
              List names = chatData['displayNames'] ?? [];
              String otherName = names.firstWhere((name) => name != "YourName", orElse: () => "User");

              return ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: brandGreen.withOpacity(0.1),
                  child: Text(otherName[0].toUpperCase(), 
                    style: const TextStyle(color: brandGreen, fontWeight: FontWeight.bold)),
                ),
                title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  chatData['lastMessage'] ?? "Tap to chat",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomPage(
                        chatRoomId: roomId,
                        otherUserName: otherName,
                        currentUserId: currentUserId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}