import 'package:flutter/material.dart';

/// Clean, high-contrast, green-and-white color palette optimized for 
/// outdoor readability in bright daylight and low visual clutter.
class AppColors {
  // Primary Greens
  static const Color primary = Color(0xFF1B5E20);       // Deep Bengal Forest Green
  static const Color primaryLight = Color(0xFF2E7D32);  // Rich Emerald Green
  static const Color primaryTint = Color(0xFFE8F5E9);   // Light Mint Background Tint
  static const Color accent = Color(0xFF43A047);        // Vivid Green Accent

  // Clean Neutrals
  static const Color background = Color(0xFFF8FAF8);    // Crisp Off-White
  static const Color surface = Color(0xFFFFFFFF);       // Pure White Card Surface
  static const Color textPrimary = Color(0xFF1E261E);   // High-contrast near-black
  static const Color textSecondary = Color(0xFF5E6D5E); // Subtle graphite grey
  static const Color textLight = Color(0xFF8D9A8D);     // Secondary placeholder
  static const Color border = Color(0xFFE0E7E0);        // Soft structural border
  static const Color divider = Color(0xFFEEF2EE);       // Hairline divider

  // Operational State Badges
  static const Color statusPending = Color(0xFFEF6C00);   // Amber Orange
  static const Color statusAssigned = Color(0xFF0277BD);  // Informational Sky Blue
  static const Color statusAccepted = Color(0xFF2E7D32);  // Confirmed Green
  static const Color statusArrived = Color(0xFF558B2F);   // Ready Lime Green
  static const Color statusActive = Color(0xFF00695C);    // On-Trip Teal
  static const Color statusCompleted = Color(0xFF2E7D32); // Success Green
  static const Color statusCancelled = Color(0xFFC62828); // Error Red

  // Service Badges
  static const Color totoBadgeBg = Color(0xFFE8F5E9);
  static const Color totoBadgeText = Color(0xFF1B5E20);
  static const Color busBadgeBg = Color(0xFFE3F2FD);
  static const Color busBadgeText = Color(0xFF0D47A1);
}
