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
  late List<MembershipPlan> plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlans();
  }

  Future<void> _initializePlans() async {
    try {
      // Get mentor's custom data from Firestore
      String? mentorCustomPrice = widget.mentorData?['price'];
      String? mentorPlanTitle = widget.mentorData?['planTitle'];
      String? mentorCallDetails = widget.mentorData?['planCallDetails'];
      List<String>? mentorFeatures;
      Map<String, int>? planMaxSlots;
      Map<String, int>? planAvailableSlots;

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
              
              // Get per-plan slot data
              planMaxSlots = {
                'Growth Starter': data['slots_Growth_Starter_max'] ?? 10,
                'Career Accelerator': data['slots_Career_Accelerator_max'] ?? 10,
                'Executive Elite': data['slots_Executive_Elite_max'] ?? 10,
              };
              planAvailableSlots = {
                'Growth Starter': data['slots_Growth_Starter_available'] ?? 10,
                'Career Accelerator': data['slots_Career_Accelerator_available'] ?? 10,
                'Executive Elite': data['slots_Executive_Elite_available'] ?? 10,
              };
              
              // Initialize slots if they don't exist
              if (data['slots_Growth_Starter_max'] == null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({
                  'slots_Growth_Starter_max': 10,
                  'slots_Growth_Starter_available': 10,
                  'slots_Career_Accelerator_max': 10,
                  'slots_Career_Accelerator_available': 10,
                  'slots_Executive_Elite_max': 10,
                  'slots_Executive_Elite_available': 10,
                });
              }
              
              // Sync slots with actual active subscriptions per plan
              for (final planName in ['Growth Starter', 'Career Accelerator', 'Executive Elite']) {
                final activeSubscriptions = await FirebaseFirestore.instance
                    .collection('subscriptions')
                    .where('mentorId', isEqualTo: uid)
                    .where('planTitle', isEqualTo: planName)
                    .where('status', isEqualTo: 'active')
                    .get();
                
                final activeCount = activeSubscriptions.docs.length;
                final maxSlots = planMaxSlots[planName] ?? 10;
                final correctAvailableSlots = maxSlots - activeCount;
                
                if (correctAvailableSlots != planAvailableSlots[planName]) {
                  planAvailableSlots[planName] = correctAvailableSlots;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({
                    'slots_${planName}_available': correctAvailableSlots,
                  });
                }
              }
              
              if (data['planFeatures'] != null) {
                mentorFeatures = List<String>.from(data['planFeatures']);
              }
            }
          } catch (e) {
            debugPrint("Error loading mentor data: $e");
          }
        }
      } else {
        // Student viewing mentor's plan - load mentor's per-plan slot data
        if (widget.mentorData != null) {
          final mentorId = widget.mentorData?['uid'];
          
          // Fetch fresh mentor data from Firestore to get latest slot info
          if (mentorId != null) {
            try {
              final mentorDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(mentorId)
                  .get();
              
              if (mentorDoc.exists) {
                final data = mentorDoc.data() as Map<String, dynamic>;
                
                // Get per-plan slot data
                planMaxSlots = {
                  'Growth Starter': data['slots_Growth_Starter_max'] ?? 10,
                  'Career Accelerator': data['slots_Career_Accelerator_max'] ?? 10,
                  'Executive Elite': data['slots_Executive_Elite_max'] ?? 10,
                };
                planAvailableSlots = {
                  'Growth Starter': data['slots_Growth_Starter_available'] ?? 10,
                  'Career Accelerator': data['slots_Career_Accelerator_available'] ?? 10,
                  'Executive Elite': data['slots_Executive_Elite_available'] ?? 10,
                };
                
                // Sync slots with actual active subscriptions per plan
                for (final planName in ['Growth Starter', 'Career Accelerator', 'Executive Elite']) {
                  final activeSubscriptions = await FirebaseFirestore.instance
                      .collection('subscriptions')
                      .where('mentorId', isEqualTo: mentorId)
                    .where('planTitle', isEqualTo: planName)
                    .where('status', isEqualTo: 'active')
                    .get();
                
                final activeCount = activeSubscriptions.docs.length;
                final maxSlots = planMaxSlots[planName] ?? 10;
                final correctAvailableSlots = maxSlots - activeCount;
                planAvailableSlots[planName] = correctAvailableSlots;
              }
            }
          } catch (e) {
            debugPrint("Error loading mentor slot data: $e");
            planMaxSlots = {
              'Growth Starter': 10,
              'Career Accelerator': 10,
              'Executive Elite': 10,
            };
            planAvailableSlots = {
              'Growth Starter': 10,
              'Career Accelerator': 10,
              'Executive Elite': 10,
            };
          }
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
        maxSlots: planMaxSlots?['Growth Starter'] ?? 10,
        availableSlots: planAvailableSlots?['Growth Starter'] ?? 10,
      ),
      MembershipPlan(
        title: "Career Accelerator",
        callDetails: "4x 30-min call per month",
        features: ["Priority in-app messaging", "Document Review"],
        price: 2500,
        maxSlots: planMaxSlots?['Career Accelerator'] ?? 10,
        availableSlots: planAvailableSlots?['Career Accelerator'] ?? 10,
      ),
      MembershipPlan(
        title: "Executive Elite",
        callDetails: "Unlimited calls",
        features: ["Direct chat access", "Resume/ Profile optimization"],
        price: 4000,
        maxSlots: planMaxSlots?['Executive Elite'] ?? 10,
        availableSlots: planAvailableSlots?['Executive Elite'] ?? 10,
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
              maxSlots: planMaxSlots?[plans[i].title] ?? 10,
              availableSlots: planAvailableSlots?[plans[i].title] ?? 10,
            );
            break;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    } catch (e) {
      debugPrint("Error initializing plans: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    final planName = selectedPlan.title;
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
    final slotsCtrl = TextEditingController(
        text: savedData?['slots_${planName}_max']?.toString() ?? '10');

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
              const SizedBox(height: 10),
              AuthTextField(
                  label: "Max Slots (Number of mentees)",
                  controller: slotsCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // Save to Firestore
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      final newMaxSlots = int.tryParse(slotsCtrl.text) ?? 10;
                      final currentData = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .get();
                      
                      // Calculate current available slots based on max slots for this specific plan
                      int currentAvailableSlots = newMaxSlots;
                      if (currentData.exists) {
                        final data = currentData.data();
                        final slotKeyMax = 'slots_${planName}_max';
                        final slotKeyAvailable = 'slots_${planName}_available';
                        final currentMaxSlots = (data?[slotKeyMax] ?? 10) as int;
                        final oldAvailableSlots = (data?[slotKeyAvailable] ?? currentMaxSlots) as int;
                        final slotsUsed = currentMaxSlots - oldAvailableSlots;
                        currentAvailableSlots = newMaxSlots - slotsUsed;
                        // Ensure available slots doesn't go negative
                        if (currentAvailableSlots < 0) currentAvailableSlots = 0;
                      }
                      
                      final slotKeyMax = 'slots_${planName}_max';
                      final slotKeyAvailable = 'slots_${planName}_available';
                      
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
                        slotKeyMax: newMaxSlots,
                        slotKeyAvailable: currentAvailableSlots,
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF2D6A65),
                ),
              ),
            )
          : Column(
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
                    // Check if slots are available before proceeding
                    final selectedPlan = plans[selectedIndex];
                    if (selectedPlan.availableSlots != null && 
                        selectedPlan.availableSlots! <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sorry, no slots available for this plan. Please try another mentor.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Navigate to Checkout
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(
                          selectedPlan: selectedPlan,
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
