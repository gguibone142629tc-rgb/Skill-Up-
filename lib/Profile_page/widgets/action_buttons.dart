import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finaproj/Message/page/chat_room_page.dart';
import 'package:finaproj/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ActionButtons extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const ActionButtons({super.key, required this.mentorData});

  @override
  State<ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<ActionButtons> {
  final DatabaseService _dbService = DatabaseService();
  bool _isSaved = false;
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final mentorId = widget.mentorData['uid'];

    if (userId != null && mentorId != null) {
      String? role;
      try {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(userId).get();
        role = userDoc.data()?['role'] as String?;
      } catch (_) {
        role = null;
      }

      final saved = await _dbService.isMentorSaved(userId, mentorId);
      if (mounted) {
        setState(() {
          _userRole = role;
          _isSaved = saved;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleSaved() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final mentorId = widget.mentorData['uid'];
    final isMentorUser = _userRole == 'mentor';

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save mentors')),
      );
      return;
    }

    if (isMentorUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mentors cannot save other mentors')),
      );
      return;
    }

    if (mentorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Mentor ID not found')),
      );
      return;
    }

    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      if (_isSaved) {
        await _dbService.saveMentor(userId, mentorId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mentor saved!'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF2D6A65),
            ),
          );
        }
      } else {
        await _dbService.unsaveMentor(userId, mentorId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mentor removed from saved'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSaved = !_isSaved;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _handleMessage(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final String mentorId = widget.mentorData['uid'] ?? '';
    final String mentorName = "${widget.mentorData['firstName'] ?? 'Mentor'}";
    // Get the profile image from mentorData to pass it to the chat room
    final String? profileImg = widget.mentorData['profileImageUrl'];

    try {
      final db = DatabaseService();

      // CHANGE THIS LINE: from getOrCreateChatRoom to getChatRoomId
      String roomId = await db.getChatRoomId(currentUser.uid, mentorId);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              chatRoomId: roomId,
              otherUserName: mentorName,
              currentUserId: currentUser.uid,
              otherUserProfileImage: profileImg, // Pass the image here!
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMentorUser = _userRole == 'mentor';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Left Button: Message (Dark Teal)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleMessage(context),
              icon: const Icon(Icons.send, size: 18, color: Colors.white),
              label: const Text(
                "Message",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF356966), // Dark Teal
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(), // Perfect pill shape
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Right Button: Save Mentor (Light Grey)
          Expanded(
            child: _isLoading
                ? ElevatedButton.icon(
                    onPressed: null,
                    icon: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    label: const Text(
                      "Loading...",
                      style: TextStyle(
                          color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: isMentorUser ? null : _toggleSaved,
                    icon: Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: _isSaved
                          ? const Color(0xFF2D6A65)
                          : (isMentorUser ? Colors.grey[400] : Colors.black),
                    ),
                    label: Text(
                      _isSaved ? "Saved" : "Save Mentor",
                      style: TextStyle(
                        color: _isSaved
                            ? const Color(0xFF2D6A65)
                            : (isMentorUser ? Colors.grey[400] : Colors.black),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaved
                          ? const Color(0xFF2D6A65).withOpacity(0.1)
                          : (isMentorUser
                              ? Colors.grey[200]
                              : const Color(0xFFF5F5F5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
