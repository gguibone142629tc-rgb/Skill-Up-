import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finaproj/common/auth_text_field.dart';
import 'package:finaproj/membershipPlan/model/membership_plan.dart';
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

  // Static Plans
  final List<MembershipPlan> plans = [
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

  // --- EDIT LOGIC ---
  void _showEditSheet(MembershipPlan selectedPlan) {
    // Pre-fill with the selected plan's static data
    // (Or you can use widget.mentorData here if you want to load saved overrides)
    final titleCtrl = TextEditingController(text: selectedPlan.title);
    final priceCtrl = TextEditingController(text: selectedPlan.price.toString());
    final callCtrl = TextEditingController(text: selectedPlan.callDetails);
    final featuresCtrl = TextEditingController(text: selectedPlan.features.join(", "));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20, left: 20, right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Edit Plan Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              AuthTextField(label: "Plan Title", controller: titleCtrl),
              const SizedBox(height: 10),
              AuthTextField(label: "Price (₱)", controller: priceCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              AuthTextField(label: "Call Details", controller: callCtrl),
              const SizedBox(height: 10),
              AuthTextField(label: "Features (comma separated)", controller: featuresCtrl),
              
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // Save to Firestore
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await FirebaseFirestore.instance.collection('users').doc(uid).update({
                        'planTitle': titleCtrl.text,
                        'price': priceCtrl.text,
                        'planCallDetails': callCtrl.text,
                        'planFeatures': featuresCtrl.text.split(',').map((e) => e.trim()).toList(),
                      });
                      
                      if(mounted) {
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Plan updated successfully!")),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D70F3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    // Student Checkout Logic
                    print("Student checking out: ${plans[selectedIndex].title}");
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
                  widget.isMentorView ? "Edit Plan Details" : "Proceed to Checkout",
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