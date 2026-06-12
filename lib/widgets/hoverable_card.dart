import 'package:flutter/material.dart';
import 'package:goodtimes/core/themes/app_colors.dart';

class HoverableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;

  const HoverableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 1.05,
  });

  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered ? AppColors.text(context).withValues(alpha: 0.3) : Colors.transparent,
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.black.withValues(alpha: 0.8) 
                          : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
