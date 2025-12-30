import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. CLOUDINARY CONFIG
  final String cloudName = 'dagnamipk';
  final String uploadPreset = 'skillup_preset';

  // --- 1. PROFILE MANAGEMENT ---

  Future<void> saveMentorProfile({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required String company,
    required String location,
    required String gender,
    required int yearsExp,
    required int monthsExp,
    required String bio,
    required List<String> skills,
    required List<String> expertise,
    XFile? profileImage,
  }) async {
    try {
      String imageUrl = '';
      if (profileImage != null) {
        imageUrl = await _uploadToCloudinary(profileImage);
      }

      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'role': 'mentor',
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': '$firstName $lastName',
        'jobTitle': jobTitle,
        'company': company,
        'location': location,
        'gender': gender,
        'yearsExperience': yearsExp,
        'monthsExperience': monthsExp,

        // ✅ These are the keys your Profile Page looks for:
        'bio': bio,
        'skills': skills,
        'expertise': expertise,

        'profileImageUrl': imageUrl,
        // Saving 'profilePic' as duplicate for safety if other widgets use it
        'profilePic': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'rating': 5.0,
        'price': 'Free',
      });
    } catch (e) {
      debugPrint("Error saving mentor profile: $e");
      rethrow;
    }
  }

  Future<void> saveStudentProfile({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    required String gender,
    XFile? profileImage,
  }) async {
    try {
      String imageUrl = '';
      if (profileImage != null) {
        imageUrl = await _uploadToCloudinary(profileImage);
      }

      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': '$firstName $lastName',
        'gender': gender,
        'role': 'student',
        'profileImageUrl': imageUrl,
        'profilePic': imageUrl, // Duplicate for safety
        'createdAt': FieldValue.serverTimestamp(),
        'bio': 'Learning and growing.',
        'location': 'Remote',
      });
    } catch (e) {
      debugPrint("Firestore Save Error: $e");
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required String location,
    required String bio,
    XFile? newImage,
  }) async {
    try {
      Map<String, dynamic> dataToUpdate = {
        'firstName': firstName,
        'lastName': lastName,
        'fullName': '$firstName $lastName',
        'jobTitle': jobTitle,
        'location': location,
        'bio': bio,
      };

      if (newImage != null) {
        String newUrl = await _uploadToCloudinary(newImage);
        if (newUrl.isNotEmpty) {
          dataToUpdate['profileImageUrl'] = newUrl;
          dataToUpdate['profilePic'] = newUrl;
        }
      }

      await _db.collection('users').doc(uid).update(dataToUpdate);
    } catch (e) {
      debugPrint("Error updating profile: $e");
      rethrow;
    }
  }

  // --- 2. DATA RETRIEVAL ---

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      return null;
    }
  }

  Stream<QuerySnapshot> getMentors() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'mentor')
        .snapshots();
  }

  // --- 3. MESSAGING LOGIC ---

  Future<String> getChatRoomId(String user1, String user2) async {
    List<String> ids = [user1, user2];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _db.collection('chat_rooms').doc(chatRoomId).set({
      'users': ids,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatRoomId;
  }

  Future<void> sendMessage(
      String chatRoomId, String senderId, String text) async {
    if (text.trim().isEmpty) return;

    try {
      // 1. Save the message to the sub-collection
      await _db
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update the parent room doc to fix the blank "Message Page" preview
      await _db.collection('chat_rooms').doc(chatRoomId).set({
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("✅ Chat preview updated in Firestore");
    } catch (e) {
      debugPrint("❌ Error sending message: $e");
    }
  }

  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // --- 4. BOOKINGS ---

  Future<void> createBooking({
    required String menteeId,
    required String mentorId,
    required String mentorName,
    required DateTime selectedDate,
    required String status,
  }) async {
    try {
      await _db.collection('bookings').add({
        'menteeId': menteeId,
        'mentorId': mentorId,
        'mentorName': mentorName,
        'bookingDate': selectedDate,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error creating booking: $e");
      rethrow;
    }
  }

  // --- 5. SAVED MENTORS ---

  Future<void> saveMentor(String userId, String mentorId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('savedMentors')
          .doc(mentorId)
          .set({
        'mentorId': mentorId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving mentor: $e");
      rethrow;
    }
  }

  Future<void> unsaveMentor(String userId, String mentorId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('savedMentors')
          .doc(mentorId)
          .delete();
    } catch (e) {
      debugPrint("Error unsaving mentor: $e");
      rethrow;
    }
  }

  Future<bool> isMentorSaved(String userId, String mentorId) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('savedMentors')
          .doc(mentorId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint("Error checking saved status: $e");
      return false;
    }
  }

  Stream<QuerySnapshot> getSavedMentors(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('savedMentors')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }

  Stream<List<Map<String, dynamic>>> getSavedMentorsDetails(
      String userId) async* {
    await for (var snapshot in getSavedMentors(userId)) {
      List<Map<String, dynamic>> mentors = [];

      for (var doc in snapshot.docs) {
        String mentorId = doc['mentorId'];
        var mentorDoc = await _db.collection('users').doc(mentorId).get();

        if (mentorDoc.exists) {
          var mentorData = mentorDoc.data() as Map<String, dynamic>;
          mentorData['id'] = mentorId;
          mentors.add(mentorData);
        }
      }

      yield mentors;
    }
  }

  // --- 6. PRIVATE CLOUDINARY HELPER ---

  Future<String> _uploadToCloudinary(XFile image) async {
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset;

      // 🟢 WEB-SAFE: Use readAsBytes instead of File
      final Uint8List fileBytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: image.name,
      ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        debugPrint("❌ CLOUDINARY ERROR: ${jsonResponse['error']['message']}");
        return '';
      }
    } catch (e) {
      debugPrint("❌ HTTP Error: $e");
      return '';
    }
  }
}
