import 'package:finaproj/common/auth_text_field.dart';
import 'package:flutter/material.dart';
// CHECK THIS IMPORT: Make sure it points to where AuthTextField actually is


class MentorExperienceStep extends StatefulWidget {
  final Function(int years, int months)? onExperienceChanged;
  final ValueChanged<String>? onBioChanged;
  final ValueChanged<List<String>>? onSkillsChanged;
  final ValueChanged<List<String>>? onExpertiseChanged;

  const MentorExperienceStep({
    super.key,
    this.onExperienceChanged,
    this.onBioChanged,
    this.onSkillsChanged,
    this.onExpertiseChanged,
  });

  @override
  State<MentorExperienceStep> createState() => _MentorExperienceStepState();
}

class _MentorExperienceStepState extends State<MentorExperienceStep> {
  int _years = 0;
  int _months = 0;

  final TextEditingController _skillController = TextEditingController();
  final List<String> _skills = [];

  final TextEditingController _expertiseController = TextEditingController();
  final List<String> _expertise = [];
  
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // FIX: Listen to the controller instead of using onChanged
    _bioController.addListener(() {
      widget.onBioChanged?.call(_bioController.text);
    });
  }

  @override
  void dispose() {
    _skillController.dispose();
    _expertiseController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _addSkill() {
    if (_skillController.text.isNotEmpty) {
      setState(() {
        _skills.add(_skillController.text.trim());
        _skillController.clear();
      });
      widget.onSkillsChanged?.call(_skills);
    }
  }

  void _addExpertise() {
    if (_expertiseController.text.isNotEmpty) {
      setState(() {
        _expertise.add(_expertiseController.text.trim());
        _expertiseController.clear();
      });
      widget.onExpertiseChanged?.call(_expertise);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Experience & Skills',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        // Experience Dropdowns
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: "Years",
                value: _years,
                items: List.generate(30, (index) => index),
                onChanged: (val) {
                  setState(() => _years = val!);
                  widget.onExperienceChanged?.call(_years, _months);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                label: "Months",
                value: _months,
                items: List.generate(12, (index) => index),
                onChanged: (val) {
                  setState(() => _months = val!);
                  widget.onExperienceChanged?.call(_years, _months);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Skills Input
        Row(
          children: [
            Expanded(
              child: AuthTextField(
                label: "Add Skills (e.g. Flutter)",
                controller: _skillController,
                hintText: "Type and press +",
              ),
            ),
            IconButton(onPressed: _addSkill, icon: const Icon(Icons.add_circle))
          ],
        ),
        Wrap(
          spacing: 8,
          children: _skills.map((s) => Chip(
            label: Text(s),
            onDeleted: () {
              setState(() => _skills.remove(s));
              widget.onSkillsChanged?.call(_skills);
            },
          )).toList(),
        ),

        const SizedBox(height: 16),

        // Expertise Input
        Row(
          children: [
            Expanded(
              child: AuthTextField(
                label: "Add Expertise (e.g. Mobile Dev)",
                controller: _expertiseController,
                hintText: "Type and press +",
              ),
            ),
            IconButton(onPressed: _addExpertise, icon: const Icon(Icons.add_circle))
          ],
        ),
        Wrap(
          spacing: 8,
          children: _expertise.map((e) => Chip(
            label: Text(e),
            onDeleted: () {
              setState(() => _expertise.remove(e));
              widget.onExpertiseChanged?.call(_expertise);
            },
          )).toList(),
        ),

        const SizedBox(height: 16),
        
        // Bio
        AuthTextField(
          label: "Bio",
          controller: _bioController,
          hintText: "Tell us about yourself...",
          // REMOVED onChanged: (val) => ...
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDropdown({
    required String label, 
    required int value, 
    required List<int> items,
    required ValueChanged<int?> onChanged
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8)
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text("$e"))).toList(),
              onChanged: onChanged,
            ),
          ),
        )
      ],
    );
  }
}