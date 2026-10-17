import 'package:flutter/material.dart';

/// Minimalist inDrive-inspired color palette for PothikSathi:
/// High-contrast obsidian blacks, electric lime accents, crisp whites,
/// and soft graphite neutrals for outdoor daylight clarity.
class AppColors {
  // inDrive Signature Accents
  static const Color brandLime = Color(0xFFB8EE00);        // Iconic inDrive Electric Lime
  static const Color brandLimeDark = Color(0xFF96C900);    // Deep Chartreuse
  static const Color brandLimeTint = Color(0xFFF3FCD0);    // Soft Lime Card Tint
  static const Color brandBlack = Color(0xFF121212);       // Deep Obsidian / Jet Black
  static const Color brandCharcoal = Color(0xFF1E1E22);    // Elevated Surface Charcoal

  // Primary Theme Aliases (Mapped to inDrive aesthetic)
  static const Color primary = Color(0xFF121212);          // Modern high-contrast dark primary
  static const Color primaryLight = Color(0xFF2A2A2E);     // Dark charcoal secondary
  static const Color primaryTint = Color(0xFFF2FCDA);      // Subtle lime-green background tint
  static const Color accent = Color(0xFFB8EE00);           // High-energy inDrive Lime

  // Clean Minimalist Neutrals
  static const Color background = Color(0xFFF7F8FA);       // Crisp off-white canvas
  static const Color surface = Color(0xFFFFFFFF);          // Pure white card surface
  static const Color surfaceSubtle = Color(0xFFF2F4F7);    // Soft grey input & pill surface
  static const Color textPrimary = Color(0xFF111827);      // Deep obsidian near-black
  static const Color textSecondary = Color(0xFF6B7280);    // Muted slate graphite
  static const Color textLight = Color(0xFF9CA3AF);        // Subtle placeholder grey
  static const Color border = Color(0xFFE5E7EB);           // Hairline modern border
  static const Color divider = Color(0xFFF3F4F6);          // Soft separator line

  // Operational State Badges
  static const Color statusPending = Color(0xFFF59E0B);    // Warm Amber
  static const Color statusAssigned = Color(0xFF2563EB);   // Electric Blue
  static const Color statusAccepted = Color(0xFF10B981);   // Confirmed Emerald Green
  static const Color statusArrived = Color(0xFF059669);    // Ready Pine Green
  static const Color statusActive = Color(0xFF121212);     // On-Trip Obsidian
  static const Color statusCompleted = Color(0xFF10B981);  // Success Emerald Green
  static const Color statusCancelled = Color(0xFFEF4444);  // Clean Warning Red

  // Service Badges
  static const Color totoBadgeBg = Color(0xFFF2FCDA);
  static const Color totoBadgeText = Color(0xFF121212);
  static const Color busBadgeBg = Color(0xFFEFF6FF);
  static const Color busBadgeText = Color(0xFF1D4ED8);
}
