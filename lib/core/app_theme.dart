import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFFFF8F5);
  static const primaryPink = Color(0xFFFF6B8A);
  static const secondaryPink = Color(0xFFFFB3C1);
  static const illustrationBox = Color(0xFFFFE8EC);
  static const textMain = Color(0xFF2A2A2A);
  static const textMuted = Color(0xFF7A7A7A);
  static const divider = Color(0xFFE0E0E0);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryPink),
        useMaterial3: true,
      );
}
