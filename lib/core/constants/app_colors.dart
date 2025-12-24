/// App Colors
///
/// Defines the color palette for FasalPlanner app
/// Based on the green farming theme from the design

import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryGreenDark = Color(0xFF1B5E20);
  static const Color primaryGreenLight = Color(0xFF4CAF50);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF1F8E9);
  static const Color backgroundGradientStart = Color(0xFFF1F8E9);
  static const Color backgroundGradientEnd = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1B5E20);
  static const Color textSecondary = Color(0xFF558B2F);
  static const Color textDark = Color(0xFF212121);
  static const Color textGrey = Color(0xFF757575);

  // Accent Colors
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentRed = Color(0xFFF44336);

  // Card Colors
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE0E0E0);

  // Weather Card Colors
  static const Color weatherSunny = Color(0xFFFFC107);
  static const Color weatherRainy = Color(0xFF42A5F5);
  static const Color weatherCloudy = Color(0xFF90A4AE);

  // Gradient for background
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundGradientStart, backgroundGradientEnd],
  );
}
