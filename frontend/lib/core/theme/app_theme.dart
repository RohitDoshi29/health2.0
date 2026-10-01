import 'package:flutter/material.dart';

class AppTheme {
  // Brand futuristic colors
  static const Color primaryGreen = Color(0xFF00F59B);
  static const Color primaryColor = Color(0xFF00F59B);
  static const Color primaryDark = Color(0xFF065F46);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color neonEmerald = Color(0xFF00F59B);
  static const Color neonTeal = Color(0xFF00F0FF);

  // Macro accents
  static const Color calorieColor = Color(0xFFFF8A00); // Radiant orange
  static const Color proteinColor = Color(0xFFFF4D4D); // Coral neon red
  static const Color carbsColor = Color(0xFF00B2FF);   // Electric cyan blue
  static const Color fatColor = Color(0xFFA855F7);     // Neon violet purple
  static const Color fiberColor = Color(0xFF10B981);   // Emerald green
  static const Color waterColor = Color(0xFF06B6D4);   // Aqua water

  // Obsidian cockpit dark surfaces
  static const Color background = Color(0xFF080D0B);
  static const Color bgDark = Color(0xFF050807);
  static const Color surface = Color(0xFF0F1814);
  static const Color surfaceLight = Color(0xFF16231D);
  static const Color cardBg = Color(0xCC111C17);
  static const Color cardBorder = Color(0x2200F59B);
  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x2AFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Gradients
  static const LinearGradient cockpitGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF080D0B),
      Color(0xFF0B1410),
      Color(0xFF07100D),
    ],
  );

  static const LinearGradient emeraldGlow = LinearGradient(
    colors: [Color(0xFF00F59B), Color(0xFF00D47E)],
  );

  static const LinearGradient glassCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x221A2E24),
      Color(0x110F1D17),
    ],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: neonEmerald,
        secondary: neonTeal,
        surface: surface,
        onPrimary: Color(0xFF041A0E),
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonEmerald,
          foregroundColor: const Color(0xFF041A0E),
          minimumSize: const Size(double.infinity, 54),
          elevation: 4,
          shadowColor: const Color(0x6600F59B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x2200F59B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x2200F59B)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: neonEmerald, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xE6080D0B),
        indicatorColor: const Color(0x3300F59B),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: neonEmerald, fontSize: 11, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: textMuted, fontSize: 11);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: neonEmerald);
          }
          return const IconThemeData(color: textMuted);
        }),
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;
}
