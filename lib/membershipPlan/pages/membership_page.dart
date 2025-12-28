import 'package:finaproj/membershipPlan/model/membership_plan.dart';
import 'package:flutter/material.dart';

import '../widgets/plan_card.dart';

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  int selectedIndex = 0; // Default to first plan

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text(
          "Monthly Membership Plans",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
          // Proceed to Checkout Button Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Action for checkout
                },
                style: ElevatedButton.styleFrom(
                  // Matching the specific purple/blue from your image
                  backgroundColor: const Color(0xFF5D70F3), 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Proceed to Checkout",
                  style: TextStyle(
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