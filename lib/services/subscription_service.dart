import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if a subscription has expired and update status
  Future<String> checkAndUpdateSubscriptionStatus(String subscriptionId) async {
    try {
      final doc = await _firestore.collection('subscriptions').doc(subscriptionId).get();
      
      if (!doc.exists) return 'not_found';
      
      final data = doc.data()!;
      final currentStatus = data['status'] ?? 'active';
      
      // If already cancelled or expired, return current status
      if (currentStatus == 'cancelled') return 'cancelled';
      if (currentStatus == 'expired') return 'expired';
      
      // Check if subscription has expired
      final expiresAt = data['expiresAt'];
      if (expiresAt != null) {
        DateTime expirationDate;
        if (expiresAt is Timestamp) {
          expirationDate = expiresAt.toDate();
        } else if (expiresAt is DateTime) {
          expirationDate = expiresAt;
        } else {
          return currentStatus;
        }
        
        // If past expiration date, mark as expired and return slot
        if (DateTime.now().isAfter(expirationDate)) {
          await _firestore.collection('subscriptions').doc(subscriptionId).update({
            'status': 'expired',
            'expiredAt': FieldValue.serverTimestamp(),
          });
          
          // Return slot to mentor
          final mentorId = data['mentorId'];
          final planTitle = data['planTitle'];
          if (mentorId != null && planTitle != null) {
            final slotKey = 'slots_${planTitle}_available';
            await _firestore.collection('users').doc(mentorId).update({
              slotKey: FieldValue.increment(1),
            });
          }
          
          return 'expired';
        }
      }
      
      return 'active';
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return 'error';
    }
  }

  /// Check all subscriptions for a user and update statuses
  Future<void> checkUserSubscriptions(String userId) async {
    try {
      final subscriptions = await _firestore
          .collection('subscriptions')
          .where('menteeId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      for (var doc in subscriptions.docs) {
        await checkAndUpdateSubscriptionStatus(doc.id);
      }
    } catch (e) {
      debugPrint('Error checking user subscriptions: $e');
    }
  }

  /// Get subscription status with color and label
  Map<String, dynamic> getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return {
          'label': 'Active',
          'color': const Color(0xFF2D6A65),
          'backgroundColor': const Color(0xFFE8F5F3),
          'icon': Icons.check_circle,
        };
      case 'expired':
        return {
          'label': 'Expired',
          'color': const Color(0xFFE57373),
          'backgroundColor': const Color(0xFFFFEBEE),
          'icon': Icons.event_busy,
        };
      case 'cancelled':
        return {
          'label': 'Cancelled',
          'color': const Color(0xFF9E9E9E),
          'backgroundColor': const Color(0xFFF5F5F5),
          'icon': Icons.cancel,
        };
      default:
        return {
          'label': 'Unknown',
          'color': const Color(0xFF9E9E9E),
          'backgroundColor': const Color(0xFFF5F5F5),
          'icon': Icons.help_outline,
        };
    }
  }

  /// Check if subscription is currently valid (active and not expired)
  Future<bool> isSubscriptionValid(String subscriptionId) async {
    final status = await checkAndUpdateSubscriptionStatus(subscriptionId);
    return status == 'active';
  }

  /// Get days remaining in subscription
  int? getDaysRemaining(dynamic expiresAt) {
    if (expiresAt == null) return null;
    
    DateTime expirationDate;
    if (expiresAt is Timestamp) {
      expirationDate = expiresAt.toDate();
    } else if (expiresAt is DateTime) {
      expirationDate = expiresAt;
    } else {
      return null;
    }
    
    final now = DateTime.now();
    if (expirationDate.isBefore(now)) return 0;
    
    return expirationDate.difference(now).inDays;
  }
}
