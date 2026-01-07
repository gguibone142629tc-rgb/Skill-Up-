import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finaproj/services/notification_service.dart';

class SubscriptionExpiryChecker {
  static final SubscriptionExpiryChecker _instance =
      SubscriptionExpiryChecker._internal();

  factory SubscriptionExpiryChecker() {
    return _instance;
  }

  SubscriptionExpiryChecker._internal();

  /// Check all subscriptions for the current user and send notifications if expiring soon
  Future<void> checkSubscriptionsForExpiration() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final subscriptionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('subscriptions')
          .where('status', isEqualTo: 'active')
          .get();

      final now = DateTime.now();
      final notificationService = NotificationService();

      for (var doc in subscriptionsSnapshot.docs) {
        final data = doc.data();
        final endDate = (data['endDate'] as Timestamp).toDate();
        final planName = data['planName'] ?? 'Your subscription';
        final mentorId = data['mentorId'] as String?;
        final daysRemaining = endDate.difference(now).inDays;

        // Send notification if:
        // 1. Subscription expires in exactly 7 days
        // 2. Subscription expires in exactly 1 day
        // 3. Subscription has already expired
        // 4. Subscription expires today
        if (daysRemaining == 7 ||
            daysRemaining == 1 ||
            daysRemaining <= 0 ||
            (endDate.day == now.day &&
                endDate.month == now.month &&
                endDate.year == now.year)) {
          
          // Check if we already sent a notification for this expiry
          final existingNotifications = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('type', isEqualTo: 'subscription')
              .where('data.planName', isEqualTo: planName)
              .where('createdAt',
                  isGreaterThan: DateTime.now().subtract(Duration(days: 1)))
              .get();

          if (existingNotifications.docs.isEmpty) {
            await notificationService.sendSubscriptionNotification(
              userId: user.uid,
              planName: planName,
              daysRemaining: daysRemaining,
              mentorId: mentorId,
            );
          }
        }
      }
    } catch (e) {
      print('Error checking subscription expiry: $e');
    }
  }

  /// Stream to listen for subscription changes and check expiry
  Stream<List<Map<String, dynamic>>> getExpiringSubscriptions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final expiringSubscriptions = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final endDate = (data['endDate'] as Timestamp).toDate();
        final daysRemaining = endDate.difference(now).inDays;

        // Consider expiring if within 7 days
        if (daysRemaining <= 7 && daysRemaining >= 0) {
          expiringSubscriptions.add({
            'planName': data['planName'],
            'daysRemaining': daysRemaining,
            'endDate': endDate,
            'docId': doc.id,
          });
        }
      }

      return expiringSubscriptions;
    });
  }
}
