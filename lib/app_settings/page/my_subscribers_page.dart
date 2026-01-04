import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MySubscribersPage extends StatelessWidget {
  const MySubscribersPage({super.key});

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
          // Get mentor's slot data
          final mentorData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final maxSlots = mentorData?['planMaxSlots'] ?? 10;
          final availableSlots = mentorData?['planAvailableSlots'] ?? maxSlots;
          final usedSlots = maxSlots - availableSlots;

          return Column(
            children: [
              // Slot counter card at the top
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D6A65), Color(0xFF3D8A7D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSlotInfo(
                      icon: Icons.people,
                      label: 'Total Slots',
                      value: '$maxSlots',
                      color: Colors.white,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildSlotInfo(
                      icon: Icons.check_circle,
                      label: 'Used',
                      value: '$usedSlots',
                      color: Colors.white,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildSlotInfo(
                      icon: Icons.event_available,
                      label: 'Available',
                      value: '$availableSlots',
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
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
                            Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
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
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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

                        final menteeName = data['menteeName'] ?? 'Student';
                        final planTitle = data['planTitle'] ?? 'Plan';
                        final planPrice = data['planPrice'] ?? 0;

              DateTime? startDate;
              if (data['startDate'] != null) {
                if (data['startDate'] is Timestamp) {
                  startDate = (data['startDate'] as Timestamp).toDate();
                } else if (data['startDate'] is DateTime) {
                  startDate = data['startDate'] as DateTime;
                }
              }

              DateTime? nextBillingDate;
              if (data['nextBillingDate'] != null) {
                if (data['nextBillingDate'] is Timestamp) {
                  nextBillingDate =
                      (data['nextBillingDate'] as Timestamp).toDate();
                } else if (data['nextBillingDate'] is DateTime) {
                  nextBillingDate = data['nextBillingDate'] as DateTime;
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  menteeName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  planTitle,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                            crossAxisAlignment: CrossAxisAlignment.end,
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

  Widget _buildSlotInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
