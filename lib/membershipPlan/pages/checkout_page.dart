import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/membership_plan.dart';
import 'package:finaproj/services/notification_service.dart';

class CheckoutPage extends StatefulWidget {
  final MembershipPlan selectedPlan;
  final Map<String, dynamic> mentorData;
  final String planKey; // e.g., Growth_Starter / Career_Accelerator / Executive_Elite

  const CheckoutPage({
    super.key,
    required this.selectedPlan,
    required this.mentorData,
    required this.planKey,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isLoading = false;
  String _selectedPaymentMethod = 'GCash';

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'GCash', 'icon': Icons.account_balance_wallet},
    {'name': 'PayMaya', 'icon': Icons.payment},
    {'name': 'Credit/Debit Card', 'icon': Icons.credit_card},
    {'name': 'Bank Transfer', 'icon': Icons.account_balance},
  ];

  Future<void> _processSubscription() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw 'User not logged in';

      // Check if student already has an active subscription to this specific plan
      final existingSubscription = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('menteeId', isEqualTo: currentUser.uid)
          .where('mentorId', isEqualTo: widget.mentorData['uid'])
          .where('planTitle', isEqualTo: widget.selectedPlan.title)
          .where('status', isEqualTo: 'active')
          .get();

      if (existingSubscription.docs.isNotEmpty) {
        throw 'You are already subscribed to this plan';
      }

      // Check if mentor has available slots
      final mentorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.mentorData['uid'])
          .get();
      
      if (!mentorDoc.exists) throw 'Mentor not found';
      
      final mentorData = mentorDoc.data() as Map<String, dynamic>;
      final selectedPlanTitle = widget.selectedPlan.title;
      final planKey = widget.planKey; // canonical key with underscores
      final selectedSlotKey = 'slots_${planKey}_available';
      final selectedMaxKey = 'slots_${planKey}_max';

      // Fallback: compute availability if fields are missing or stale
      int maxSlots = mentorData[selectedMaxKey] is int
          ? mentorData[selectedMaxKey] as int
          : 10;

      // Count active subscriptions for this mentor & plan
      final activeSubs = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('mentorId', isEqualTo: widget.mentorData['uid'])
          .where('planTitle', isEqualTo: selectedPlanTitle)
          .where('status', isEqualTo: 'active')
          .get();
      final activeCount = activeSubs.docs.length;

      int availableSlots = mentorData[selectedSlotKey] is int
          ? mentorData[selectedSlotKey] as int
          : (maxSlots - activeCount);

      // Keep Firestore in sync if derived value differs
      final correctedAvailable = maxSlots - activeCount;
      if (availableSlots != correctedAvailable) {
        availableSlots = correctedAvailable;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.mentorData['uid'])
            .update({
          selectedSlotKey: correctedAvailable,
          selectedMaxKey: maxSlots,
        });
      }

      if (availableSlots <= 0) {
        throw 'No available slots for this plan. Please try again later.';
      }

      // Get current user's data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>;
      final menteeName =
          '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();

      // Create subscription record
      final now = DateTime.now();
      final expirationDate = now.add(const Duration(days: 30));
      
      await FirebaseFirestore.instance.collection('subscriptions').add({
        'menteeId': currentUser.uid,
        'menteeName': menteeName,
        'mentorId': widget.mentorData['uid'],
        'mentorName':
            '${widget.mentorData['firstName'] ?? ''} ${widget.mentorData['lastName'] ?? ''}',
        'planTitle': widget.selectedPlan.title,
        'planKey': planKey,
        'planPrice': widget.selectedPlan.price,
        'callDetails': widget.selectedPlan.callDetails,
        'features': widget.selectedPlan.features,
        'paymentMethod': _selectedPaymentMethod,
        'status': 'active',
        'startDate': now,
        'expiresAt': expirationDate,
        'createdAt': now,
      });

      // Decrement available slots for the specific plan
      final decrementSlotKey = 'slots_${planKey}_available';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.mentorData['uid'])
          .update({
        decrementSlotKey: FieldValue.increment(-1),
      });

      // Update user's current subscription
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
        'currentSubscription': {
          'mentorId': widget.mentorData['uid'],
          'mentorName':
              '${widget.mentorData['firstName'] ?? ''} ${widget.mentorData['lastName'] ?? ''}',
          'planTitle': widget.selectedPlan.title,
          'planPrice': widget.selectedPlan.price,
          'status': 'active',
        },
      }, SetOptions(merge: true));

      // Send notification to mentor about new subscription
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.mentorData['uid'])
          .collection('notifications')
          .add({
        'userId': widget.mentorData['uid'],
        'title': 'New Subscription!',
        'body': '$menteeName subscribed to your ${widget.selectedPlan.title} plan',
        'type': 'booking',
        'relatedId': currentUser.uid,
        'isRead': false,
        'createdAt': DateTime.now(),
        'data': {
          'menteeId': currentUser.uid,
          'menteeName': menteeName,
          'planTitle': widget.selectedPlan.title,
          'planPrice': widget.selectedPlan.price,
        },
      });

      // Notify mentor (local + inbox)
      await NotificationService().sendSubscriptionCreatedForMentor(
        mentorId: widget.mentorData['uid'],
        menteeName: menteeName,
        planName: widget.selectedPlan.title,
        planPrice: widget.selectedPlan.price,
      );

      // Notify mentee (local + inbox)
      await NotificationService().sendSubscriptionCreatedForMentee(
        menteeId: currentUser.uid,
        mentorName:
            '${widget.mentorData['firstName'] ?? ''} ${widget.mentorData['lastName'] ?? ''}',
        planName: widget.selectedPlan.title,
        planPrice: widget.selectedPlan.price,
      );

      // Send automatic welcome message from mentor to student
      await _sendWelcomeMessage(
        mentorId: widget.mentorData['uid'],
        mentorName:
            '${widget.mentorData['firstName'] ?? ''} ${widget.mentorData['lastName'] ?? ''}',
        mentorEmail: widget.mentorData['email'] ?? 'mentor@email.com',
        studentId: currentUser.uid,
        planTitle: widget.selectedPlan.title,
      );

      // Send notification to student about welcome message
      await NotificationService().sendWelcomeMessageNotification(
        studentId: currentUser.uid,
        mentorId: widget.mentorData['uid'],
        mentorName:
            '${widget.mentorData['firstName'] ?? ''} ${widget.mentorData['lastName'] ?? ''}',
        planName: widget.selectedPlan.title,
      );

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Subscription Successful!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You are now subscribed to ${widget.selectedPlan.title}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your next billing date is ${DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0]}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Close checkout
                        Navigator.of(context).pop(); // Close membership page
                        Navigator.of(context).pop(); // Close mentor profile
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A65),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mentorName =
        '${widget.mentorData['firstName'] ?? ''} ${widget.mentorData['lastName'] ?? ''}'
            .trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mentor',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        mentorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    widget.selectedPlan.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.selectedPlan.callDetails,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...widget.selectedPlan.features.map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $feature',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      )),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monthly Fee',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '₱${widget.selectedPlan.price}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D6A65),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Payment Method
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = method['name'];
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8F5F3) : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2D6A65)
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        method['icon'],
                        color:
                            isSelected ? const Color(0xFF2D6A65) : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          method['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF2D6A65)
                                : Colors.black,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF2D6A65),
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 30),

            // Billing Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFF57F17)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Billing Cycle',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You will be charged ₱${widget.selectedPlan.price} every month starting today.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A65),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Confirm & Pay ₱${widget.selectedPlan.price}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendWelcomeMessage({
    required String mentorId,
    required String mentorName,
    required String mentorEmail,
    required String studentId,
    required String planTitle,
  }) async {
    try {
      // Find or create chat room between mentor and student
      final chatRoomsRef = FirebaseFirestore.instance.collection('chat_rooms');
      
      // Create a unique chat room ID
      final chatRoomId = '$mentorId\_$studentId';
      
      // Check if chat room exists, create if not
      final chatRoomDoc = await chatRoomsRef.doc(chatRoomId).get();
      
      if (!chatRoomDoc.exists) {
        // Create new chat room
        await chatRoomsRef.doc(chatRoomId).set({
          'users': [mentorId, studentId],
          'lastMessage': 'Chat started',
          'lastTimestamp': FieldValue.serverTimestamp(),
          'lastSenderId': mentorId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Send welcome message from mentor with Gmail and request for student's Gmail
      final welcomeMessage = 'Hi! 👋 Welcome to my $planTitle plan! I\'m excited to work with you.\n\n📧 My Email: $mentorEmail\n\nPlease share your Gmail address so we can schedule calls via Google Meet. Feel free to reach out anytime you have questions or need guidance. Let\'s make this a great learning experience!';
      
      await chatRoomsRef
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': mentorId,
        'text': welcomeMessage,
        'imageUrl': '',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'reaction': '',
      });
      
      // Update chat room with latest message
      await chatRoomsRef.doc(chatRoomId).update({
        'lastMessage': welcomeMessage,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'lastSenderId': mentorId,
      });
      
      debugPrint('Welcome message sent from $mentorName to student');
    } catch (e) {
      debugPrint('Error sending welcome message: $e');
      // Don't throw - subscription should succeed even if message fails
    }
  }
}
