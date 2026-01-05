import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'rating_model.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if student is subscribed to mentor (current or past)
  Future<bool> canRateMentor(String mentorId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final subscription = await _firestore
          .collection('subscriptions')
          .where('menteeId', isEqualTo: userId)
          .where('mentorId', isEqualTo: mentorId)
          .get();

      return subscription.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if student already rated this mentor
  Future<bool> hasRatedMentor(String mentorId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final existing = await _firestore
          .collection('ratings')
          .where('mentorId', isEqualTo: mentorId)
          .where('studentId', isEqualTo: userId)
          .get();

      return existing.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Submit a rating for a mentor
  Future<void> submitRating({
    required String mentorId,
    required double rating,
    required String comment,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw 'User not authenticated';

    // Get student name
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    final studentName =
        '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'
            .trim();

    // Create rating object
    final newRating = MentorRating(
      id: '', // Will be set by Firestore
      mentorId: mentorId,
      studentId: userId,
      studentName: studentName.isEmpty ? 'Anonymous' : studentName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    // Add rating to Firestore
    await _firestore.collection('ratings').add(newRating.toMap());

    // Update mentor's average rating
    await _updateMentorAverageRating(mentorId);
  }

  /// Update a mentor's average rating
  Future<void> _updateMentorAverageRating(String mentorId) async {
    final ratings = await _firestore
        .collection('ratings')
        .where('mentorId', isEqualTo: mentorId)
        .get();

    if (ratings.docs.isEmpty) return;

    double sum = 0;
    for (var doc in ratings.docs) {
      sum += (doc.data()['rating'] ?? 0).toDouble();
    }

    double average = sum / ratings.docs.length;

    // Update mentor's rating in users collection
    await _firestore.collection('users').doc(mentorId).update({
      'rating': double.parse(average.toStringAsFixed(1)),
      'totalRatings': ratings.docs.length,
    });
  }

  /// Get all ratings for a mentor
  Stream<List<MentorRating>> getMentorRatings(String mentorId) {
    return _firestore
        .collection('ratings')
        .where('mentorId', isEqualTo: mentorId)
        .snapshots()
        .map((snapshot) {
      debugPrint('Fetching ratings for mentor: $mentorId');
      debugPrint('Found ${snapshot.docs.length} rating documents');
      
      final ratings = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          debugPrint('Rating data: $data');
          return MentorRating.fromMap(doc.id, data);
        } catch (e) {
          debugPrint('Error parsing rating: $e');
          rethrow;
        }
      }).toList();
      
      // Sort by date in memory (newest first)
      ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return ratings;
    }).handleError((error) {
      debugPrint('Error fetching ratings: $error');
      return <MentorRating>[];
    });
  }

  /// Get average rating for a mentor
  Future<Map<String, dynamic>> getMentorRatingStats(String mentorId) async {
    final ratings = await _firestore
        .collection('ratings')
        .where('mentorId', isEqualTo: mentorId)
        .get();

    if (ratings.docs.isEmpty) {
      return {'average': 0.0, 'count': 0};
    }

    double sum = 0;
    for (var doc in ratings.docs) {
      sum += (doc.data()['rating'] ?? 0).toDouble();
    }

    double average = sum / ratings.docs.length;

    return {
      'average': double.parse(average.toStringAsFixed(1)),
      'count': ratings.docs.length,
    };
  }
}
