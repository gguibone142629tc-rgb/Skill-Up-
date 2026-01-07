import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FindMentorSearchWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final String initialText;
  final bool showFilter;

  const FindMentorSearchWidget({
    super.key,
    required this.onSearchChanged,
    required this.onFilterTap,
    this.initialText = '',
    this.showFilter = true,
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
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
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
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),
          if (widget.showFilter) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onFilterTap,
              child: Container(
                height: 50,
                width: 50,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A65).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: SvgPicture.asset(
                  'assets/icons/tune.svg',
                  color: const Color(0xFF2D6A65),
                  placeholderBuilder: (_) =>
                      const Icon(Icons.tune, color: Color(0xFF2D6A65)),
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
}
