import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/membership_plan.dart';

class CheckoutPage extends StatefulWidget {
  final MembershipPlan selectedPlan;
  final Map<String, dynamic> mentorData;

  const CheckoutPage({
    super.key,
    required this.selectedPlan,
    required this.mentorData,
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
      await FirebaseFirestore.instance.collection('subscriptions').add({
        'menteeId': currentUser.uid,
        'menteeName': menteeName,
        'mentorId': widget.mentorData['uid'],
        'mentorName':
            '${widget.mentorData['firstName'] ?? ''} ${widget.mentorData['lastName'] ?? ''}',
        'planTitle': widget.selectedPlan.title,
        'planPrice': widget.selectedPlan.price,
        'callDetails': widget.selectedPlan.callDetails,
        'features': widget.selectedPlan.features,
        'paymentMethod': _selectedPaymentMethod,
        'status': 'active',
        'startDate': now,
        'nextBillingDate': now.add(const Duration(days: 30)),
        'createdAt': now,
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

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text('Subscription Successful!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are now subscribed to ${widget.selectedPlan.title}'),
                const SizedBox(height: 8),
                Text(
                  'Your next billing date is ${DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0]}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close checkout
                  Navigator.of(context).pop(); // Close membership page
                  Navigator.of(context).pop(); // Close mentor profile
                },
                child: const Text('Done'),
              ),
            ],
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
}
