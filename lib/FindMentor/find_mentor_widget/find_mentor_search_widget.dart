import 'package:finaproj/common/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FindMentorSearchWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final String initialText;
  final bool showFilter;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final bool showSort; // New parameter to control sort visibility

  const FindMentorSearchWidget({
    super.key,
    required this.onSearchChanged,
    required this.onFilterTap,
    this.initialText = '',
    this.showFilter = true,
    required this.sortBy,
    required this.onSortChanged,
    this.showSort = true, // Default to true (show sort)
  });

  @override
  State<FindMentorSearchWidget> createState() => _FindMentorSearchWidgetState();
}

class _FindMentorSearchWidgetState extends State<FindMentorSearchWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _moveCursorToEnd();
  }

  @override
  void didUpdateWidget(covariant FindMentorSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText &&
        widget.initialText != _controller.text) {
      _controller.text = widget.initialText;
      _moveCursorToEnd();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _moveCursorToEnd() {
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final side = ResponsiveLayout.horizontalPadding(context);
    final gap = ResponsiveLayout.verticalSpacing(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Force inline layout so search and filter stay on one row on all devices
        final isStacked = false;

        final searchField = Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _controller,
            onChanged: widget.onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              hintText: 'Search mentors or students...',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        );

        final filterButton = GestureDetector(
          onTap: widget.onFilterTap,
          child: Container(
            height: 52,
            width: 52,
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A65).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: SvgPicture.asset(
              'assets/icons/tune.svg',
              color: const Color(0xFF2D6A65),
              placeholderBuilder: (_) => const Icon(Icons.tune, color: Color(0xFF2D6A65)),
            ),
          ),
        );

        return Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(side, gap, side, gap / 2),
              child: isStacked
                  ? Column(
                      children: [
                        searchField,
                        if (widget.showFilter) ...[
                          SizedBox(height: gap / 2),
                          Align(alignment: Alignment.centerRight, child: filterButton),
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: searchField),
                        if (widget.showFilter) ...[
                          SizedBox(width: gap / 1.5),
                          filterButton,
                        ],
                      ],
                    ),
            ),
            // Sort dropdown - only show if showSort is true
            if (widget.showSort)
              Container(
                margin: EdgeInsets.symmetric(horizontal: side),
                child: Row(
                  children: [
                    const Icon(Icons.sort, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Sort by:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: widget.sortBy,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2D6A65)),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                widget.onSortChanged(value);
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: 'default', child: Text('Default')),
                              DropdownMenuItem(value: 'rating', child: Text('Highest Rated')),
                              DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                              DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: gap),
          ],
        );
      },
    );
  }
}
