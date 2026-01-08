import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:finaproj/app_settings/page/my_subscribers_page.dart';
import 'package:finaproj/membershipPlan/pages/membership_page.dart';
import 'package:finaproj/services/rating_service.dart';

class MentorDashboardPage extends StatelessWidget {
  const MentorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Mentor Dashboard'),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final mentorData = userSnap.data?.data() ?? <String, dynamic>{};

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('subscriptions')
                .where('mentorId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, subsSnap) {
              if (subsSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = subsSnap.data?.docs ??
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              int activeCount = 0;
              int totalCount = docs.length;
              int expiringSoonCount = 0;
              int estimatedMonthlyIncome = 0;

              final now = DateTime.now();
              final soon = now.add(const Duration(days: 7));

              for (final doc in docs) {
                final data = doc.data();
                final status = (data['status'] ?? '').toString().toLowerCase();

                final int planPrice = (data['planPrice'] is int)
                    ? data['planPrice'] as int
                    : int.tryParse((data['planPrice'] ?? '').toString()) ?? 0;

                if (status == 'active') {
                  activeCount += 1;
                  estimatedMonthlyIncome += planPrice;

                  final expiresAt = data['expiresAt'];
                  DateTime? expires;
                  if (expiresAt is Timestamp) {
                    expires = expiresAt.toDate();
                  } else if (expiresAt is DateTime) {
                    expires = expiresAt;
                  }

                  if (expires != null &&
                      expires.isAfter(now) &&
                      expires.isBefore(soon)) {
                    expiringSoonCount += 1;
                  }
                }
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _SectionTitle(title: 'Income'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Est. Monthly',
                          value: '₱$estimatedMonthlyIncome',
                          icon: Icons.payments_outlined,
                          accent: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Active Subs',
                          value: activeCount.toString(),
                          icon: Icons.group_outlined,
                          accent: primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(title: 'Stats'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Subs',
                          value: totalCount.toString(),
                          icon: Icons.receipt_long_outlined,
                          accent: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Expiring (7d)',
                          value: expiringSoonCount.toString(),
                          icon: Icons.schedule_outlined,
                          accent: primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>>(
                    future: RatingService().getMentorRatingStats(user.uid),
                    builder: (context, ratingSnap) {
                      final stats = ratingSnap.data;
                      final avg = (stats?['average'] ?? 0.0).toString();
                      final count = (stats?['count'] ?? 0).toString();

                      return _WideCard(
                        title: 'Ratings',
                        subtitle: '$avg avg • $count reviews',
                        icon: Icons.star_rate_rounded,
                        accent: Colors.amber,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(title: 'More'),
                  const SizedBox(height: 12),
                  _ActionTile(
                    title: 'My Subscribers',
                    icon: Icons.people_alt_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MySubscribersPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    title: 'Manage Plans',
                    icon: Icons.card_membership_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MembershipPage(
                            isMentorView: true,
                            mentorData: {
                              ...mentorData,
                              'uid': user.uid,
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WideCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _WideCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.85)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.35)),
            ],
          ),
        ),
      ),
    );
  }
}
