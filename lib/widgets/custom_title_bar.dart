import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:goodtimes/providers/theme_provider.dart';
import 'package:goodtimes/core/themes/app_colors.dart';

class CustomTitleBar extends ConsumerStatefulWidget {
  final bool isTransparent;
  final String? title;
  
  const CustomTitleBar({
    super.key, 
    this.isTransparent = false,
    this.title,
  });

  @override
  ConsumerState<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends ConsumerState<CustomTitleBar> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _checkMaximized();
  }

  Future<void> _checkMaximized() async {
    bool isMax = await windowManager.isMaximized();
    if (mounted) setState(() => _isMaximized = isMax);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 24, // Minimal height
      decoration: BoxDecoration(
        color: widget.isTransparent ? Colors.transparent : AppColors.bg(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (details) => windowManager.startDragging(),
              onDoubleTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.only(left: 16),
                alignment: Alignment.centerLeft,
                child: widget.title != null
                    ? Text(
                        widget.title!,
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox(),
              ),
            ),
          ),
          Row(
            children: [
              _buildBtn(
                Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: AppColors.textMuted(context), size: 14),
                () => ref.read(themeProvider.notifier).toggleTheme(),
              ),
              _buildBtn(
                Container(width: 10, height: 1, color: AppColors.textMuted(context)),
                () => windowManager.minimize(),
              ),
              _buildBtn(
                _isMaximized
                    ? Stack(
                        children: [
                          Positioned(top: 0, right: 0, child: Container(width: 8, height: 8, decoration: BoxDecoration(border: Border.all(color: AppColors.textMuted(context), width: 1)))),
                          Positioned(bottom: 0, left: 0, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.isTransparent ? Colors.transparent : theme.scaffoldBackgroundColor, border: Border.all(color: AppColors.textMuted(context), width: 1)))),
                        ],
                      )
                    : Container(width: 10, height: 10, decoration: BoxDecoration(border: Border.all(color: AppColors.textMuted(context), width: 1))),
                () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.unmaximize();
                    setState(() => _isMaximized = false);
                  } else {
                    windowManager.maximize();
                    setState(() => _isMaximized = true);
                  }
                },
              ),
              _buildBtn(
                Icon(Icons.close, color: AppColors.textMuted(context), size: 14),
                () => windowManager.close(),
                isClose: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBtn(Widget iconWidget, VoidCallback onTap, {bool isClose = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: isClose ? const Color(0xFFE81123) : AppColors.borderStrong(context),
        child: SizedBox(
          width: 46,
          height: 24,
          child: Center(
            child: SizedBox(
              width: 12,
              height: 12,
              child: Center(child: iconWidget),
            ),
          ),
        ),
      ),
    );
  }
}
