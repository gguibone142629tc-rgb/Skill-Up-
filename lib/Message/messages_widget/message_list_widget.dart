// lib/Message/messages_widget/message_list_widget.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finaproj/services/database_service.dart';
import '../messages_decor/messages_list_decor.dart';
import '../model/messages_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageListWidget extends StatelessWidget {
  MessageListWidget({super.key});

  final DatabaseService _db = DatabaseService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    if (currentUserId.isEmpty) return const Center(child: Text("Please login"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('users', arrayContains: currentUserId)
          .orderBy('lastTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(
                color: Color(0xFF2D6A65),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Conversations Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation with a mentor',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var chatDoc = snapshot.data!.docs[index];
            var chatData = chatDoc.data() as Map<String, dynamic>;

            List users = chatData['users'] ?? [];
            String otherUserId =
                users.firstWhere((id) => id != currentUserId, orElse: () => "");

            return FutureBuilder<Map<String, dynamic>?>(
              future: _db.getUserData(otherUserId),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox.shrink();

                final userData = userSnap.data!;
                String lastMsg = chatData['lastMessage'] ?? "";
                String lastSenderId = chatData['lastSenderId'] ?? "";

                // ADD "YOU: " PREFIX LOGIC
                if (lastMsg.isNotEmpty && lastSenderId == currentUserId) {
                  lastMsg = "You: $lastMsg";
                }

                if (lastMsg.isEmpty) lastMsg = "No messages yet...";

                return MessagesListDecor(
                  messagesModel: MessagesModel(
                    profilePath: userData['profileImageUrl'] ?? '',
                    name: userData['fullName'] ?? 'User',
                    message: lastMsg,
                    time: _formatTime(chatData['lastTimestamp']),
                    chatRoomId: chatDoc.id,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return "";
    return DateFormat.jm().format(timestamp.toDate());
  }
}
