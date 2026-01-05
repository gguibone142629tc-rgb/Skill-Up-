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
                  'images/default_avatar.png',
                  height: 52,
                  width: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.grey),
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              messagesModel.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: messagesModel.isUnread ? FontWeight.w700 : FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          // New message indicator (blue dot for unread messages from others)
          if (messagesModel.isUnread && !messagesModel.isFromCurrentUser)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              margin: const EdgeInsets.only(left: 8),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              messagesModel.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: messagesModel.isUnread ? Colors.black87 : Colors.grey.shade600,
                fontWeight: messagesModel.isUnread ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          // Sent indicator (checkmark for messages from current user)
          if (messagesModel.isFromCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.check,
                size: 16,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
      trailing: Text(
        messagesModel.time,
        style: TextStyle(
          fontSize: 12,
          color: messagesModel.isUnread ? Colors.blue : Colors.grey.shade500,
          fontWeight: messagesModel.isUnread ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}