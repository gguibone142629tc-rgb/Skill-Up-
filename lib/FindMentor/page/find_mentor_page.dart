import 'package:flutter/material.dart';
import 'package:finaproj/FindMentor/find_mentor_widget/find_mentor_list_view.dart';
import 'package:finaproj/FindMentor/find_mentor_widget/find_mentor_search_widget.dart';
import 'package:finaproj/main.dart';

class FindMentorPage extends StatefulWidget {
  final String? initialCategory;
  final List<String>? initialCategories;
  final bool hideStudents;
  final String? initialSearch;

  const FindMentorPage({super.key, this.initialCategory, this.initialCategories, this.hideStudents = false, this.initialSearch});

  @override
  State<FindMentorPage> createState() => _FindMentorPageState();
}

class _FindMentorPageState extends State<FindMentorPage> {
  String _searchQuery = "";
  String? _selectedCategory;
  List<String>? _selectedCategories;
  String _selectedRole = 'Mentors'; // New: Role filter (Mentors or Students)
  String _sortBy = 'default'; // New: Sort option

  // Same categories as Sign Up for consistency
  final List<String> _categories = [
    'All', // Option to clear filter
    'Graphic Design',
    'Digital Marketing',
    'Video & Animation',
    'Music & Audio',
    'Program & Tech',
    'Product Photography',
    'Build AI Service',
    'Data',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedCategories = widget.initialCategories;
    _searchQuery = widget.initialSearch ?? "";
  }

  // Show Filter Bottom Sheet
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Filter by Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat || (_selectedCategory == null && cat == 'All');
                    
                    return ListTile(
                      title: Text(cat),
                      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF2D6A65)) : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat == 'All' ? null : cat;
                          _selectedCategories = null; // clear multi-category selection when user picks single
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Title Logic
    final String? displayCategory = _selectedCategory == 'Marketing' ? 'Digital Marketing' : _selectedCategory;
    String title = displayCategory != null 
        ? '$displayCategory ${_selectedRole}' 
        : 'Search $_selectedRole';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              title, 
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)
            ),
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            automaticallyImplyLeading: widget.initialCategory != null, 
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          
          // Role filter tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = 'Mentors'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'Mentors' ? const Color(0xFF2D6A65) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'Mentors',
                            style: TextStyle(
                              color: _selectedRole == 'Mentors' ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = 'Students'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'Students' ? const Color(0xFF2D6A65) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'Students',
                            style: TextStyle(
                              color: _selectedRole == 'Students' ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: FindMentorSearchWidget(
              initialText: _searchQuery,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onFilterTap: _showFilterModal,
              showFilter: _selectedRole == 'Mentors', // Hide filter when viewing students
              sortBy: _sortBy,
              onSortChanged: (value) {
                setState(() {
                  _sortBy = value;
                });
              },
            ),
          ),

          SliverToBoxAdapter(
            child: FindMentorListView(
              searchQuery: _searchQuery,
              categories: _selectedCategories ?? (_selectedCategory != null ? [_selectedCategory!] : null),
              hideStudents: _selectedRole == 'Mentors',
              hideMentors: _selectedRole == 'Students',
              sortBy: _sortBy,
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(initialIndex: 1),
    );
  }
}