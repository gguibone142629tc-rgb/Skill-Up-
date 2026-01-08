import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:finaproj/services/subscription_service.dart';

class MySubscriptionsPage extends StatefulWidget {
  const MySubscriptionsPage({super.key});

  @override
  State<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    _checkSubscriptions();
  }

  Future<void> _checkSubscriptions() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await _subscriptionService.checkUserSubscriptions(currentUser.uid);
      if (mounted) setState(() {});
    }
  }

  Future<void> _cancelSubscription(
      BuildContext context, String subscriptionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            kDebugMode ? 'Expire Subscription (Debug)' : 'Cancel Subscription'),
        content: Text(
          kDebugMode
              ? 'This will force-expire your subscription now so you can test the expired flow.'
              : 'Are you sure you want to cancel this subscription? You will lose access at the end of your current billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(kDebugMode ? 'Yes, Expire Now' : 'Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (kDebugMode) {
          final result = await _subscriptionService.forceExpireNow(
            subscriptionId,
            sendNotification: true,
          );

          // Keep user's current subscription in sync for UI.
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .update({
              'currentSubscription.status': 'expired',
            });
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Subscription expired for testing ($result)')),
            );
          }
          return;
        }

        // Get subscription data to retrieve mentor ID and plan title
        final subscriptionDoc = await FirebaseFirestore.instance
            .collection('subscriptions')
            .doc(subscriptionId)
            .get();

        final subscriptionData = subscriptionDoc.data();
        final mentorId = subscriptionData?['mentorId'];
        final planKey = subscriptionData?['planKey'];
        final planTitle = subscriptionData?['planTitle'];

        // Update subscription status
        await FirebaseFirestore.instance
            .collection('subscriptions')
            .doc(subscriptionId)
            .update({'status': 'cancelled'});

        // Increment mentor's available slots back for the specific plan
        final String? slotPlanKey = (planKey is String && planKey.isNotEmpty)
            ? planKey
            : (planTitle is String && planTitle.isNotEmpty)
                ? planTitle.replaceAll(RegExp(r'\s+'), '_')
                : null;

        if (mentorId != null && slotPlanKey != null) {
          final slotKey = 'slots_${slotPlanKey}_available';
          await FirebaseFirestore.instance
              .collection('users')
              .doc(mentorId)
              .update({
            slotKey: FieldValue.increment(1),
          });
        }

        // Also update user's current subscription
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'currentSubscription.status': 'cancelled',
          });
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Subscription cancelled successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Subscriptions'),
        ),
        body: const Center(child: Text('Please log in to view subscriptions')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Subscriptions',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subscriptions')
            .where('menteeId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.subscriptions_outlined,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No subscriptions yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Subscribe to a mentor to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'active';
              // For student-facing UI, treat "cancelled" as "expired" so it matches the
              // expected end-of-access experience.
              final displayStatus = status == 'cancelled' ? 'expired' : status;
              final isActive = displayStatus == 'active';
              final statusInfo =
                  _subscriptionService.getStatusInfo(displayStatus);
              final daysRemaining =
                  _subscriptionService.getDaysRemaining(data['expiresAt']);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: status == 'active'
                        ? const Color(0xFF2D6A65)
                        : Colors.grey[300]!,
                    width: status == 'active' ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge and Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusInfo['backgroundColor'],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusInfo['icon'],
                                  size: 14,
                                  color: statusInfo['color'],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusInfo['label'].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusInfo['color'],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₱${data['planPrice']}/month',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D6A65),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Days Remaining (only for active subscriptions)
                      if (status == 'active' && daysRemaining != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: daysRemaining <= 7
                                ? const Color(0xFFFFF3E0)
                                : const Color(0xFFE8F5F3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: daysRemaining <= 7
                                    ? const Color(0xFFF57C00)
                                    : const Color(0xFF2D6A65),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$daysRemaining day${daysRemaining == 1 ? '' : 's'} remaining',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: daysRemaining <= 7
                                      ? const Color(0xFFF57C00)
                                      : const Color(0xFF2D6A65),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Plan Title
                      Text(
                        data['planTitle'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Mentor Name
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Mentor: ${data['mentorName'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Call Details
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['callDetails'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Features
                      if (data['features'] != null) ...[
                        const Text(
                          'Features:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...List<String>.from(data['features']).map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $feature',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Billing Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['startDate'] != null
                                    ? DateFormat('MMM dd, yyyy').format(
                                        (data['startDate'] as Timestamp)
                                            .toDate())
                                    : 'N/A',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (isActive)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Expires',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['expiresAt'] != null
                                      ? DateFormat('MMM dd, yyyy').format(
                                          (data['expiresAt'] as Timestamp)
                                              .toDate())
                                      : 'N/A',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Cancel Button (only for active subscriptions)
                      if (status == 'active') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () =>
                                _cancelSubscription(context, doc.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel Subscription'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
