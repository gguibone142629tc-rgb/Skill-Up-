// lib/Message/messages_decor/messages_list_decor.dart

import 'package:flutter/material.dart';
import '../model/messages_model.dart';
import '../page/chat_room_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagesListDecor extends StatelessWidget {
  final MessagesModel messagesModel;

  const MessagesListDecor({super.key, required this.messagesModel});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              chatRoomId: messagesModel.chatRoomId,
              otherUserName: messagesModel.name,
              currentUserId: FirebaseAuth.instance.currentUser!.uid,
              otherUserProfileImage: messagesModel.profilePath,
            ),
          ),
        );
      },
      leading: CircleAvatar(
        radius: 26,
        backgroundImage: messagesModel.profilePath.isNotEmpty
            ? NetworkImage(messagesModel.profilePath)
            : null,
        backgroundColor: Colors.grey[200],
        child: messagesModel.profilePath.isEmpty
            ? ClipOval(
                child: Image.asset(
                  'assets/images/default_avatar.png',
                  height: 52,
                  width: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.grey),
                ),
              )
            : null,
      ),
      title: Text(
        messagesModel.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600, // Semi-bold like your image
          color: Colors.black,
        ),
      ),
      subtitle: Text(
  messagesModel.message,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    fontSize: 14,
    color: Colors.grey.shade600, // Matches the grey in your reference image
    fontWeight: FontWeight.w400,
  ),
),
      trailing: Text(
        messagesModel.time,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}