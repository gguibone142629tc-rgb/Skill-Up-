import 'package:finaproj/common/loading_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finaproj/FindMentor/find_mentor_decor/find_mentor_list.dart';
import 'package:finaproj/common/mentor_avatar.dart';
import 'package:finaproj/common/responsive_layout.dart';
import 'package:finaproj/Profile_page/pages/student_profile_view.dart';
import 'package:finaproj/app_settings/page/profile_page.dart';
import 'package:finaproj/home_page/model/mentor_model.dart';
import 'package:finaproj/membershipPlan/model/membership_plan.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FindMentorListView extends StatelessWidget {
  final String searchQuery;
  final List<String>? categories; // supports multiple selected categories
  final bool hideStudents;
  final bool hideMentors;
  final String sortBy;

  const FindMentorListView({
    super.key,
    required this.searchQuery,
    this.categories,
    this.hideStudents = false,
    this.hideMentors = false,
    this.sortBy = 'default',
  });

  // Helper function to get actual price for sorting (same priority as display)
  int _getMentorPrice(Mentor mentor) {
    if (mentor.plan1Price != null && mentor.plan1Price! > 0) {
      return mentor.plan1Price!;
    }
    if (mentor.planPrice != null && mentor.planPrice! > 0) {
      return mentor.planPrice!;
    }
    if (mentor.planTitle != null && mentor.planTitle!.isNotEmpty) {
      return MembershipPlan.getPriceForTitle(mentor.planTitle);
    }
    final parsed =
        int.tryParse(mentor.pricePerMonth.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsed != null && parsed > 0) {
      return parsed;
    }
    return MembershipPlan.defaultStartingPrice;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = ResponsiveLayout.verticalSpacing(
      context,
      mobile: 20,
      tablet: 28,
      desktop: 36,
    );

    return StreamBuilder<QuerySnapshot>(
      // Fetch both mentors and students
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        Widget content;

        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
          return ResponsiveLayout.constrain(context: context, child: content);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          content = const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 50),
              child: Text("No users found."),
            ),
          );
          return ResponsiveLayout.constrain(context: context, child: content);
        }

        // 1. Convert Firestore documents to Mentor objects (for mentors) or get student data
        final allUsers = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final role = data['role'] ?? '';
          return role == 'mentor' || role == 'student';
        }).toList();

        final mentors = allUsers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['role'] == 'mentor';
        }).map((doc) {
          return Mentor.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        final students = allUsers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['role'] == 'student';
        }).toList();

        // 2. FILTERING LOGIC
        var filteredMentors = mentors.where((mentor) {
          final query = searchQuery.toLowerCase().trim();

          // If no search query, apply only category filter
          if (query.isEmpty) {
            // If no categories selected, show all mentors
            if (categories == null || categories!.isEmpty) {
              return true;
            }

            // Otherwise, apply category filter
            return categories!.any((sel) {
              final selNorm = sel.toLowerCase();
              final selTokens = selNorm
                  .split(RegExp(r'[^a-z0-9]+'))
                  .where((t) => t.isNotEmpty)
                  .toList();

              final bool matchInCategories = mentor.categories.any((c) {
                final cNorm = c.toLowerCase();
                if (cNorm.contains(selNorm)) return true;
                final cTokens = cNorm
                    .split(RegExp(r'[^a-z0-9]+'))
                    .where((t) => t.isNotEmpty)
                    .toList();
                return selTokens
                    .any((t) => cTokens.any((ct) => ct.contains(t)));
              });

              final bool matchInExpertise = mentor.expertise.any((e) {
                final eNorm = e.toLowerCase();
                if (eNorm.contains(selNorm)) return true;
                final eTokens = eNorm
                    .split(RegExp(r'[^a-z0-9]+'))
                    .where((t) => t.isNotEmpty)
                    .toList();
                return selTokens
                    .any((t) => eTokens.any((et) => et.contains(t)));
              });

              final bool matchInSkills = mentor.skills.any((s) {
                final sNorm = s.toLowerCase();
                if (sNorm.contains(selNorm)) return true;
                final sTokens = sNorm
                    .split(RegExp(r'[^a-z0-9]+'))
                    .where((t) => t.isNotEmpty)
                    .toList();
                return selTokens
                    .any((t) => sTokens.any((st) => st.contains(t)));
              });

              final bool matchInJob = selTokens
                  .any((t) => mentor.jobTitle.toLowerCase().contains(t));

              return matchInCategories ||
                  matchInExpertise ||
                  matchInSkills ||
                  matchInJob;
            });
          }

          // Search query is not empty
          final name = mentor.name.toLowerCase();
          final job = mentor.jobTitle.toLowerCase();

          // Check Search Text (match in name or job)
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

              final bool matchInCategories = mentor.categories.any((c) {
                final cNorm = c.toLowerCase();
                if (cNorm.contains(selNorm)) return true;
                final cTokens = cNorm
                    .split(RegExp(r'[^a-z0-9]+'))
                    .where((t) => t.isNotEmpty)
                    .toList();
                return selTokens
                    .any((t) => cTokens.any((ct) => ct.contains(t)));
              });

              final bool matchInExpertise = mentor.expertise.any((e) {
                final eNorm = e.toLowerCase();
                if (eNorm.contains(selNorm)) return true;
                final eTokens = eNorm
                    .split(RegExp(r'[^a-z0-9]+'))
                    .where((t) => t.isNotEmpty)
                    .toList();
                return selTokens
                    .any((t) => eTokens.any((et) => et.contains(t)));
              });

              final bool matchInSkills = mentor.skills.any((s) {
                final sNorm = s.toLowerCase();
                if (sNorm.contains(selNorm)) return true;
                final sTokens = sNorm
                    .split(RegExp(r'[^a-z0-9]+'))
                    .where((t) => t.isNotEmpty)
                    .toList();
                return selTokens
                    .any((t) => sTokens.any((st) => st.contains(t)));
              });

              final bool matchInJob = selTokens
                  .any((t) => mentor.jobTitle.toLowerCase().contains(t));

              return matchInCategories ||
                  matchInExpertise ||
                  matchInSkills ||
                  matchInJob;
            });
          }

          return matchesSearch && matchesCategory;
        }).toList();

        var filteredStudents = students.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final query = searchQuery.toLowerCase();

          // If search query is empty, show all students (unless categories filter applies)
          if (query.isEmpty) {
            // For students, categories don't apply, so always show them if no search query
            return true;
          }

          final firstName = (data['firstName'] ?? '').toString().toLowerCase();
          final lastName = (data['lastName'] ?? '').toString().toLowerCase();
          final fullName = '$firstName $lastName'.trim().toLowerCase();
          final location = (data['location'] ?? '').toString().toLowerCase();

          // Search in name (first, last, full) and location
          return fullName.contains(query) ||
              firstName.contains(query) ||
              lastName.contains(query) ||
              location.contains(query);
        }).toList();

        // If requested to hide students or mentors, filter accordingly
        if (hideStudents) {
          filteredStudents = [];
        }
        if (hideMentors) {
          filteredMentors.clear();
        }

        // Apply sorting
        switch (sortBy) {
          case 'rating':
            filteredMentors.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case 'price_low':
            filteredMentors.sort((a, b) {
              final aPrice = _getMentorPrice(a);
              final bPrice = _getMentorPrice(b);
              return aPrice.compareTo(bPrice);
            });
            break;
          case 'price_high':
            filteredMentors.sort((a, b) {
              final aPrice = _getMentorPrice(a);
              final bPrice = _getMentorPrice(b);
              return bPrice.compareTo(aPrice);
            });
            break;
          case 'default':
          default:
            // Keep default order
            break;
        }

        // Combine results (mentors first, then students)
        final combinedCount = filteredMentors.length + filteredStudents.length;

        if (combinedCount == 0) {
          content = Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Text(
                searchQuery.isEmpty ? "No users found." : "No matches found.",
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
          return ResponsiveLayout.constrain(context: context, child: content);
        }

        content = ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.only(bottom: bottomInset),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: combinedCount,
          itemBuilder: (context, index) {
            if (index < filteredMentors.length) {
              return FindMentorList(mentor: filteredMentors[index]);
            } else {
              final studentIndex = index - filteredMentors.length;
              final studentData =
                  filteredStudents[studentIndex].data() as Map<String, dynamic>;
              return StudentSearchCard(
                  studentData: studentData,
                  studentId: filteredStudents[studentIndex].id);
            }
          },
        );

        return ResponsiveLayout.constrain(context: context, child: content);
      },
    );
  }
}

// Student Search Card Widget
class StudentSearchCard extends StatelessWidget {
  final Map<String, dynamic> studentData;
  final String studentId;

  const StudentSearchCard({
    super.key,
    required this.studentData,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final side = ResponsiveLayout.horizontalPadding(context);
    final vertical = ResponsiveLayout.verticalSpacing(context,
        mobile: 10, tablet: 12, desktop: 14);
    final firstName = studentData['firstName'] ?? 'Student';
    final lastName = studentData['lastName'] ?? '';
    final fullName = '$firstName $lastName';
    final location = studentData['location'] ?? 'Remote';
    final profileImage = (studentData['profileImageUrl'] ??
            studentData['photoUrl'] ??
            studentData['photoURL'] ??
            '')
        .toString();
    final interests = List<String>.from(studentData['interests'] ?? []);
    final goals = List<String>.from(studentData['goals'] ?? []);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: side, vertical: vertical),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 5,
              offset: const Offset(0, 5),
            )
          ]),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Avatar, Name, Rating Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                MentorAvatar(
                  name: fullName,
                  image: profileImage,
                  size: 64,
                ),
                const SizedBox(width: 12),
                // Name & Job
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Student',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Row 2: Interests
            if (interests.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: interests.take(2).map((interest) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      interest,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            if (interests.isEmpty)
              Text(
                'No interests listed',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            const SizedBox(height: 12),
            // Row 3: Goals
            if (goals.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Goals',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    goals.take(2).join(', '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            else
              Text(
                'No goals listed',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            const SizedBox(height: 16),
            // View Profile Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  final isOwnProfile = studentId == currentUserId;

                  if (isOwnProfile) {
                    // Navigate to own profile page (from nav bar)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  } else {
                    // Navigate to other student's profile
                    LoadingDialog.navigateWithLoader(
                      context,
                      StudentProfileView(studentId: studentId),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A65),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                child: const Text(
                  "View Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
