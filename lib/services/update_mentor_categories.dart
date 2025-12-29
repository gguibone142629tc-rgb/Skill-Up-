import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateMentorCategoriesService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Update specific mentors with categories
  /// This adds "eman godz" and "lance" to Technology category
  static Future<void> updateMentorCategories() async {
    try {
      // Update Eman Godz with Technology category
      await _db
          .collection('users')
          .where('firstName', isEqualTo: 'Eman')
          .where('lastName', isEqualTo: 'Godz')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({
            'categories': FieldValue.arrayUnion(['Technology'])
          });
        }
      });

      // Update Lance with Technology category
      await _db
          .collection('users')
          .where('firstName', isEqualTo: 'Lance')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({
            'categories': FieldValue.arrayUnion(['Technology'])
          });
        }
      });

      print('✅ Successfully updated mentor categories!');
    } catch (e) {
      print('❌ Error updating mentor categories: $e');
      rethrow;
    }
  }

  /// Alternative: Update by mentor UID if you know it
  static Future<void> updateMentorCategoriesByUid(
      String uid, List<String> categories) async {
    try {
      await _db.collection('users').doc(uid).update({
        'categories': categories,
      });
      print('✅ Successfully updated mentor with UID: $uid');
    } catch (e) {
      print('❌ Error updating mentor: $e');
      rethrow;
    }
  }
}
