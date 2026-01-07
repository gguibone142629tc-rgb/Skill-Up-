import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finaproj/Profile_page/pages/pofile_page.dart';
import 'package:finaproj/Profile_page/pages/student_profile_view.dart';
import 'package:finaproj/services/unread_messages_service.dart';


class ChatRoomPage extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;
  final String currentUserId;
  final String? otherUserProfileImage;

  const ChatRoomPage({
    super.key,
    required this.chatRoomId,
    required this.otherUserName,
    required this.currentUserId,
    this.otherUserProfileImage,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Mark chat room as read using the service
    Future.delayed(const Duration(milliseconds: 100), () {
      UnreadMessagesService().markChatRoomAsRead(widget.chatRoomId);
      debugPrint('Marked chat room as read via service');
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- NEW: REACTION FUNCTION ---
  void _reactToMessage(String messageId, String emoji) async {
    try {
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'reaction': emoji});
    } catch (e) {
      debugPrint("Error reacting: $e");
    }
  }

  // --- DELETE MESSAGE FUNCTION ---
  void _deleteMessage(String messageId, bool isLastMessage, String? newLastMsg) async {
    try {
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();

      if (isLastMessage) {
        await FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(widget.chatRoomId)
            .update({
          'lastMessage': newLastMsg ?? "Message deleted",
          'lastTimestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error deleting message: $e");
    }
  }

  // --- UPDATED: SHOW OPTIONS DIALOG (EMOJIS + DELETE) ---
  void _showOptions(String messageId, bool isMe, bool isLastMessage, String? prevMsg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji Reaction Row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['❤️', '👍', '😂', '😮', '😢', '🔥'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        _reactToMessage(messageId, emoji);
                        Navigator.pop(context);
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 30)),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              if (isMe) 
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Message', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(messageId, isLastMessage, prevMsg);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage({String? text, String? imageUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null) return;
    final String displayMessage = text ?? (imageUrl != null ? 'Sent an image' : '');

    try {
      // Get sender's name
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      final senderData = senderDoc.data();
      final senderName = senderData != null
          ? '${senderData['firstName'] ?? ''} ${senderData['lastName'] ?? ''}'.trim()
          : 'User';

      // Get recipient's ID from chat room
      final chatRoomDoc = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .get();
      final chatRoomData = chatRoomDoc.data();
      final List users = chatRoomData?['users'] ?? [];
      final String recipientId = users.firstWhere(
        (id) => id != widget.currentUserId,
        orElse: () => '',
      );

      // Send message
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'senderId': widget.currentUserId,
        'text': text ?? "",
        'imageUrl': imageUrl ?? "",
        'timestamp': FieldValue.serverTimestamp(),
        'type': imageUrl != null ? 'image' : 'text',
        'reaction': '', // Initialize with empty reaction
      });

      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .set({
        'lastMessage': displayMessage,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'lastSenderId': widget.currentUserId,
      }, SetOptions(merge: true));

      // Send notification to the recipient
      if (recipientId.isNotEmpty) {
        final messageContent = imageUrl != null ? '📸 Sent an image' : text;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(recipientId)
            .collection('notifications')
            .add({
          'userId': recipientId,
          'title': 'New Message from $senderName',
          'body': messageContent ?? 'Sent a message',
          'type': 'message',
          'relatedId': widget.chatRoomId,
          'isRead': false,
          'createdAt': DateTime.now(),
          'data': {
            'senderId': widget.currentUserId,
            'senderName': senderName,
            'chatRoomId': widget.chatRoomId,
            'messagePreview': messageContent ?? 'Message',
          },
        }).catchError((e) {
          debugPrint("Error saving notification: $e");
          throw e;
        });
      }

      if (text != null) _messageController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  Future<void> _onPlusTap() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = FirebaseStorage.instance.ref().child('chat_images').child('${widget.chatRoomId}_$fileName.jpg');
        if (kIsWeb) {
          Uint8List bytes = await image.readAsBytes();
          await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          await ref.putFile(File(image.path));
        }
        String downloadUrl = await ref.getDownloadURL();
        _sendMessage(imageUrl: downloadUrl);
      } catch (e) {
        debugPrint("Upload Error: $e");
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF356966);
    const Color bgGrey = Color(0xFFF7F8FA);
    const Color bubbleGrey = Color(0xFFE9EBEE);
    
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: bgGrey, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28), onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () async {
            // Load and navigate to the other user's profile
            try {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .where('fullName', isEqualTo: widget.otherUserName)
                  .limit(1)
                  .get();
              
              if (userDoc.docs.isNotEmpty && mounted) {
                final userData = userDoc.docs.first.data();
                final uid = userDoc.docs.first.id;
                final userRole = (userData['role'] ?? 'mentor').toLowerCase();
                
                // Navigate to appropriate profile based on user role
                if (userRole == 'student') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentProfileView(studentId: uid),
                    ),
                  );
                } else {
                  // Mentor profile
                  userData['uid'] = uid;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(mentorData: userData),
                    ),
                  );
                }
              }
            } catch (e) {
              debugPrint("Error loading profile: $e");
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 20, backgroundColor: brandGreen.withOpacity(0.1),
                backgroundImage: widget.otherUserProfileImage != null && widget.otherUserProfileImage!.isNotEmpty ? NetworkImage(widget.otherUserProfileImage!) : null,
                child: widget.otherUserProfileImage == null || widget.otherUserProfileImage!.isEmpty ? Text(widget.otherUserName[0].toUpperCase(), style: const TextStyle(color: brandGreen)) : null,
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.otherUserName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                const Text("Online", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(color: brandGreen),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId).collection('messages').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                var docs = snapshot.data!.docs;
                
                // ✅ FIXED: Sort messages by timestamp in descending order (newest first)
                docs.sort((a, b) {
                  var aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                  var bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                  return bTime.compareTo(aTime); // Descending - newest first
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  reverse: true, // ✅ Newest message appears at top
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == widget.currentUserId;
                    bool isImage = (data['type'] ?? 'text') == 'image';
                    String reaction = data['reaction'] ?? '';
                    String time = data['timestamp'] != null ? DateFormat('hh:mm a').format((data['timestamp'] as Timestamp).toDate()) : "...";

                    bool isLastMessage = index == 0;
                    String? nextMessageInList = docs.length > 1 ? (docs[1].data() as Map<String, dynamic>)['text'] : null;

                    return Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onLongPress: () => _showOptions(doc.id, isMe, isLastMessage, nextMessageInList),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                      padding: isImage ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isMe ? brandGreen : bubbleGrey,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(20),
                                          topRight: const Radius.circular(20),
                                          bottomLeft: Radius.circular(isMe ? 4 : 20),
                                          bottomRight: Radius.circular(isMe ? 20 : 4),
                                        ),
                                      ),
                                      child: isImage 
                                        ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(data['imageUrl'], fit: BoxFit.cover))
                                        : Text(data['text'] ?? "", style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                                    ),
                                    // --- REACTION BADGE ---
                                    if (reaction.isNotEmpty)
                                      Positioned(
                                        bottom: -8,
                                        right: isMe ? -8 : null,
                                        left: isMe ? null : -8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                          ),
                                          child: Text(reaction, style: const TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
                                  child: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  IconButton(onPressed: _onPlusTap, icon: const Icon(Icons.add_circle, color: brandGreen, size: 30)),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(hintText: "Write a message...", border: InputBorder.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(text: _messageController.text),
                    child: const CircleAvatar(backgroundColor: brandGreen, child: Icon(Icons.send, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}