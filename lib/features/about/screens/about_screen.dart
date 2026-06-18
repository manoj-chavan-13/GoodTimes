import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goodtimes/core/themes/app_colors.dart';
import 'package:goodtimes/widgets/animations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Title ────────────────────────────────────────────────
            PageFadeSlide(
              delay: const Duration(milliseconds: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Learn more about GoodTime and the person who built it.',
                    style: TextStyle(color: AppColors.textMuted(context), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── App Hero Card ─────────────────────────────────────────────
            PageFadeSlide(
              delay: const Duration(milliseconds: 80),
              child: _AppHeroCard(isDark: isDark),
            ),
            const SizedBox(height: 24),

            // ── Features Grid ─────────────────────────────────────────────
            PageFadeSlide(
              delay: const Duration(milliseconds: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(context: context, title: 'What GoodTime Offers'),
                  const SizedBox(height: 12),
                  _FeaturesGrid(isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Tech Stack ────────────────────────────────────────────────
            PageFadeSlide(
              delay: const Duration(milliseconds: 240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(context: context, title: 'Built With'),
                  const SizedBox(height: 12),
                  _TechStackCard(isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Founder Card ─────────────────────────────────────────────
            PageFadeSlide(
              delay: const Duration(milliseconds: 320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(context: context, title: 'The Creator'),
                  const SizedBox(height: 12),
                  _FounderCard(isDark: isDark, onCopy: _copyToClipboard),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Footer ────────────────────────────────────────────────────
            PageFadeSlide(
              delay: const Duration(milliseconds: 400),
              child: Center(
                child: Text(
                  '© 2026 GoodTime. Made with ❤️ for focused learners.',
                  style: TextStyle(color: AppColors.textFaint(context), fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Hero Card
// ─────────────────────────────────────────────────────────────────────────────
class _AppHeroCard extends StatelessWidget {
  final bool isDark;
  const _AppHeroCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.primary.withOpacity(0.18), AppColors.primary.withOpacity(0.04)]
              : [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.01)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.25 : 0.18),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // App Icon with glow
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(isDark ? 0.35 : 0.15),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Image.asset(
              'lib/assets/icon.png',
              height: 72,
              width: 72,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.play_circle_fill, size: 72, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 24),

          // App details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GoodTime',
                  style: TextStyle(
                    color: AppColors.text(context),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Offline Course Media Player',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'v1.0.2 Stable  •  Windows Desktop',
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A professional desktop media player built for structured, distraction-free learning. '
                  'GoodTime automatically organises your local video courses, tracks watch progress, '
                  'supports multiple playback speeds, keyboard shortcuts, and seamless auto-resume — '
                  'all offline, all private, all yours.',
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Features Grid
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturesGrid extends StatelessWidget {
  final bool isDark;
  const _FeaturesGrid({required this.isDark});

  static const _features = [
    {
      'icon': Icons.folder_special_outlined,
      'title': 'Auto Library Scan',
      'desc': 'Point GoodTime at any folder — it detects courses, modules and lectures automatically.',
    },
    {
      'icon': Icons.bookmark_added_outlined,
      'title': 'Smart Progress Tracking',
      'desc': 'Every second of every lecture is logged. Lectures watched >90% are auto-marked complete.',
    },
    {
      'icon': Icons.history_edu_outlined,
      'title': 'Instant Auto-Resume',
      'desc': 'Close the app, come back later — you are always dropped back exactly where you left off.',
    },
    {
      'icon': Icons.speed_outlined,
      'title': 'Variable Playback Speed',
      'desc': 'Keyboard shortcuts let you speed through reviews or slow down complex concepts instantly.',
    },
    {
      'icon': Icons.picture_in_picture_alt_outlined,
      'title': 'Fullscreen Player',
      'desc': 'Distraction-free fullscreen mode with overlay controls that fade away while you focus.',
    },
    {
      'icon': Icons.lock_outline,
      'title': '100% Offline & Private',
      'desc': 'Zero cloud, zero accounts. Your courses and progress never leave your machine.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.55,
      ),
      itemCount: _features.length,
      itemBuilder: (context, i) {
        final f = _features[i];
        return HoverScaleCard(
          scaleUp: 1.03,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(f['icon'] as IconData, color: AppColors.primary, size: 24),
                const SizedBox(height: 10),
                Text(
                  f['title'] as String,
                  style: TextStyle(
                    color: AppColors.text(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    f['desc'] as String,
                    style: TextStyle(
                      color: AppColors.textMuted(context),
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tech Stack Card
// ─────────────────────────────────────────────────────────────────────────────
class _TechStackCard extends StatelessWidget {
  final bool isDark;
  const _TechStackCard({required this.isDark});

  static const _stack = [
    {'label': 'Framework', 'value': 'Flutter 3.x — Windows native desktop platform'},
    {'label': 'Media Engine', 'value': 'media_kit (libmpv) — High-performance C video decoder'},
    {'label': 'State Management', 'value': 'Flutter Riverpod — Reactive Notifier Providers'},
    {'label': 'Local Database', 'value': 'Hive NoSQL — Ultra-fast persistent watch-state cache'},
    {'label': 'Language', 'value': 'Dart 3.x — Strongly typed, null-safe'},
    {'label': 'Platform', 'value': 'Windows 10 / 11 x64 — Native Win32 integration'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: _stack.asMap().entries.map((entry) {
          final isLast = entry.key == _stack.length - 1;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        item['label']!,
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item['value']!,
                        style: TextStyle(color: AppColors.text(context), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  height: 1,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Founder Card
// ─────────────────────────────────────────────────────────────────────────────
class _FounderCard extends StatefulWidget {
  final bool isDark;
  final void Function(BuildContext, String, String) onCopy;
  const _FounderCard({required this.isDark, required this.onCopy});

  @override
  State<_FounderCard> createState() => _FounderCardState();
}

class _FounderCardState extends State<_FounderCard> {
  String? _hoveredButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(widget.isDark ? 0.2 : 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(widget.isDark ? 0.08 : 0.03),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Name & title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manoj Chavan',
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Full-Stack Developer & Creator of GoodTime',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Passionate about building tools that make focused, self-directed learning more effective and enjoyable.',
                      style: TextStyle(
                        color: AppColors.textMuted(context),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Divider
          Divider(
            color: widget.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
            height: 1,
          ),
          const SizedBox(height: 20),

          // Link buttons row
          Row(
            children: [
              Expanded(
                child: _LinkButton(
                  icon: Icons.code,
                  label: 'GitHub',
                  value: 'github.com/manoj-chavan-13',
                  hoverColor: const Color(0xFF2DA44E),
                  isDark: widget.isDark,
                  isHovered: _hoveredButton == 'github',
                  onHoverChange: (h) => setState(() => _hoveredButton = h ? 'github' : null),
                  onTap: () => widget.onCopy(context, 'https://github.com/manoj-chavan-13', 'GitHub URL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LinkButton(
                  icon: Icons.work_outline,
                  label: 'LinkedIn',
                  value: 'linkedin.com/in/manoj-chavan-13',
                  hoverColor: const Color(0xFF0A66C2),
                  isDark: widget.isDark,
                  isHovered: _hoveredButton == 'linkedin',
                  onHoverChange: (h) => setState(() => _hoveredButton = h ? 'linkedin' : null),
                  onTap: () => widget.onCopy(context, 'https://www.linkedin.com/in/manoj-chavan-13/', 'LinkedIn URL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LinkButton(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: 'manojchavan1302@gmail.com',
                  hoverColor: AppColors.primary,
                  isDark: widget.isDark,
                  isHovered: _hoveredButton == 'email',
                  onHoverChange: (h) => setState(() => _hoveredButton = h ? 'email' : null),
                  onTap: () => widget.onCopy(context, 'manojchavan1302@gmail.com', 'Email'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '💡 Tap any button above to copy the link / email to your clipboard.',
              style: TextStyle(
                color: AppColors.textFaint(context),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Link Button
// ─────────────────────────────────────────────────────────────────────────────
class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color hoverColor;
  final bool isDark;
  final bool isHovered;
  final ValueChanged<bool> onHoverChange;
  final VoidCallback onTap;

  const _LinkButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.hoverColor,
    required this.isDark,
    required this.isHovered,
    required this.onHoverChange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHoverChange(true),
      onExit: (_) => onHoverChange(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isHovered
                ? hoverColor.withOpacity(isDark ? 0.18 : 0.10)
                : AppColors.bg(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHovered
                  ? hoverColor.withOpacity(0.45)
                  : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07)),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18,
                  color: isHovered ? hoverColor : AppColors.textMuted(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isHovered ? hoverColor : AppColors.text(context),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.textFaint(context),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.copy, size: 14, color: AppColors.textFaint(context)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Title helper
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final BuildContext context;
  final String title;
  const _SectionTitle({required this.context, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.text(context),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
      ),
    );
  }
}
