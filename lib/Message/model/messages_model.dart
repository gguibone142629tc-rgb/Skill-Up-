class MessagesModel {
  final String profilePath;
  final String name;
  final String message; // Ensure this is a String
  final String time;
  final String chatRoomId;
  final bool isFromCurrentUser; // Whether last message is from current user
  final bool isUnread; // Whether chat room has unread messages

  MessagesModel({
    required this.profilePath,
    required this.name,
    required this.message,
    required this.time,
    required this.chatRoomId,
    this.isFromCurrentUser = false,
    this.isUnread = false,
  });
}