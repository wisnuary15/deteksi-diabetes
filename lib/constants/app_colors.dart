import 'package:flutter/material.dart';

/// Modern Color Palette for DeteksiDiabetes App
/// Based on professional design systems like Material 3 and Tailwind CSS
class AppColors {
  // Primary Colors - Medical Blue Palette
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryVariant = Color(0xFF2196F3);

  // Secondary Colors - Accent
  static const Color secondary = Color(0xFF42A5F5);
  static const Color secondaryLight = Color(0xFF90CAF9);
  static const Color secondaryDark = Color(0xFF1976D2);

  // Success Colors - Health Status
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFF10B981);
  static const Color successDark = Color(0xFF047857);
  static const Color successBackground = Color(0xFFECFDF5);

  // Warning Colors - Medium Risk
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningBackground = Color(0xFFFEF3C7);

  // Error Colors - High Risk
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFB91C1C);
  static const Color errorBackground = Color(0xFFFEE2E2);

  // Neutral Colors - Text & Backgrounds
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Surface Colors
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF8FAFC);
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundSecondary = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;

  // Border Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderFocus = Color(0xFF1976D2);

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowMedium = Color(0x29000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  // Medical Status Colors
  static const Color diabetesHigh = Color(0xFFDC2626);
  static const Color diabetesMedium = Color(0xFFF59E0B);
  static const Color diabetesLow = Color(0xFF059669);
  static const Color diabetesUnknown = Color(0xFF64748B);

  // Chat Colors
  static const Color chatUserBubble = Color(0xFF1976D2);
  static const Color chatAiBubble = Color(0xFFF1F5F9);
  static const Color chatUserText = Colors.white;
  static const Color chatAiText = Color(0xFF334155);

  // Icon Colors
  static const Color iconPrimary = Color(0xFF1976D2);
  static const Color iconSecondary = Color(0xFF64748B);
  static const Color iconDisabled = Color(0xFF94A3B8);
  static const Color iconSuccess = Color(0xFF059669);
  static const Color iconWarning = Color(0xFFF59E0B);
  static const Color iconError = Color(0xFFDC2626);

  // Card Colors
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color cardShadow = Color(0x0F000000);

  // Input Colors
  static const Color inputBackground = Color(0xFFF8FAFC);
  static const Color inputBorder = Color(0xFFCBD5E1);
  static const Color inputBorderFocus = Color(0xFF1976D2);
  static const Color inputText = Color(0xFF334155);
  static const Color inputLabel = Color(0xFF64748B);
  static const Color inputHint = Color(0xFF94A3B8);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF1976D2);
  static const Color buttonSecondary = Color(0xFFF1F5F9);
  static const Color buttonDisabled = Color(0xFFCBD5E1);
  static const Color buttonText = Colors.white;
  static const Color buttonTextSecondary = Color(0xFF334155);

  // Status Bar & System UI
  static const Color statusBarLight = Color(0xFFF8FAFC);
  static const Color statusBarDark = Color(0xFF1E293B);

  // Helper method to get risk color
  static Color getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'tinggi':
      case 'high':
        return diabetesHigh;
      case 'sedang':
      case 'medium':
        return diabetesMedium;
      case 'rendah':
      case 'low':
        return diabetesLow;
      default:
        return diabetesUnknown;
    }
  }

  // Helper method to get risk background color
  static Color getRiskBackgroundColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'tinggi':
      case 'high':
        return errorBackground;
      case 'sedang':
      case 'medium':
        return warningBackground;
      case 'rendah':
      case 'low':
        return successBackground;
      default:
        return neutral100;
    }
  }

  // Helper method to get text color for dark backgrounds
  static Color getContrastText(Color backgroundColor) {
    // Calculate luminance to determine if we need light or dark text
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : textOnPrimary;
  }
}
