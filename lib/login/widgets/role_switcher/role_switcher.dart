import 'package:flutter/material.dart';

class RoleSwitcher extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const RoleSwitcher({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _RoleItem(
              label: "I'm a mentee",
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
            _RoleItem(
              label: "I'm a mentor",
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: Colors.grey.shade300),
      ],
    );
  }
}

class _RoleItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2D6A65);
    final color = selected ? accent : Colors.black87;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: selected ? 80 : 0,
              color: selected ? accent : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
