import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finaproj/services/subscription_service.dart';

class MySubscribersPage extends StatefulWidget {
  const MySubscribersPage({super.key});

  @override
  State<MySubscribersPage> createState() => _MySubscribersPageState();
}

class _MySubscribersPageState extends State<MySubscribersPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    _checkMentorSubscriptions();
  }

  Future<void> _checkMentorSubscriptions() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Runs once on page open to ensure expired subscriptions are marked as expired.
    await _subscriptionService.checkMentorSubscriptions(currentUser.uid);
  }

  Future<void> _debugForceExpire(
      BuildContext context, String subscriptionId) async {
    final result = await _subscriptionService.forceExpireNow(subscriptionId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Force expire result: $result')),
    );

    // Re-check list so expired ones drop out immediately.
    await _checkMentorSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Subscribers'),
        ),
        body: const Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Subscribers",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          return Column(
            children: [
              // Subscribers list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('subscriptions')
                      .where('mentorId', isEqualTo: currentUser.uid)
                      .where('status', isEqualTo: 'active')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 20),
                            Text(
                              "No active subscribers yet",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Students who subscribe to your plans will appear here",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final subscriptionId = doc.id;

                        final menteeName = data['menteeName'] ?? 'Student';
                        final planPrice = data['planPrice'] ?? 0;
                        final status = data['status'] ?? 'active';
                        final statusInfo =
                            _subscriptionService.getStatusInfo(status);
                        final daysRemaining = _subscriptionService
                            .getDaysRemaining(data['expiresAt']);

                        DateTime? startDate;
                        if (data['startDate'] != null) {
                          if (data['startDate'] is Timestamp) {
                            startDate =
                                (data['startDate'] as Timestamp).toDate();
                          } else if (data['startDate'] is DateTime) {
                            startDate = data['startDate'] as DateTime;
                          }
                        }

                        // We don't always persist `nextBillingDate` in Firestore.
                        // Fallback to `expiresAt` which is stored for 30-day billing cycles.
                        DateTime? nextBillingDate;
                        final nextBillingRaw =
                            data['nextBillingDate'] ?? data['expiresAt'];
                        if (nextBillingRaw != null) {
                          if (nextBillingRaw is Timestamp) {
                            nextBillingDate = nextBillingRaw.toDate();
                          } else if (nextBillingRaw is DateTime) {
                            nextBillingDate = nextBillingRaw;
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: const Color(0xFF2D6A65),
                                      child: Text(
                                        menteeName.isNotEmpty
                                            ? menteeName[0].toUpperCase()
                                            : 'S',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            menteeName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Expires',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                                    const SizedBox(width: 8),
                                    IconButton(
                                      tooltip: 'Force expire',
                                      icon: const Icon(
                                          Icons.bug_report_outlined,
                                          size: 20),
                                      onPressed: () => _debugForceExpire(
                                          context, subscriptionId),
                                    ),
                                  ],
                                ),

                                // Days Remaining (only for active subscriptions)
                                if (status == 'active' &&
                                    daysRemaining != null) ...[
                                  const SizedBox(height: 12),
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
                                ],

                                const SizedBox(height: 12),

                                // Price Badge
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5F3),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '₱$planPrice/mo',
                                        style: const TextStyle(
                                          color: Color(0xFF2D6A65),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Started',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          startDate != null
                                              ? DateFormat('MMM dd, yyyy')
                                                  .format(startDate)
                                              : 'N/A',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Next Billing',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          nextBillingDate != null
                                              ? DateFormat('MMM dd, yyyy')
                                                  .format(nextBillingDate)
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
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
