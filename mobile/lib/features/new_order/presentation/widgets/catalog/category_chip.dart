import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';

/// Category pill chip matching the design with tactile press feedback & 40dp clearance.
class CategoryChip extends StatefulWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? KkfcMotion.pressScale : 1.0,
        duration: KkfcMotion.durPress,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0xFF1D2940)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(KkfcRadius.pill),
            border: widget.selected
                ? null
                : Border.all(color: const Color(0xFF76849A), width: 1.0),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1D2940).withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 14.0,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
              color: widget.selected ? Colors.white : const Color(0xFF19293E),
            ),
          ),
        ),
      ),
    );
  }
}
