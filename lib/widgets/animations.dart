import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ScreenSwitcher
//
// The single, authoritative transition hub for every top-level page switch
// in the app.  Rules:
//   • Incoming page  → fades IN  + slides up from 24 px below  (easeOutCubic)
//   • Outgoing page  → fades OUT only, no slide               (easeIn)
//   • Duration 320 ms — fast enough to feel snappy, visible enough to feel smooth
//   • layoutBuilder keeps the outgoing page in a full-expand Stack beneath the
//     incoming page so there is never a blank flash between swaps.
// ─────────────────────────────────────────────────────────────────────────────
class ScreenSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const ScreenSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      // Stack: old page sits beneath new page during the overlap.
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      // Incoming child: anim goes 0→1  → fade-in + slide-up
      // Outgoing child: anim goes 1→0  → fade-out, no slide (see _FadeOnly)
      transitionBuilder: (child, animation) {
        // Detect direction: forward anim = incoming, reverse = outgoing.
        // We use the key trick: wrap outgoing only in a fade, incoming in fade+slide.
        return _SwitchTransition(animation: animation, child: child);
      },
      child: child,
    );
  }
}

/// Applies fade+slide for the incoming page and fade-only for the outgoing page.
class _SwitchTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const _SwitchTransition({required this.child, required this.animation});

  @override
  Widget build(BuildContext context) {
    // When animation is going forward (0→1) this is the incoming widget.
    // When it is going in reverse (1→0) this is the outgoing widget.
    // We detect this by checking the animation status.
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (context, animation, child) {
        // Incoming: fade in + slide up
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      reverseBuilder: (context, animation, child) {
        // Outgoing: fade out only (no slide to avoid the "flying away" feel)
        return FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeIn),
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PageFadeSlide
//
// One-shot entrance animation (plays once when the widget first mounts).
// Used for staggered entry of sections within a page (e.g. About screen).
// ─────────────────────────────────────────────────────────────────────────────
class PageFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const PageFadeSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
  });

  @override
  State<PageFadeSlide> createState() => _PageFadeSlideState();
}

class _PageFadeSlideState extends State<PageFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HoverScaleCard
//
// Subtle 1.025× scale-up on mouse hover for interactive cards.
// ─────────────────────────────────────────────────────────────────────────────
class HoverScaleCard extends StatefulWidget {
  final Widget child;
  final double scaleUp;
  final Duration duration;
  final VoidCallback? onTap;

  const HoverScaleCard({
    super.key,
    required this.child,
    this.scaleUp = 1.025,
    this.duration = const Duration(milliseconds: 160),
    this.onTap,
  });

  @override
  State<HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? widget.scaleUp : 1.0,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FadeSlidePageRoute
//
// Reusable PageRouteBuilder for navigating to the CourseScreen (or any other)
// with a smooth fade-in and slight slide-up animation.
// ─────────────────────────────────────────────────────────────────────────────
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: child,
              ),
            );
          },
        );
}
