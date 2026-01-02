import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finaproj/common/auth_text_field.dart';
import 'package:finaproj/membershipPlan/model/membership_plan.dart';
import 'package:finaproj/membershipPlan/pages/checkout_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/plan_card.dart';

class MembershipPage extends StatefulWidget {
  final bool isMentorView;
  final Map<String, dynamic>? mentorData; // ✅ Added this back to fix the error

  const MembershipPage({
    super.key,
    this.isMentorView = false,
    this.mentorData, // ✅ Added this back
  });

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  int selectedIndex = 1;

  // Plans - will be updated with mentor's custom pricing if viewing as student
  late List<MembershipPlan> plans;

  @override
  void initState() {
    super.initState();
    _initializePlans();
  }

  Future<void> _initializePlans() async {
    // Get mentor's custom price if available
    String? mentorCustomPrice = widget.mentorData?['price'];
    String? mentorPlanTitle = widget.mentorData?['planTitle'];
    String? mentorCallDetails = widget.mentorData?['planCallDetails'];
    List<String>? mentorFeatures;

    // If mentor is viewing their own plans, load from Firestore
    if (widget.isMentorView) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          final data = doc.data();
          if (data != null) {
            mentorCustomPrice = data['price'];
            mentorPlanTitle = data['planTitle'];
            mentorCallDetails = data['planCallDetails'];
            if (data['planFeatures'] != null) {
              mentorFeatures = List<String>.from(data['planFeatures']);
            }
          }
        } catch (e) {
          debugPrint("Error loading mentor data: $e");
        }
      }
    }

    // Base plans with default prices
    plans = [
      MembershipPlan(
        title: "Growth Starter",
        callDetails: "1x 45-min call per month",
        features: ["Basic email support"],
        price: 1200,
      ),
      MembershipPlan(
        title: "Career Accelerator",
        callDetails: "4x 30-min call per month",
        features: ["Priority in-app messaging", "Document Review"],
        price: 2500,
      ),
      MembershipPlan(
        title: "Executive Elite",
        callDetails: "Unlimited calls",
        features: ["Direct chat access", "Resume/ Profile optimization"],
        price: 4000,
      ),
    ];

    // If mentor has custom pricing, update the corresponding plan
    if (mentorCustomPrice != null) {
      final customPrice = int.tryParse(mentorCustomPrice.toString()) ?? 0;
      if (customPrice > 0) {
        // Find which plan matches the mentor's selected plan title
        for (int i = 0; i < plans.length; i++) {
          if (mentorPlanTitle != null &&
              plans[i].title.toLowerCase() == mentorPlanTitle.toLowerCase()) {
            // Update the plan with custom data
            plans[i] = MembershipPlan(
              title: plans[i].title,
              callDetails: mentorCallDetails ?? plans[i].callDetails,
              features: mentorFeatures ?? plans[i].features,
              price: customPrice,
            );
            break;
          }
        }
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  // --- EDIT LOGIC ---
  void _showEditSheet(MembershipPlan selectedPlan) async {
    // Load mentor's current saved plan data from Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    Map<String, dynamic>? savedData;
    
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        savedData = doc.data();
      } catch (e) {
        debugPrint("Error loading mentor data: $e");
      }
    }

    // Pre-fill with mentor's saved data if available, otherwise use default plan data
    final titleCtrl = TextEditingController(
        text: savedData?['planTitle'] ?? selectedPlan.title);
    final priceCtrl = TextEditingController(
        text: savedData?['price']?.toString() ?? selectedPlan.price.toString());
    final callCtrl = TextEditingController(
        text: savedData?['planCallDetails'] ?? selectedPlan.callDetails);
    final savedFeatures = savedData?['planFeatures'];
    final featuresCtrl = TextEditingController(
        text: savedFeatures != null
            ? (savedFeatures as List).join(", ")
            : selectedPlan.features.join(", "));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Edit Plan Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              AuthTextField(label: "Plan Title", controller: titleCtrl),
              const SizedBox(height: 10),
              AuthTextField(
                  label: "Price (₱)",
                  controller: priceCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              AuthTextField(label: "Call Details", controller: callCtrl),
              const SizedBox(height: 10),
              AuthTextField(
                  label: "Features (comma separated)",
                  controller: featuresCtrl),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // Save to Firestore
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({
                        'planTitle': titleCtrl.text,
                        'price': priceCtrl.text,
                        'planCallDetails': callCtrl.text,
                        'planFeatures': featuresCtrl.text
                            .split(',')
                            .map((e) => e.trim())
                            .toList(),
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        // Reload the plans to reflect the changes
                        setState(() {
                          _initializePlans();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Plan updated successfully!")),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D70F3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text("Save Changes",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Monthly Membership Plans",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                return PlanCard(
                  plan: plans[index],
                  isSelected: selectedIndex == index,
                  onTap: () => setState(() => selectedIndex = index),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.isMentorView) {
                    _showEditSheet(plans[selectedIndex]);
                  } else {
                    // Navigate to Checkout
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(
                          selectedPlan: plans[selectedIndex],
                          mentorData: widget.mentorData!,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D70F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.isMentorView
                      ? "Edit Plan Details"
                      : "Proceed to Checkout",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
