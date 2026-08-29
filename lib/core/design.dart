import 'package:flutter/material.dart';

/// Design tokens for the Juicy Tropic premium-minimal shell.
class D {
  D._();

  // Canvas
  static const ink = Color(0xFF05090C);
  static const inkSoft = Color(0xFF0A1116);
  static const inkLift = Color(0xFF101A20);

  // Accents
  static const lime = Color(0xFFC7F94F);
  static const teal = Color(0xFF35E0C0);
  static const gold = Color(0xFFF2C063);
  static const coral = Color(0xFFFF6B5A);
  static const violet = Color(0xFF9B8CFF);
  static const sky = Color(0xFF4FC3F7);

  // Text
  static const text = Color(0xFFF1F6F3);
  static const textDim = Color(0xFF9AACA6);
  static const textFaint = Color(0xFF64756F);

  static Color glass(double a) => Colors.white.withValues(alpha: a);
  static Color hairline([double a = 0.10]) => Colors.white.withValues(alpha: a);

  static const rSm = 12.0;
  static const rMd = 18.0;
  static const rLg = 26.0;
  static const rXl = 34.0;

  static const gap = 12.0;

  static const softShadow = <BoxShadow>[
    BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 14)),
  ];

  static TextStyle display(double size, {Color color = text, double wght = 700}) {
    return TextStyle(
      fontFamily: 'Sora',
      fontSize: size,
      height: 1.02,
      color: color,
      letterSpacing: -size * 0.028,
      fontVariations: [FontVariation('wght', wght)],
      fontWeight: _weightOf(wght),
    );
  }

  static TextStyle label(double size, {Color color = text, double wght = 700, double tracking = 0.6}) {
    return TextStyle(
      fontFamily: 'Manrope',
      fontSize: size,
      height: 1.1,
      color: color,
      letterSpacing: tracking,
      fontVariations: [FontVariation('wght', wght)],
      fontWeight: _weightOf(wght),
    );
  }

  static TextStyle body(double size, {Color color = textDim, double wght = 500}) {
    return TextStyle(
      fontFamily: 'Manrope',
      fontSize: size,
      height: 1.42,
      color: color,
      fontVariations: [FontVariation('wght', wght)],
      fontWeight: _weightOf(wght),
    );
  }

  /// Numbers that never jitter while counting up.
  static TextStyle numeric(double size, {Color color = text, double wght = 700}) {
    return TextStyle(
      fontFamily: 'Sora',
      fontSize: size,
      height: 1.0,
      color: color,
      letterSpacing: -size * 0.02,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontVariations: [FontVariation('wght', wght)],
      fontWeight: _weightOf(wght),
    );
  }

  static FontWeight _weightOf(double wght) {
    if (wght >= 800) return FontWeight.w800;
    if (wght >= 700) return FontWeight.w700;
    if (wght >= 600) return FontWeight.w600;
    if (wght >= 500) return FontWeight.w500;
    return FontWeight.w400;
  }

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      canvasColor: ink,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: lime,
        secondary: teal,
        surface: inkSoft,
        onPrimary: ink,
      ),
      textTheme: TextTheme(
        bodyMedium: body(14),
        titleMedium: label(15),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: inkLift,
        contentTextStyle: body(13, color: text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
      ),
    );
  }
}
