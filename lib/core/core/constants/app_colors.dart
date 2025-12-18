import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF6750A4);
  static const Color primaryLight = Color(0xFF9A82DB);
  static const Color primaryDark = Color(0xFF381E72);

  // Secondary Colors
  static const Color secondary = Color(0xFF625B71);
  static const Color secondaryLight = Color(0xFF7D5260);

  // Surface Colors
  static const Color surface = Color(0xFFFFFBFE);
  static const Color surfaceDark = Color(0xFF1C1B1F);
  static const Color surfaceContainer = Color(0xFFF3EDF7);
  static const Color surfaceContainerDark = Color(0xFF2B2930);

  // Message Bubble Colors
  static const Color bubbleSent = Color(0xFF6750A4);
  static const Color bubbleReceived = Color(0xFFE8E0E5);
  static const Color bubbleReceivedDark = Color(0xFF49454F);

  // Text Colors
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textPrimaryDark = Color(0xFFE6E1E5);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color textSecondaryDark = Color(0xFFCAC4D0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textHint = Color(0xFF79747E);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFB3261E);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF2196F3);

  // Divider & Border
  static const Color divider = Color(0xFFCAC4D0);
  static const Color dividerDark = Color(0xFF49454F);
  static const Color border = Color(0xFF79747E);

  // Gradient Colors
  static const Color gradientStart = Color(0xFF6750A4);
  static const Color gradientEnd = Color(0xFF625B71);

  // Opacity helpers
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // Theme-aware getters
  static Color bubbleReceivedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? bubbleReceivedDark
        : bubbleReceived;
  }

  static Color textPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimaryDark
        : textPrimary;
  }

  static Color textSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondaryDark
        : textSecondary;
  }

  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : surface;
  }

  static Color surfaceContainerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceContainerDark
        : surfaceContainer;
  }

  static Color dividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? dividerDark
        : divider;
  }
}