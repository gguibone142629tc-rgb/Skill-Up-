import 'package:cloud_firestore/cloud_firestore.dart'; // Add this
import 'package:finaproj/common/responsive_layout.dart';
import 'package:finaproj/home_page/model/mentor_model.dart';
import 'package:flutter/material.dart';
import 'mentor_card.dart';

class TopMentorsSection extends StatelessWidget {
  const TopMentorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'Top Mentors',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        // STREAMBUILDER: Pulls data from your "users" collection
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'mentor') // Only show mentors
              .limit(10) // Fetch more to filter out unconfigured mentors
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Unable to load mentors right now.'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No mentors found yet."),
              );
            }

            // Convert Firestore documents into your Mentor model and filter configured mentors
            final allMentors = snapshot.data!.docs.map((doc) {
              return Mentor.fromFirestore(
                  doc.data() as Map<String, dynamic>, doc.id);
            }).toList();
            
            // Only show mentors who have configured at least Plan 1 (price > 0)
            final configuredMentors = allMentors.where((mentor) {
              return mentor.plan1Price != null && mentor.plan1Price! > 0;
            }).toList();
            
            // Sort by rating (highest first)
            configuredMentors.sort((a, b) => b.rating.compareTo(a.rating));
            
            // Take top 5
            final mentors = configuredMentors.take(5).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final spacing = ResponsiveLayout.verticalSpacing(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                );

                final columns = ResponsiveLayout.gridColumns(
                  context,
                  mobile: 1,
                  tablet: 2,
                  desktop: 3,
                );

                final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: mentors
                      .map(
                        (mentor) => SizedBox(
                          width: cardWidth,
                          child: MentorCard(
                            mentor: mentor,
                            margin: EdgeInsets.zero,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
