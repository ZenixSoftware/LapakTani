import 'package:flutter/material.dart';

/// Canonical Design Tokens for LapakTani Agri-Commerce (White-Dominant 4-Color System)
/// Synchronized with design_specs/DESIGN.md and lapaktani_web/src/index.css
/// Single Source of Truth for all Flutter widgets.
class AppColors {
  AppColors._();

  // 1. Primary: Hijau Soft / Nature Foliage
  static const Color primary = Color(0xFF388E5C);
  static const Color primaryDark = Color(0xFF2E754C);
  static const Color primaryTint = Color(0xFFEFF6F1);
  static const Color primaryBorder = Color(0xFFCFE3D6);

  // 2. Secondary: Biru Air / Irigasi
  static const Color secondary = Color(0xFF2B7A9E);
  static const Color secondaryDark = Color(0xFF22627F);
  static const Color secondaryTint = Color(0xFFEAF3F7);
  static const Color secondaryBorder = Color(0xFFC9E0EA);

  // 3. Tertiary: Kuning Padi Panen (use tertiaryText for light-surface typography)
  static const Color tertiary = Color(0xFFE5A93B);
  static const Color tertiaryText = Color(0xFF8A5E00);
  static const Color tertiaryTint = Color(0xFFFDF6EA);
  static const Color tertiaryBorder = Color(0xFFF3DDB0);

  // 4. Neutral: Cokelat Tanah Subur
  static const Color neutral = Color(0xFF3D3228);
  static const Color neutralMuted = Color(0xFF6E6259);
  static const Color neutralSubtle = Color(0xFFA39890);
  static const Color neutralBorder = Color(0xFFD8CFCA);

  // Surfaces, Borders & Semantic Error
  static const Color border = Color(0xFFE2E8E4);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceCanvas = Color(0xFFF8FAF6);
  static const Color error = Color(0xFFC94A29);
  static const Color errorTint = Color(0xFFFBEDE9);
  static const Color errorBorder = Color(0xFFF0C3B6);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Shadow & Scrim Tokens
  static const Color shadowFaint = Color(0x0A3D3228);
  static const Color shadowMedium = Color(0x143D3228);
  static const Color scrim = Color(0x603D3228);

  // Legacy aliases (mapped automatically to canonical tokens)
  static const Color primaryLight = primary; // legacy alias
  static const Color primaryVibrant = primary; // legacy alias
  static const Color leaf = primary; // legacy alias
  static const Color success = primary; // legacy alias
  static const Color accent = tertiary; // legacy alias
  static const Color gold = tertiary; // legacy alias
  static const Color background = surfaceCanvas; // legacy alias
  static const Color surface = surfaceCard; // legacy alias
  static const Color card = surfaceCard; // legacy alias
  static const Color surfaceSoft = primaryTint; // legacy alias
  static const Color surfaceMint = primaryTint; // legacy alias
  static const Color surfaceSoftBorder = primaryBorder; // legacy alias
  static const Color outline = border; // legacy alias
  static const Color divider = border; // legacy alias
  static const Color textPrimary = neutral; // legacy alias
  static const Color textMuted = neutralMuted; // legacy alias
  static const Color textSecondary = neutralMuted; // legacy alias
  static const Color errorSoft = errorTint; // legacy alias
  static const Color warning = tertiaryText; // legacy alias
  static const Color warningSoft = tertiaryTint; // legacy alias
  static const Color info = secondary; // legacy alias
  static const Color infoSoft = secondaryTint; // legacy alias

  // Subtle Flat Shadows (max blur 8)
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: shadowFaint,
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: shadowFaint,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: shadowMedium,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
}
