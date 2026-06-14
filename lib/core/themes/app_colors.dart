import 'package:flutter/material.dart';

/// Central color system - dark theme keeps premium, layered slate-grey / steel-grey
/// shades (similar to VS Code / GitHub dark theme) for professional contrast and comfort.
/// Light theme uses a clean, high-contrast professional look.
class AppColors {
  // Primary accent (Premium Brand Red)
  static const Color primary = Color(0xFFDC2626);

  // ── Semantic helpers ──────────────────────────────────────────
  static Color bg(BuildContext ctx) =>
      _dark(ctx) ? const Color(0xFF222228) : const Color(0xFFF9FAFB);

  static Color sidebar(BuildContext ctx) =>
      _dark(ctx) ? const Color(0xFF1B1B1F) : Colors.white;

  static Color card(BuildContext ctx) =>
      _dark(ctx) ? const Color(0xFF2C2C35) : Colors.white;

  static Color text(BuildContext ctx) =>
      _dark(ctx) ? const Color(0xFFF5F5F7) : const Color(0xFF111827);

  static Color textMuted(BuildContext ctx) =>
      _dark(ctx) ? const Color(0xFF9EABB8) : const Color(0xFF4B5563);

  static Color textFaint(BuildContext ctx) =>
      _dark(ctx) ? const Color(0xFF6B7A87) : const Color(0xFF9CA3AF);

  static Color border(BuildContext ctx) =>
      _dark(ctx) ? const Color(0xFF3F3F4D) : const Color(0xFFE5E7EB);

  static Color borderStrong(BuildContext ctx) =>
      _dark(ctx) ? const Color(0xFF4D4D5E) : const Color(0xFFD1D5DB);

  static Color overlay(BuildContext ctx) =>
      _dark(ctx) ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.3);

  static Color sidebarSelected(BuildContext ctx) =>
      _dark(ctx) ? const Color(0xFF383842) : const Color(0xFFF3F4F6);

  static Color sidebarBorder(BuildContext ctx) =>
      primary;

  static Color iconActive(BuildContext ctx) =>
      _dark(ctx) ? const Color(0xFFF5F5F7) : const Color(0xFF111827);

  static Color iconMuted(BuildContext ctx) =>
      _dark(ctx) ? const Color(0xFF6B7A87) : const Color(0xFF9CA3AF);

  static Color scanBtn(BuildContext ctx) =>
      _dark(ctx) ? const Color(0xFF2C2C35) : const Color(0xFFF3F4F6);

  static Color scanBtnText(BuildContext ctx) =>
      _dark(ctx) ? const Color(0xFFF5F5F7) : const Color(0xFF111827);

  static bool _dark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;
}
