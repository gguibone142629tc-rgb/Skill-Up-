import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:finaproj/FindMentor/find_mentor_decor/find_mentor_list.dart';
import 'package:finaproj/home_page/model/mentor_model.dart';

class FindMentorListView extends StatelessWidget {
  final String searchQuery;
  final List<String>? categories; // supports multiple selected categories

  const FindMentorListView({
    super.key,
    required this.searchQuery,
    this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // We fetch all mentors first and filter in memory for flexibility
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'mentor')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 50),
              child: Text("No mentors found."),
            ),
          );
        }

        // 1. Convert Firestore documents to Mentor objects
        final mentors = snapshot.data!.docs.map((doc) {
          return Mentor.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // 2. FILTERING LOGIC
        final filteredMentors = mentors.where((mentor) {
          final query = searchQuery.toLowerCase();
          final name = mentor.name.toLowerCase();
          final job = mentor.jobTitle.toLowerCase();
          
          // Check Search Text
          bool matchesSearch = name.contains(query) || job.contains(query);

          // Check Category (support multiple selected categories with tokenized matching)
          bool matchesCategory = true;
          if (categories != null && categories!.isNotEmpty) {
            matchesCategory = categories!.any((sel) {
              final selNorm = sel.toLowerCase();
              final selTokens = selNorm
                  .split(RegExp(r'[^a-z0-9]+'))
                  .where((t) => t.isNotEmpty)
                  .toList();

              // Check categories with partial and token overlap
              final bool matchInCategories = mentor.categories.any((c) {
                final cNorm = c.toLowerCase();
                if (cNorm.contains(selNorm)) return true;
                final cTokens = cNorm.split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();
                return selTokens.any((t) => cTokens.any((ct) => ct.contains(t)));
              });

              // Check expertise similarly
              final bool matchInExpertise = mentor.expertise.any((e) {
                final eNorm = e.toLowerCase();
                if (eNorm.contains(selNorm)) return true;
                final eTokens = eNorm.split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();
                return selTokens.any((t) => eTokens.any((et) => et.contains(t)));
              });

              // Check skills similarly
              final bool matchInSkills = mentor.skills.any((s) {
                final sNorm = s.toLowerCase();
                if (sNorm.contains(selNorm)) return true;
                final sTokens = sNorm.split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();
                return selTokens.any((t) => sTokens.any((st) => st.contains(t)));
              });

              // Fallback: check job title tokens (e.g., "Software Engineer" matching "Program")
              final bool matchInJob = selTokens.any((t) => mentor.jobTitle.toLowerCase().contains(t));

              return matchInCategories || matchInExpertise || matchInSkills || matchInJob;
            });
          }

          return matchesSearch && matchesCategory;
        }).toList();

        if (filteredMentors.isEmpty) {
          final String message = (categories == null || categories!.isEmpty)
              ? "No matches found."
              : (categories!.length == 1 ? "No mentors in ${categories![0]} yet." : "No mentors in selected categories yet.");

          // Debug logging: when a category filter yields no results, print out the mentors fetched
          // so we can inspect how categories/skills/expertise are stored in Firestore.
          if (categories != null && categories!.isNotEmpty) {
            debugPrint('FindMentor filter debug - selected categories: ${categories}');
            for (final m in mentors) {
              debugPrint('Mentor debug -> name: ${m.name}, id: ${m.id}, job: ${m.jobTitle}, categories: ${m.categories}, expertise: ${m.expertise}, skills: ${m.skills}');
            }
          }

           return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Text(
                message,
                style: const TextStyle(color: Colors.grey)
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredMentors.length,
          itemBuilder: (context, index) {
            return FindMentorList(mentor: filteredMentors[index]);
          },
        );
      },
    );
  }
}