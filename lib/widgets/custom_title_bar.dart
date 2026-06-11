import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatefulWidget {
  final bool isTransparent;
  final String? title;
  
  const CustomTitleBar({
    super.key, 
    this.isTransparent = false,
    this.title,
  });

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> {
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
    return Container(
      height: 24, // Minimal height
      decoration: BoxDecoration(
        color: widget.isTransparent ? Colors.transparent : const Color(0xFF141414),
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
                        style: const TextStyle(
                          color: Colors.white70,
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
                Container(width: 10, height: 1, color: Colors.white70),
                () => windowManager.minimize(),
              ),
              _buildBtn(
                _isMaximized
                    ? Stack(
                        children: [
                          Positioned(top: 0, right: 0, child: Container(width: 8, height: 8, decoration: BoxDecoration(border: Border.all(color: Colors.white70, width: 1)))),
                          Positioned(bottom: 0, left: 0, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.isTransparent ? Colors.transparent : const Color(0xFF141414), border: Border.all(color: Colors.white70, width: 1)))),
                        ],
                      )
                    : Container(width: 10, height: 10, decoration: BoxDecoration(border: Border.all(color: Colors.white70, width: 1))),
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
                const Icon(Icons.close, color: Colors.white70, size: 14),
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
        hoverColor: isClose ? const Color(0xFFE81123) : Colors.white.withOpacity(0.1),
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
