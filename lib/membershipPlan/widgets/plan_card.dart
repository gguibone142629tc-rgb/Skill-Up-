import 'package:finaproj/membershipPlan/model/membership_plan.dart';
import 'package:flutter/material.dart';


class PlanCard extends StatelessWidget {
  final MembershipPlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const PlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            // Matching the dark teal selection color from your first image
            color: isSelected ? const Color(0xFF2D5D56) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Fixes overflow by only taking needed space
          children: [
            Center(
              child: Text(
                plan.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              plan.callDetails,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            // Map features to bullet points
            ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "• $feature",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                )),
            const SizedBox(height: 12),
            // Display available slots if provided
            if (plan.availableSlots != null && plan.maxSlots != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: plan.availableSlots! > 0 
                      ? const Color(0xFFE8F5F3) 
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      plan.availableSlots! > 0 
                          ? Icons.people_outline 
                          : Icons.block,
                      size: 16,
                      color: plan.availableSlots! > 0 
                          ? const Color(0xFF2D6A65) 
                          : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      plan.availableSlots! > 0
                          ? "${plan.availableSlots}/${plan.maxSlots} slots available"
                          : "No slots available",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: plan.availableSlots! > 0 
                            ? const Color(0xFF2D6A65) 
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "₱${plan.price}/month",
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}