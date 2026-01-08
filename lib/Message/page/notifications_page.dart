import 'package:flutter/material.dart';
import 'package:finaproj/services/notification_service.dart';
import 'package:finaproj/services/notification_model.dart';
import 'package:finaproj/Message/page/chat_room_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:finaproj/app_settings/page/my_subscribers_page.dart';
import 'package:finaproj/SessionHistory/pages/session_history_screen.dart';
import 'package:finaproj/app_settings/page/profile_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Mark all as read when page opens
    _notificationService.markAllAsRead();
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) async {
    // Always mark the tapped notification as read before navigating
    await _notificationService.markAsRead(notification.id);

    if (!mounted) return;

    final type = notification.type.toLowerCase().trim();

    // Navigate based on notification type
    if (type == 'message' && notification.relatedId != null) {
      // Extract data from notification
      final chatRoomId = notification.relatedId!;
      final senderName = notification.data?['senderName'] ?? notification.data?['mentorName'] ?? 'User';
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      // Get the other user's ID from the chat room ID
      // Chat room ID format: mentorId_studentId
      final userIds = chatRoomId.split('_');
      final otherUserId = userIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => userIds.first,
      );
      
      // Fetch other user's profile image from Firestore
      String? senderProfileImage;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .get();
        if (userDoc.exists) {
          senderProfileImage = userDoc.data()?['profileImageUrl'];
        }
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(
            chatRoomId: chatRoomId,
            otherUserName: senderName,
            currentUserId: currentUserId,
            otherUserProfileImage: senderProfileImage,
          ),
        ),
      );
    } else if (type == 'booking') {
      // For booking notifications, navigate to subscribers page to see who subscribed
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MySubscribersPage(),
        ),
      );
    } else if (type == 'session') {
      // For session notifications, show session details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionReminderPage(notification: notification),
        ),
      );
    } else if (type == 'rating' || type.contains('rating')) {
      // For rating notifications, navigate to profile and focus the ratings section
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilePage(focusRatings: true),
        ),
      );
    } else if (type == 'subscription' || type.contains('subscription') || type.contains('subscrib')) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final data = notification.data ?? {};
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to view this subscription')),
        );
        return;
      }

      // Data may use different key shapes depending on who received the notification
      String? mentorId = data['mentorId'] ?? data['mentor_id'] ?? data['mentorID'];
      String? menteeId = data['menteeId'] ?? data['mentee_id'] ?? data['menteeID'];
      final String? subscriptionId =
          data['subscriptionId'] ?? data['subscription_id'] ?? notification.relatedId;

      // Try to hydrate from subscription doc if relatedId points to it
      if (subscriptionId != null) {
        try {
          final subDoc = await FirebaseFirestore.instance
              .collection('subscriptions')
              .doc(subscriptionId)
              .get();
          if (subDoc.exists) {
            final subData = subDoc.data();
            mentorId ??= subData?['mentorId'] as String?;
            menteeId ??= subData?['menteeId'] as String?;
          }
        } catch (e) {
          debugPrint('Error loading subscription doc: $e');
        }
      }

      if (!mounted) return;

      // Load user role to decide mentor/student path
      bool isMentorAccount = false;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();
        final userData = userDoc.data();
        final role = userData?['role']?.toString().toLowerCase();
        isMentorAccount = userData?['isMentor'] == true || role == 'mentor';
      } catch (e) {
        debugPrint('Error loading user role: $e');
      }

      if (!mounted) return;

      // If you are the mentor (explicitly or inferred), go to subscribers
      final bool isMentorRecipient = (mentorId == currentUserId) ||
          (menteeId != null && menteeId != currentUserId) ||
          isMentorAccount;

      if (isMentorRecipient) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MySubscribersPage(),
          ),
        );
        return;
      }

      // Student path: open your subscription list focusing on the mentor
      // Fallback lookup: find a recent subscription for this mentee (optionally filtered by plan)
      if (mentorId == null) {
        try {
          Query<Map<String, dynamic>> query = FirebaseFirestore.instance
              .collection('subscriptions')
              .where('menteeId', isEqualTo: currentUserId);

          if (data['planName'] != null) {
            query = query.where('planTitle', isEqualTo: data['planName']);
          }

          final subSnap = await query
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();
          if (subSnap.docs.isNotEmpty) {
            mentorId = subSnap.docs.first.data()['mentorId'] as String?;
          }
        } catch (e) {
          debugPrint('Error finding mentor for subscription: $e');
        }
      }

      if (!mounted) return;

      // Always navigate; if mentorId is still null, show list without focus
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MySubscriptionPage(focusMentorId: mentorId),
        ),
      );
    } else {
      // Unknown/system notification types: still provide a tap action.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notification.title.isNotEmpty ? notification.title : 'Notification opened')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  _notificationService.markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                    ),
                  );
                },
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: Color(0xFF2D6A65),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                onDelete: () {
                  _notificationService.deleteNotification(notification.id);
                },
                onTap: () => _handleNotificationTap(context, notification),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.notification,
    required this.onDelete,
    this.onTap,
  });

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'booking':
        return Icons.calendar_today;
      case 'session':
        return Icons.video_call;
      case 'subscription':
        return Icons.card_membership;
      case 'rating':
        return Icons.star_rate;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'booking':
        return Colors.green;
      case 'session':
        return Colors.purple;
      case 'subscription':
        return Colors.orange;
      case 'rating':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade100,
        child: Icon(Icons.delete, color: Colors.red.shade700),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Material(
          color: notification.isRead ? Colors.white : Colors.blue.shade50,
          elevation: notification.isRead ? 0 : 1.5,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!, width: 1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getColorForType(notification.type).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _getIconForType(notification.type),
                        color: _getColorForType(notification.type),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              _getTimeAgo(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SessionReminderPage extends StatelessWidget {
  final NotificationModel notification;

  const SessionReminderPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final data = notification.data ?? {};
    final mentorName = data['mentorName'] ?? 'Your mentor';
    final courseTitle = data['courseTitle'] ?? 'Session';
    final rawDate = data['sessionDate'];
    DateTime? sessionDate;

    if (rawDate is Timestamp) {
      sessionDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      sessionDate = rawDate;
    } else if (rawDate is String) {
      sessionDate = DateTime.tryParse(rawDate);
    }

    final formattedDate = sessionDate != null
        ? DateFormat('MMM d, y • h:mm a').format(sessionDate)
        : 'Scheduled soon';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Session Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D6A65),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Color(0xFF2D6A65)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mentorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.black54, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.body,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A65),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MySubscriptionPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.list_alt),
                label: const Text(
                  'View My Subscriptions',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
