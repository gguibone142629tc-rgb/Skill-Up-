import 'package:flutter/material.dart';
import 'package:finaproj/common/auth_text_field.dart';

class MentorExperienceStep extends StatefulWidget {
  final Function(int years, int months)? onExperienceChanged;
  final ValueChanged<String>? onBioChanged;
  final ValueChanged<List<String>>? onSkillsChanged;
  final ValueChanged<List<String>>? onExpertiseChanged;
  
  // ✅ NEW: Callback for Category
  final ValueChanged<String>? onCategoryChanged;

  const MentorExperienceStep({
    super.key,
    this.onExperienceChanged,
    this.onBioChanged,
    this.onSkillsChanged,
    this.onExpertiseChanged,
    this.onCategoryChanged, // ✅ Initialize it
  });

  @override
  State<MentorExperienceStep> createState() => _MentorExperienceStepState();
}

class _MentorExperienceStepState extends State<MentorExperienceStep> {
  int _years = 0;
  int _months = 0;

  final TextEditingController _bioController = TextEditingController();

  // --- DATA STRUCTURE ---
  final Map<String, Map<String, List<String>>> _categoryData = {
    'Graphic Design': {
      'skills': ['Adobe Photoshop', 'Adobe Illustrator', 'Figma', 'InDesign', 'Canva', 'Sketch', 'CorelDRAW'],
      'expertise': ['Logo Design', 'Brand Identity', 'Illustration', 'Print Design', 'Packaging', 'Visual Arts', 'UI/UX Design'],
    },
    'Digital Marketing': {
      'skills': ['Google Analytics', 'SEO Tools', 'Facebook Ads Manager', 'Mailchimp', 'HubSpot', 'Canva', 'WordPress'],
      'expertise': ['Social Media Marketing', 'SEO', 'Content Strategy', 'Email Marketing', 'PPC Advertising', 'Copywriting'],
    },
    'Video & Animation': {
      'skills': ['Adobe Premiere Pro', 'After Effects', 'Final Cut Pro', 'DaVinci Resolve', 'Blender', 'Cinema 4D'],
      'expertise': ['Video Editing', 'Motion Graphics', '2D Animation', '3D Animation', 'Visual Effects (VFX)', 'Color Grading'],
    },
    'Music & Audio': {
      'skills': ['Ableton Live', 'Logic Pro', 'Pro Tools', 'FL Studio', 'Audacity', 'GarageBand'],
      'expertise': ['Music Production', 'Sound Design', 'Mixing & Mastering', 'Voice Over', 'Songwriting', 'Audio Engineering'],
    },
    'Program & Tech': {
      'skills': ['Flutter', 'Dart', 'React', 'JavaScript', 'Python', 'Java', 'C++', 'AWS', 'Firebase', 'Git', 'Docker'],
      'expertise': ['Mobile App Dev', 'Web Development', 'Backend Engineering', 'Cybersecurity', 'Cloud Computing', 'DevOps'],
    },
    'Product Photography': {
      'skills': ['Adobe Lightroom', 'Photoshop', 'DSLR Cameras', 'Lighting Equipment', 'Capture One'],
      'expertise': ['Product Styling', 'Commercial Photography', 'E-commerce', 'Photo Retouching', 'Composition'],
    },
    'Build AI Service': {
      'skills': ['Python', 'TensorFlow', 'PyTorch', 'OpenAI API', 'Pandas', 'Scikit-learn', 'Jupyter'],
      'expertise': ['Machine Learning', 'NLP', 'Computer Vision', 'Deep Learning', 'Chatbot Development', 'Data Modeling'],
    },
    'Data': {
      'skills': ['SQL', 'Excel', 'Tableau', 'Power BI', 'Python', 'R', 'SAS'],
      'expertise': ['Data Analysis', 'Data Science', 'Business Intelligence', 'Big Data', 'Statistical Analysis'],
    },
  };

  String? _selectedCategory;
  final List<String> _selectedSkills = [];
  final List<String> _selectedExpertise = [];

  @override
  void initState() {
    super.initState();
    _bioController.addListener(() {
      widget.onBioChanged?.call(_bioController.text);
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? newCategory) {
    setState(() {
      _selectedCategory = newCategory;
      _selectedSkills.clear();
      _selectedExpertise.clear();
    });
    
    // ✅ Notify Parent about the Category Change
    if (newCategory != null) {
      widget.onCategoryChanged?.call(newCategory);
    }

    widget.onSkillsChanged?.call([]);
    widget.onExpertiseChanged?.call([]);
  }

  void _addSkill(String? value) {
    if (value != null && !_selectedSkills.contains(value)) {
      setState(() => _selectedSkills.add(value));
      widget.onSkillsChanged?.call(_selectedSkills);
    }
  }

  void _addExpertise(String? value) {
    if (value != null && !_selectedExpertise.contains(value)) {
      setState(() => _selectedExpertise.add(value));
      widget.onExpertiseChanged?.call(_selectedExpertise);
    }
  }

  void _removeSkill(String value) {
    setState(() => _selectedSkills.remove(value));
    widget.onSkillsChanged?.call(_selectedSkills);
  }

  void _removeExpertise(String value) {
    setState(() => _selectedExpertise.remove(value));
    widget.onExpertiseChanged?.call(_selectedExpertise);
  }

  @override
  Widget build(BuildContext context) {
    List<String> availableSkills = [];
    List<String> availableExpertise = [];

    if (_selectedCategory != null) {
      availableSkills = _categoryData[_selectedCategory]!['skills'] ?? [];
      availableExpertise = _categoryData[_selectedCategory]!['expertise'] ?? [];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNumberDropdown(
                label: "Years of Exp",
                value: _years,
                max: 30,
                onChanged: (val) {
                  setState(() => _years = val!);
                  widget.onExperienceChanged?.call(_years, _months);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberDropdown(
                label: "Months",
                value: _months,
                max: 11,
                onChanged: (val) {
                  setState(() => _months = val!);
                  widget.onExperienceChanged?.call(_years, _months);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        const Text("Main Category", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildStyledDropdown(
          hint: "Select your main category",
          value: _selectedCategory,
          items: _categoryData.keys.toList(),
          onChanged: _onCategoryChanged,
        ),
        const SizedBox(height: 20),

        if (_selectedCategory != null) ...[
          const Text("Select Skills", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildStyledDropdown(
            hint: "Add a skill...",
            value: null,
            items: availableSkills,
            onChanged: _addSkill,
          ),
          if (_selectedSkills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8,
                children: _selectedSkills.map((skill) => Chip(
                  label: Text(skill),
                  backgroundColor: const Color(0xFFE0F2F1),
                  deleteIconColor: Colors.teal,
                  onDeleted: () => _removeSkill(skill),
                )).toList(),
              ),
            ),
          const SizedBox(height: 20),

          const Text("Select Expertise", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildStyledDropdown(
            hint: "Add an area of expertise...",
            value: null,
            items: availableExpertise,
            onChanged: _addExpertise,
          ),
          if (_selectedExpertise.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8,
                children: _selectedExpertise.map((exp) => Chip(
                  label: Text(exp),
                  backgroundColor: const Color(0xFFE0F2F1),
                  deleteIconColor: Colors.teal,
                  onDeleted: () => _removeExpertise(exp),
                )).toList(),
              ),
            ),
        ] else ...[
          const Text(
            "Please select a category above.",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],

        const SizedBox(height: 20),

        AuthTextField(
          label: "Bio",
          controller: _bioController,
          hintText: "Tell us about yourself...",
          maxLines: 4,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStyledDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildNumberDropdown({
    required String label,
    required int value,
    required int max,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300)
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              items: List.generate(max + 1, (index) => index)
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}