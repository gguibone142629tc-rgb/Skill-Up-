import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        final data = doc.data() as Map<String, dynamic>;
        final lastSenderId = data['lastSenderId'] as String?;
        final lastTimestamp = data['lastTimestamp'] as Timestamp?;
        final lastReadKey = 'lastReadBy_${currentUser.uid}';
        final lastReadTimestamp = data[lastReadKey] as Timestamp?;
        
        // Count chat rooms where:
        // 1. Last message is from someone else (not current user)
        // 2. Last message is newer than last read time
        if (lastSenderId != null && 
            lastSenderId != currentUser.uid && 
            lastTimestamp != null) {
          
          if (lastReadTimestamp == null) {
            // Never read this chat room
            unreadCount++;
          } else if (lastTimestamp.toDate().isAfter(lastReadTimestamp.toDate())) {
            // New messages after last read
            unreadCount++;
          }
        }
      }
      
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
