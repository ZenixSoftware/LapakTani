import 'package:flutter/material.dart';

/// Design tokens for LapakTani Fresh Commercial preset
/// Synchronized with Google Stitch project #7886005796293936358
class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF166534); // Deep Forest Green
  static const Color primaryDark = Color(0xFF0D5136); // Spruce Deep Green
  static const Color secondary = Color(0xFF22C55E); // Leaf Green
  static const Color leaf = Color(0xFF22C55E);
  static const Color primaryLight = Color(0xFF22C55E);
  static const Color primaryVibrant = Color(0xFF03AC0E);

  // Accent & Highlights
  static const Color accent = Color(0xFFF59E0B); // Harvest Gold
  static const Color gold = Color(0xFFF59E0B);
  static const Color tertiary = Color(0xFFF59E0B);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8FAF9); // Neutral Light
  static const Color surface = Color(0xFFFFFFFF); // Card Surface
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF0FDF4); // Ultra-soft Mint Tint
  static const Color surfaceSoftBorder = Color(0xFFD1F2D6);
  static const Color surfaceMint = Color(0xFFE8F8EC);

  // Outlines & Dividers
  static const Color outline = Color(0xFFE2E8F0); // Border / Divider
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE2E8F0);

  // Typography & Text
  static const Color textPrimary = Color(0xFF0F172A); // Slate Primary
  static const Color textMuted = Color(0xFF64748B); // Slate Muted
  static const Color textSecondary = Color(0xFF475569);

  // Functional & Semantic
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color errorBorder = Color(0xFFFECACA);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);
  static const Color success = Color(0xFF166534);

  // Soft Ambient BoxShadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x140D5136),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
