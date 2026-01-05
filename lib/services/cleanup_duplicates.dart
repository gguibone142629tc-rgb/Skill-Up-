import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// One-time script to remove duplicate subscriptions
Future<void> removeDuplicateSubscriptions() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    debugPrint('🧹 Starting duplicate subscription cleanup...');
    
    // Get all active subscriptions
    final subscriptions = await firestore
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .get();
    
    debugPrint('📊 Found ${subscriptions.docs.length} active subscriptions');
    
    // Group subscriptions by menteeId + mentorId + planTitle
    Map<String, List<QueryDocumentSnapshot>> groupedSubs = {};
    
    for (var doc in subscriptions.docs) {
      final data = doc.data();
      final menteeId = data['menteeId'] ?? '';
      final mentorId = data['mentorId'] ?? '';
      final planTitle = data['planTitle'] ?? '';
      
      final key = '$menteeId-$mentorId-$planTitle';
      
      if (!groupedSubs.containsKey(key)) {
        groupedSubs[key] = [];
      }
      groupedSubs[key]!.add(doc);
    }
    
    debugPrint('👥 Found ${groupedSubs.length} unique subscription combinations');
    
    // Find and remove duplicates (keep oldest subscription per student-mentor pair)
    int removedCount = 0;
    
    for (var entry in groupedSubs.entries) {
      final subs = entry.value;
      
      if (subs.length > 1) {
        debugPrint('⚠️ Found ${subs.length} subscriptions for ${entry.key}');
        
        // Sort by creation date (oldest first)
        subs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>?;
          final bData = b.data() as Map<String, dynamic>?;
          final aDate = (aData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bDate = (bData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return aDate.compareTo(bDate);
        });
        
        // Keep the first one, delete the rest
        for (int i = 1; i < subs.length; i++) {
          final doc = subs[i];
          final data = doc.data() as Map<String, dynamic>?;
          final mentorId = data?['mentorId'];
          final planTitle = data?['planTitle'];
          final menteeName = data?['menteeName'];
          
          debugPrint('🗑️ Deleting duplicate: $menteeName - $planTitle (${doc.id})');
          
          // Delete the duplicate subscription
          await firestore.collection('subscriptions').doc(doc.id).delete();
          
          // Return the slot to the mentor
          if (mentorId != null && planTitle != null) {
            final slotKey = 'slots_${planTitle}_available';
            await firestore.collection('users').doc(mentorId).update({
              slotKey: FieldValue.increment(1),
            });
            debugPrint('✅ Returned 1 slot for $planTitle');
          }
          
          removedCount++;
        }
      }
    }
    
    debugPrint('✨ Cleanup complete! Removed $removedCount duplicate subscriptions.');
  } catch (e, stackTrace) {
    debugPrint('❌ Error removing duplicates: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}
