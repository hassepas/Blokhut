import 'package:flutter/material.dart';

class StudyBuddyTheme {
  static const _bg = Color(0xFFF7F5F1); // gebroken wit
  static const _text = Color(0xFF3B3B3B); // donkergrijs

  // Pastel accenten
  static const mint = Color(0xFF8AD7C1);
  static const pastelYellow = Color(0xFFF6D985);
  static const peach = Color(0xFFF6B5A7);
  static const lavendel = Color(0xFFC7B6FF);
  static const pastelPink = Color(0xFFFFB6C9);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: mint, background: _bg),
      scaffoldBackgroundColor: _bg,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: _text),
        bodyLarge: TextStyle(color: _text),
        titleLarge: TextStyle(color: _text, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: _text, fontWeight: FontWeight.w600),
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: _bg,
        foregroundColor: _text,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: Colors.white.withOpacity(0.85),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }
}
