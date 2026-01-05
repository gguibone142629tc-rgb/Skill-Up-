import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Fresh start - removes all subscriptions and ratings
Future<void> freshStart() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    debugPrint('🔄 Starting fresh start cleanup...');
    
    // Delete all subscriptions
    final subscriptions = await firestore.collection('subscriptions').get();
    int subCount = 0;
    for (var doc in subscriptions.docs) {
      await doc.reference.delete();
      subCount++;
    }
    debugPrint('🗑️ Deleted $subCount subscriptions');
    
    // Delete all ratings
    final ratings = await firestore.collection('ratings').get();
    int ratingCount = 0;
    for (var doc in ratings.docs) {
      await doc.reference.delete();
      ratingCount++;
    }
    debugPrint('🗑️ Deleted $ratingCount ratings');
    
    // Reset mentor ratings to 0
    final mentors = await firestore.collection('users').where('role', isEqualTo: 'mentor').get();
    for (var doc in mentors.docs) {
      await doc.reference.update({
        'averageRating': 0.0,
        'totalRatings': 0,
      });
    }
    debugPrint('✅ Reset all mentor ratings');
    
    debugPrint('✨ Fresh start complete!');
  } catch (e) {
    debugPrint('❌ Error: $e');
  }
}
