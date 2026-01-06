import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UnreadMessagesService {
  static final UnreadMessagesService _instance = UnreadMessagesService._internal();

  factory UnreadMessagesService() {
    return _instance;
  }

  UnreadMessagesService._internal();

  /// Get stream of unread message count for current user
  /// Counts unique chat rooms where:
  /// 1. Last sender is not the current user
  /// 2. Current user has not read the message yet
  Stream<int> getUnreadMessagesCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('users', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      int unreadCount = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lastSenderId = data['lastSenderId'] as String?;
        final lastTimestamp = data['lastTimestamp'] as Timestamp?;
        final lastReadKey = 'lastReadBy_${currentUser.uid}';
        final lastReadTimestamp = data[lastReadKey] as Timestamp?;
        
        debugPrint('Chat ${doc.id}: lastSenderId=$lastSenderId, currentUser=$currentUser, lastMsg=$lastTimestamp, lastRead=$lastReadTimestamp');
        
        // Only count as unread if:
        // 1. Last message exists and is from someone else
        // 2. AND either:
        //    a) This is the first time reading (no read timestamp)
        //    b) OR the last message is newer than the last read timestamp
        if (lastSenderId != null && lastSenderId != currentUser.uid && lastTimestamp != null) {
          
          if (lastReadTimestamp == null) {
            // Never read this chat room before
            debugPrint('  -> UNREAD (never read)');
            unreadCount++;
          } else {
            final lastMsgTime = lastTimestamp.toDate();
            final lastReadTime = lastReadTimestamp.toDate();
            
            // Message is newer than last read
            if (lastMsgTime.isAfter(lastReadTime)) {
              debugPrint('  -> UNREAD (new message: $lastMsgTime > $lastReadTime)');
              unreadCount++;
            } else {
              debugPrint('  -> READ (message is older: $lastMsgTime <= $lastReadTime)');
            }
          }
        }
      }
      
      debugPrint('Total unread: $unreadCount');
      return unreadCount;
    });
  }

  /// Mark all messages in a chat room as read
  Future<void> markChatRoomAsRead(String chatRoomId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;
      
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .update({
        'lastReadBy_$currentUserId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking chat room as read: $e');
    }
  }
}
