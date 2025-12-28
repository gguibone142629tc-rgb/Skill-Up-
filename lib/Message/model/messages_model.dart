class MessagesModel {
  final String profilePath;
  final String name;
  final String message; // Ensure this is a String
  final String time;
  final String chatRoomId;

  MessagesModel({
    required this.profilePath,
    required this.name,
    required this.message,
    required this.time,
    required this.chatRoomId,
  });
}