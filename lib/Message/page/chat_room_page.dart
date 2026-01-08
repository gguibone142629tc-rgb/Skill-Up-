import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:finaproj/Profile_page/pages/pofile_page.dart';
import 'package:finaproj/Profile_page/pages/student_profile_view.dart';
import 'package:finaproj/common/loading_dialog.dart';
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

  // Selected image state
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  // Cloudinary config (same as profile uploads)
  final String cloudName = 'dagnamipk';
  final String uploadPreset = 'skillup_preset';

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String> _uploadToCloudinary(
      Uint8List fileBytes, String fileName) async {
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset;

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'] ?? '';
      } else {
        throw Exception(
            'Upload failed: ${jsonResponse['error']?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      rethrow;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(that).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF356966).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatDayLabel(date),
                style: const TextStyle(
                  color: Color(0xFF356966),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
        ],
      ),
    );
  }

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
  void _deleteMessage(
      String messageId, bool isLastMessage, String? newLastMsg) async {
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
  void _showOptions(
      String messageId, bool isMe, bool isLastMessage, String? prevMsg) {
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
                  title: const Text('Delete Message',
                      style: TextStyle(color: Colors.red)),
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

  Future<void> _sendMessage(
      {String? text,
      String? imageUrl,
      String? fileUrl,
      String? fileName}) async {
    if ((text == null || text.trim().isEmpty) &&
        imageUrl == null &&
        fileUrl == null) return;

    String displayMessage;
    if (fileUrl != null) {
      displayMessage = 'Sent a file: ${fileName ?? 'Attachment'}';
    } else if (imageUrl != null) {
      displayMessage = 'Sent an image';
    } else {
      displayMessage = text!.trim();
    }

    try {
      // Get sender's name
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      final senderData = senderDoc.data();
      final senderName = senderData != null
          ? '${senderData['firstName'] ?? ''} ${senderData['lastName'] ?? ''}'
              .trim()
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
        'fileUrl': fileUrl ?? "",
        'fileName': fileName ?? "",
        'timestamp': FieldValue.serverTimestamp(),
        'type': fileUrl != null
            ? 'file'
            : imageUrl != null
                ? 'image'
                : 'text',
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
        String? messageContent;
        if (fileUrl != null) {
          messageContent = '📎 Sent a file: ${fileName ?? 'Attachment'}';
        } else if (imageUrl != null) {
          messageContent = '📸 Sent an image';
        } else {
          messageContent = text;
        }
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
        _scrollController.animateTo(0.0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
      _showError('Could not send message. Please try again.');
    }
  }

  Future<void> _pickImage() async {
    debugPrint('📸 Picking image...');
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) {
      debugPrint('❌ Image picker cancelled');
      return;
    }

    debugPrint('✅ Image picked, loading preview...');
    final bytes = await image.readAsBytes();
    setState(() {
      _selectedImage = image;
      _selectedImageBytes = bytes;
    });
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  Future<void> _sendMessageWithAttachment() async {
    // Check if there's an image to send
    if (_selectedImage != null && _selectedImageBytes != null) {
      setState(() => _isUploading = true);
      try {
        debugPrint('📤 Uploading image to Cloudinary...');
        final downloadUrl = await _uploadToCloudinary(
            _selectedImageBytes!, _selectedImage!.name);

        debugPrint('✅ Got URL: $downloadUrl');
        debugPrint('📨 Sending message with image...');
        await _sendMessage(
          text: _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
          imageUrl: downloadUrl,
        );

        // Clear selected image after successful send
        _clearSelectedImage();
        debugPrint('✅ Message sent!');
      } catch (e) {
        debugPrint("❌ Upload Error: $e");
        _showError('Image upload failed: ${e.toString()}');
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    } else {
      // No image, just send text
      await _sendMessage(text: _messageController.text);
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
        backgroundColor: bgGrey,
        elevation: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(24),
          child: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () async {
            // Load and navigate to the other user's profile
            try {
              LoadingDialog.show(context);
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
                  LoadingDialog.hide(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentProfileView(studentId: uid),
                    ),
                  );
                } else {
                  // Mentor profile
                  userData['uid'] = uid;
                  LoadingDialog.hide(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(mentorData: userData),
                    ),
                  );
                }
              }
            } catch (e) {
              debugPrint("Error loading profile: $e");
              if (mounted) LoadingDialog.hide(context);
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: brandGreen.withOpacity(0.1),
                backgroundImage: widget.otherUserProfileImage != null &&
                        widget.otherUserProfileImage!.isNotEmpty
                    ? NetworkImage(widget.otherUserProfileImage!)
                    : null,
                child: widget.otherUserProfileImage == null ||
                        widget.otherUserProfileImage!.isEmpty
                    ? Text(widget.otherUserName[0].toUpperCase(),
                        style: const TextStyle(color: brandGreen))
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Online",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(color: brandGreen),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                var docs = snapshot.data!.docs;

                // ✅ FIXED: Sort messages by timestamp in descending order (newest first)
                docs.sort((a, b) {
                  var aTime = (a['timestamp'] as Timestamp?)?.toDate() ??
                      DateTime.now();
                  var bTime = (b['timestamp'] as Timestamp?)?.toDate() ??
                      DateTime.now();
                  return bTime.compareTo(aTime); // Descending - newest first
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  reverse: true, // ✅ Newest message appears at top
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == widget.currentUserId;
                    final messageType = (data['type'] ?? 'text') as String;
                    bool isImage = messageType == 'image';
                    bool isFile = messageType == 'file';
                    String reaction = data['reaction'] ?? '';
                    DateTime messageDate = data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate()
                        : DateTime.now();
                    String time = DateFormat('hh:mm a').format(messageDate);

                    bool isLastMessage = index == 0;
                    String? nextMessageInList = docs.length > 1
                        ? (docs[1].data() as Map<String, dynamic>)['text']
                        : null;

                    // Check if we need to show date header
                    bool showDateHeader = false;
                    if (index == docs.length - 1) {
                      showDateHeader = true;
                    } else {
                      var nextDoc = docs[index + 1];
                      var nextData = nextDoc.data() as Map<String, dynamic>;
                      DateTime nextMessageDate = nextData['timestamp'] != null
                          ? (nextData['timestamp'] as Timestamp).toDate()
                          : DateTime.now();
                      if (!_isSameDay(messageDate, nextMessageDate)) {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(messageDate),
                        Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onLongPress: () => _showOptions(doc.id, isMe,
                                  isLastMessage, nextMessageInList),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.75),
                                          padding: isImage
                                              ? EdgeInsets.zero
                                              : const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color:
                                                isMe ? brandGreen : bubbleGrey,
                                            borderRadius: BorderRadius.only(
                                              topLeft:
                                                  const Radius.circular(20),
                                              topRight:
                                                  const Radius.circular(20),
                                              bottomLeft: Radius.circular(
                                                  isMe ? 4 : 20),
                                              bottomRight: Radius.circular(
                                                  isMe ? 20 : 4),
                                            ),
                                          ),
                                          child: isImage
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  child: Image.network(
                                                      data['imageUrl'],
                                                      fit: BoxFit.cover),
                                                )
                                              : isFile
                                                  ? GestureDetector(
                                                      onTap: () async {
                                                        final url =
                                                            (data['fileUrl'] ??
                                                                '') as String;
                                                        if (url.isEmpty) return;
                                                        final uri =
                                                            Uri.parse(url);
                                                        if (await canLaunchUrl(
                                                            uri)) {
                                                          await launchUrl(uri,
                                                              mode: LaunchMode
                                                                  .externalApplication);
                                                        }
                                                      },
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .insert_drive_file,
                                                              color: isMe
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black54),
                                                          const SizedBox(
                                                              width: 10),
                                                          Flexible(
                                                            child: Text(
                                                              (data['fileName'] ??
                                                                      'Attachment')
                                                                  as String,
                                                              style: TextStyle(
                                                                color: isMe
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black87,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : Text(
                                                      data['text'] ?? "",
                                                      style: TextStyle(
                                                          color: isMe
                                                              ? Colors.white
                                                              : Colors.black87),
                                                    ),
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
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: Colors.black26,
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2))
                                                ],
                                              ),
                                              child: Text(reaction,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 10, left: 4, right: 4),
                                      child: Text(
                                        time,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image preview
                if (_selectedImageBytes != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: brandGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _selectedImageBytes!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Image selected',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: _clearSelectedImage,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image,
                              color: brandGreen, size: 30)),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30)),
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                                hintText: "Write a message...",
                                border: InputBorder.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _sendMessageWithAttachment,
                        borderRadius: BorderRadius.circular(50),
                        child: Ink(
                          decoration: const BoxDecoration(
                            color: brandGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child:
                                Icon(Icons.send, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
