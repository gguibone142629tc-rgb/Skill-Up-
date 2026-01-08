import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finaproj/common/auth_text_field.dart';
import 'package:finaproj/common/responsive_layout.dart';
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
  int selectedIndex = 0;

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
      setState(() {
        _isLoading = true;
      });

      // Get mentor's custom data from Firestore
      Map<String, int>? planMaxSlots;
      Map<String, int>? planAvailableSlots;
      Map<String, dynamic>? mentorDocData;

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
              mentorDocData = data;
              
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
              
              // Sync slots with actual active subscriptions per plan (uses canonical planKey when available)
              const planNames = ['Growth Starter', 'Career Accelerator', 'Executive Elite'];
              const planKeys = ['Growth_Starter', 'Career_Accelerator', 'Executive_Elite'];

              for (var i = 0; i < planNames.length; i++) {
                final planName = planNames[i];
                final planKey = planKeys[i];

                // Prefer counting subs by canonical planKey
                final activeByKey = await FirebaseFirestore.instance
                    .collection('subscriptions')
                    .where('mentorId', isEqualTo: uid)
                    .where('planKey', isEqualTo: planKey)
                    .where('status', isEqualTo: 'active')
                    .get();

                // Fallback for legacy subs that stored only planTitle (default names)
                final activeByTitle = await FirebaseFirestore.instance
                    .collection('subscriptions')
                    .where('mentorId', isEqualTo: uid)
                    .where('planTitle', isEqualTo: planName)
                    .where('status', isEqualTo: 'active')
                    .get();

                final activeCount = activeByKey.docs.length + activeByTitle.docs.length;
                final maxSlots = planMaxSlots[planName] ?? 10;
                final correctAvailableSlots = maxSlots - activeCount;

                if (correctAvailableSlots != planAvailableSlots[planName]) {
                  planAvailableSlots[planName] = correctAvailableSlots;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({
                    'slots_${planKey}_available': correctAvailableSlots,
                  });
                }
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
                mentorDocData = data;
                
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
                
                // Sync slots with actual active subscriptions per plan (canonical planKey + legacy fallback)
                const planNames = ['Growth Starter', 'Career Accelerator', 'Executive Elite'];
                const planKeys = ['Growth_Starter', 'Career_Accelerator', 'Executive_Elite'];

                for (var i = 0; i < planNames.length; i++) {
                  final planName = planNames[i];
                  final planKey = planKeys[i];

                  final activeByKey = await FirebaseFirestore.instance
                      .collection('subscriptions')
                      .where('mentorId', isEqualTo: mentorId)
                      .where('planKey', isEqualTo: planKey)
                      .where('status', isEqualTo: 'active')
                      .get();

                  final activeByTitle = await FirebaseFirestore.instance
                      .collection('subscriptions')
                      .where('mentorId', isEqualTo: mentorId)
                      .where('planTitle', isEqualTo: planName)
                      .where('status', isEqualTo: 'active')
                      .get();

                  final activeCount = activeByKey.docs.length + activeByTitle.docs.length;
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

      // Base plans - for mentors, start blank; for students, load mentor's plans
      if (widget.isMentorView && mentorDocData != null) {
        // Mentor view: Load their saved plans or start with blank templates
        final md = mentorDocData;
        plans = [
          MembershipPlan(
            title: md['plan_Growth_Starter_title'] ?? "Plan 1",
            callDetails: md['plan_Growth_Starter_callDetails'] ?? "Add call details",
            features: (md['plan_Growth_Starter_features'] as List?)?.map((e) => e.toString()).toList() ?? ["Add features"],
            price: (() {
              final raw = md['plan_Growth_Starter_price']?.toString() ?? '';
              final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
              return digits.isEmpty ? 0 : (int.tryParse(digits) ?? 0);
            })(),
            maxSlots: planMaxSlots?['Growth Starter'] ?? 10,
            availableSlots: planAvailableSlots?['Growth Starter'] ?? 10,
          ),
          MembershipPlan(
            title: md['plan_Career_Accelerator_title'] ?? "Plan 2",
            callDetails: md['plan_Career_Accelerator_callDetails'] ?? "Add call details",
            features: (md['plan_Career_Accelerator_features'] as List?)?.map((e) => e.toString()).toList() ?? ["Add features"],
            price: (() {
              final raw = md['plan_Career_Accelerator_price']?.toString() ?? '';
              final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
              return digits.isEmpty ? 0 : (int.tryParse(digits) ?? 0);
            })(),
            maxSlots: planMaxSlots?['Career Accelerator'] ?? 10,
            availableSlots: planAvailableSlots?['Career Accelerator'] ?? 10,
          ),
          MembershipPlan(
            title: md['plan_Executive_Elite_title'] ?? "Plan 3",
            callDetails: md['plan_Executive_Elite_callDetails'] ?? "Add call details",
            features: (md['plan_Executive_Elite_features'] as List?)?.map((e) => e.toString()).toList() ?? ["Add features"],
            price: (() {
              final raw = md['plan_Executive_Elite_price']?.toString() ?? '';
              final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
              return digits.isEmpty ? 0 : (int.tryParse(digits) ?? 0);
            })(),
            maxSlots: planMaxSlots?['Executive Elite'] ?? 10,
            availableSlots: planAvailableSlots?['Executive Elite'] ?? 10,
          ),
        ];
      } else if (!widget.isMentorView && mentorDocData != null) {
        // Student view: Load mentor's configured plans
        final md = mentorDocData;
        plans = [
          MembershipPlan(
            title: md['plan_Growth_Starter_title'] ?? "Plan 1",
            callDetails: md['plan_Growth_Starter_callDetails'] ?? "Not configured",
            features: (md['plan_Growth_Starter_features'] as List?)?.map((e) => e.toString()).toList() ?? ["Not configured"],
            price: (() {
              final raw = md['plan_Growth_Starter_price']?.toString() ?? '';
              final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
              return digits.isEmpty ? 0 : (int.tryParse(digits) ?? 0);
            })(),
            maxSlots: planMaxSlots?['Growth Starter'] ?? 10,
            availableSlots: planAvailableSlots?['Growth Starter'] ?? 10,
          ),
          MembershipPlan(
            title: md['plan_Career_Accelerator_title'] ?? "Plan 2",
            callDetails: md['plan_Career_Accelerator_callDetails'] ?? "Not configured",
            features: (md['plan_Career_Accelerator_features'] as List?)?.map((e) => e.toString()).toList() ?? ["Not configured"],
            price: (() {
              final raw = md['plan_Career_Accelerator_price']?.toString() ?? '';
              final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
              return digits.isEmpty ? 0 : (int.tryParse(digits) ?? 0);
            })(),
            maxSlots: planMaxSlots?['Career Accelerator'] ?? 10,
            availableSlots: planAvailableSlots?['Career Accelerator'] ?? 10,
          ),
          MembershipPlan(
            title: md['plan_Executive_Elite_title'] ?? "Plan 3",
            callDetails: md['plan_Executive_Elite_callDetails'] ?? "Not configured",
            features: (md['plan_Executive_Elite_features'] as List?)?.map((e) => e.toString()).toList() ?? ["Not configured"],
            price: (() {
              final raw = md['plan_Executive_Elite_price']?.toString() ?? '';
              final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
              return digits.isEmpty ? 0 : (int.tryParse(digits) ?? 0);
            })(),
            maxSlots: planMaxSlots?['Executive Elite'] ?? 10,
            availableSlots: planAvailableSlots?['Executive Elite'] ?? 10,
          ),
        ];
      } else {
        // Fallback: blank templates
        plans = [
          MembershipPlan(
            title: "Plan 1",
            callDetails: "Add call details",
            features: ["Add features"],
            price: 0,
            maxSlots: 10,
            availableSlots: 10,
          ),
          MembershipPlan(
            title: "Plan 2",
            callDetails: "Add call details",
            features: ["Add features"],
            price: 0,
            maxSlots: 10,
            availableSlots: 10,
          ),
          MembershipPlan(
            title: "Plan 3",
            callDetails: "Add call details",
            features: ["Add features"],
            price: 0,
            maxSlots: 10,
            availableSlots: 10,
          ),
        ];
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error initializing plans: $e");
      // Provide default plans on error
      plans = [
        MembershipPlan(
          title: "Growth Starter",
          callDetails: "1x 45-min call per month",
          features: ["Basic email support"],
          price: 1200,
          maxSlots: 10,
          availableSlots: 10,
        ),
        MembershipPlan(
          title: "Career Accelerator",
          callDetails: "4x 30-min call per month",
          features: ["Priority in-app messaging", "Document Review"],
          price: 2500,
          maxSlots: 10,
          availableSlots: 10,
        ),
        MembershipPlan(
          title: "Executive Elite",
          callDetails: "Unlimited calls",
          features: ["Direct chat access", "Resume/ Profile optimization"],
          price: 4000,
          maxSlots: 10,
          availableSlots: 10,
        ),
      ];
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- EDIT LOGIC ---
  void _showEditSheet(MembershipPlan selectedPlan, int planIndex) async {
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

    // CRITICAL: Use plan index to get the DEFAULT plan title
    final defaultPlanNames = ["Growth Starter", "Career Accelerator", "Executive Elite"];
    final defaultPlanName = defaultPlanNames[planIndex];
    
    // Normalize plan name for Firestore keys (we store with underscores)
    final planKey = defaultPlanName.replaceAll(' ', '_');
    // Per-plan overrides
    final titleCtrl = TextEditingController(
      text: savedData?['plan_${planKey}_title'] ?? selectedPlan.title);
    final priceCtrl = TextEditingController(
      text: savedData?['plan_${planKey}_price']?.toString() ??
        selectedPlan.price.toString());
    final callCtrl = TextEditingController(
      text: savedData?['plan_${planKey}_callDetails'] ?? selectedPlan.callDetails);
    final savedFeatures = savedData?['plan_${planKey}_features'];
    final featuresCtrl = TextEditingController(
      text: savedFeatures != null
        ? (savedFeatures as List).join(", ")
        : selectedPlan.features.join(", "));
    final slotsCtrl = TextEditingController(
      text: savedData?['slots_${planKey}_max']?.toString() ?? '10');

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
                      final priceDigits = priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                      final parsedPrice = priceDigits.isEmpty
                          ? null
                          : int.tryParse(priceDigits);
                      final currentData = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .get();
                      
                      // Calculate current available slots based on max slots for this specific plan
                      int currentAvailableSlots = newMaxSlots;
                      if (currentData.exists) {
                        final data = currentData.data();
                        final slotKeyMax = 'slots_${planKey}_max';
                        final slotKeyAvailable = 'slots_${planKey}_available';
                        final currentMaxSlots = (data?[slotKeyMax] ?? 10) as int;
                        final oldAvailableSlots = (data?[slotKeyAvailable] ?? currentMaxSlots) as int;
                        final slotsUsed = currentMaxSlots - oldAvailableSlots;
                        currentAvailableSlots = newMaxSlots - slotsUsed;
                        // Ensure available slots doesn't go negative
                        if (currentAvailableSlots < 0) currentAvailableSlots = 0;
                      }
                      
                      final slotKeyMax = 'slots_${planKey}_max';
                      final slotKeyAvailable = 'slots_${planKey}_available';
                      
                      debugPrint('💾 Saving $defaultPlanName (key: $planKey): price=$parsedPrice, call=${callCtrl.text}, title=${titleCtrl.text}');
                      
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({
                        // Per-plan overrides
                        'plan_${planKey}_title': titleCtrl.text,
                        'plan_${planKey}_price': parsedPrice ?? priceCtrl.text,
                        'plan_${planKey}_callDetails': callCtrl.text,
                        'plan_${planKey}_features': featuresCtrl.text
                          .split(',')
                          .map((e) => e.trim())
                          .toList(),
                        slotKeyMax: newMaxSlots,
                        slotKeyAvailable: currentAvailableSlots,
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Plan updated successfully!")),
                        );
                        // Reload the plans to reflect the changes
                        await _initializePlans();
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
    final side = ResponsiveLayout.horizontalPadding(context);
    final gap = ResponsiveLayout.verticalSpacing(context, mobile: 10, tablet: 14, desktop: 16);
    final maxCardWidth = ResponsiveLayout.value<double>(
      context,
      mobile: 520,
      tablet: 640,
      desktop: 760,
    );

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
                  child: plans.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No plans available right now.'),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              EdgeInsets.symmetric(horizontal: side, vertical: gap),
                          itemCount: plans.length,
                          itemBuilder: (context, index) {
                            return Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxCardWidth),
                                child: PlanCard(
                                  plan: plans[index],
                                  isSelected: selectedIndex == index,
                                  onTap: () => setState(() => selectedIndex = index),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(side, gap, side, 80),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxCardWidth),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: plans.isEmpty
                              ? null
                              : () {
                                  final safeIndex = selectedIndex.clamp(0, plans.length - 1);
                                  final selectedPlan = plans[safeIndex];

                                  if (widget.isMentorView) {
                                    _showEditSheet(selectedPlan, safeIndex);
                                    return;
                                  }

                                  if (selectedPlan.price <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "This mentor hasn't configured this plan yet. Please select another plan or mentor."),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  if (selectedPlan.availableSlots != null &&
                                      selectedPlan.availableSlots! <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Sorry, no slots available for this plan. Please try another mentor.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  const planKeys = [
                                    'Growth_Starter',
                                    'Career_Accelerator',
                                    'Executive_Elite',
                                  ];
                                  final planKey = planKeys[safeIndex];

                                  if (widget.mentorData == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Missing mentor details. Please reopen the mentor profile and try again.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CheckoutPage(
                                        selectedPlan: selectedPlan,
                                        mentorData: widget.mentorData!,
                                        planKey: planKey,
                                      ),
                                    ),
                                  );
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
                  ),
                ),
              ],
            ),
    );
  }
}
