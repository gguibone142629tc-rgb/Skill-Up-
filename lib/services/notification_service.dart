import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:finaproj/services/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initializeNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize local notifications for Android
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('notification_icon');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Request permissions for iOS
    await _firebaseMessaging.requestPermission();

    // Get FCM token and store it
    await _storeFCMToken();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<void> _storeFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'fcmToken': token});
        }
      }
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Handling foreground message: ${message.messageId}');

    // Show local notification
    await _showLocalNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      payload: message.data,
    );

    // Store notification in Firestore
    if (FirebaseAuth.instance.currentUser != null) {
      await _saveNotificationToFirestore(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        type: message.data['type'] ?? 'system',
        relatedId: message.data['relatedId'],
        data: message.data,
      );
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Message opened: ${message.messageId}');
    // Handle navigation based on message type
    // You can use a global navigator or callback
  }

  void _handleNotificationTap(NotificationResponse notificationResponse) {
    print('Notification tapped: ${notificationResponse.payload}');
    // Handle navigation
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'channel_id',
      'Default Channel',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload.toString(),
    );
  }

  Future<void> _saveNotificationToFirestore({
    required String title,
    required String body,
    required String type,
    String? relatedId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final notification = NotificationModel(
          id: '', // Firestore will generate
          userId: user.uid,
          title: title,
          body: body,
          type: type,
          relatedId: relatedId,
          isRead: false,
          createdAt: DateTime.now(),
          data: data,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add(notification.toFirestore());
      }
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  // Get all notifications for current user
  Stream<List<NotificationModel>> getNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get unread notification count
  Stream<int> getUnreadCountStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final unreadNotifications = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .get();

        for (var doc in unreadNotifications.docs) {
          await doc.reference.update({'isRead': true});
        }
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .delete();
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Send booking notification
  Future<void> sendBookingNotification({
    required String mentorId,
    required String studentName,
    required String courseTitle,
    required DateTime sessionDate,
  }) async {
    try {
      final dateFormat = DateFormat('MMM d, yyyy h:mm a');
      final formattedDate = dateFormat.format(sessionDate);
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(mentorId)
          .collection('notifications')
          .add({
        'userId': mentorId,
        'title': 'New Session Booking',
        'body': '$studentName booked a session for $courseTitle',
        'type': 'booking',
        'relatedId': courseTitle,
        'isRead': false,
        'createdAt': DateTime.now(),
        'data': {
          'studentName': studentName,
          'courseTitle': courseTitle,
          'sessionDate': sessionDate,
        },
      });

      // Show local notification
      await _showLocalNotification(
        title: 'New Session Booking',
        body: '$studentName booked a session for $courseTitle on $formattedDate',
        payload: {'type': 'booking', 'mentorId': mentorId},
      );
    } catch (e) {
      print('Error sending booking notification: $e');
    }
  }

  // Send session reminder notification
  Future<void> sendSessionReminder({
    required String userId,
    required String mentorName,
    required String courseTitle,
    required DateTime sessionDate,
  }) async {
    try {
      final dateFormat = DateFormat('h:mm a');
      final formattedTime = dateFormat.format(sessionDate);
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'userId': userId,
        'title': 'Session Reminder',
        'body': 'Your session with $mentorName for $courseTitle starts at $formattedTime',
        'type': 'session',
        'relatedId': courseTitle,
        'isRead': false,
        'createdAt': DateTime.now(),
        'data': {
          'mentorName': mentorName,
          'courseTitle': courseTitle,
          'sessionDate': sessionDate,
        },
      });

      // Show local notification
      await _showLocalNotification(
        title: 'Session Reminder',
        body: 'Your session with $mentorName for $courseTitle starts at $formattedTime',
        payload: {'type': 'session', 'userId': userId},
      );
    } catch (e) {
      print('Error sending session reminder: $e');
    }
  }

  // Send subscription expiry notification
  Future<void> sendSubscriptionNotification({
    required String userId,
    required String planName,
    required int daysRemaining,
  }) async {
    try {
      String title;
      String body;

      if (daysRemaining <= 0) {
        title = 'Subscription Expired';
        body = 'Your $planName subscription has expired. Renew now to continue.';
      } else if (daysRemaining == 1) {
        title = 'Subscription Expiring Tomorrow';
        body = 'Your $planName subscription expires tomorrow. Renew now.';
      } else {
        title = 'Subscription Expiring Soon';
        body = 'Your $planName subscription expires in $daysRemaining days.';
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': 'subscription',
        'relatedId': planName,
        'isRead': false,
        'createdAt': DateTime.now(),
        'data': {
          'planName': planName,
          'daysRemaining': daysRemaining,
        },
      });

      // Show local notification
      await _showLocalNotification(
        title: title,
        body: body,
        payload: {'type': 'subscription', 'userId': userId},
      );
    } catch (e) {
      print('Error sending subscription notification: $e');
    }
  }
}
