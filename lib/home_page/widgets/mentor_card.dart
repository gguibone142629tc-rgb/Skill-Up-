import 'package:finaproj/home_page/model/mentor_model.dart';
import 'package:finaproj/Profile_page/pages/pofile_page.dart';
import 'package:finaproj/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MentorCard extends StatefulWidget {
  final Mentor mentor;

  const MentorCard({super.key, required this.mentor});

  @override
  State<MentorCard> createState() => _MentorCardState();
}

class _MentorCardState extends State<MentorCard> {
  final DatabaseService _dbService = DatabaseService();
  bool _isSaved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final saved = await _dbService.isMentorSaved(userId, widget.mentor.id);
      setState(() {
        _isSaved = saved;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSaved() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save mentors')),
      );
      return;
    }

    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      if (_isSaved) {
        await _dbService.saveMentor(userId, widget.mentor.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mentor saved!'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await _dbService.unsaveMentor(userId, widget.mentor.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mentor removed from saved'),
              duration: Duration(seconds: 1),
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
          const SnackBar(content: Text('Error saving mentor')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey[200],
                backgroundImage: widget.mentor.image.startsWith('http')
                    ? NetworkImage(widget.mentor.image)
                    : (widget.mentor.image.isNotEmpty
                        ? AssetImage(widget.mentor.image)
                        : null) as ImageProvider?,
                child: widget.mentor.image.isEmpty
                    ? const Icon(Icons.person, size: 30, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mentor.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.work_outline,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.mentor.jobTitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        widget.mentor.rating.toString(),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Save/Bookmark Button
                  _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : InkWell(
                          onTap: _toggleSaved,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _isSaved
                                  ? const Color(0xFF2D6A65).withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              _isSaved ? Icons.bookmark : Icons.bookmark_border,
                              size: 20,
                              color: _isSaved
                                  ? const Color(0xFF2D6A65)
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.mentor.skills
                .map((skill) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.mentor.pricePerMonth == 'Free'
                    ? 'Starting at ₱1200/mo'
                    : widget.mentor.pricePerMonth,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D6A65),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        mentorData: {
                          'uid': widget.mentor.id,
                          'firstName': widget.mentor.name.split(' ')[0],
                          'lastName': widget.mentor.name.contains(' ')
                              ? widget.mentor.name.split(' ')[1]
                              : '',
                          'jobTitle': widget.mentor.jobTitle,
                          'profileImageUrl': widget.mentor.image,
                          'rating': widget.mentor.rating,
                          'skills': widget.mentor.skills,
                          'price': widget.mentor.pricePerMonth,
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A65),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                child: const Text(
                  "View Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
