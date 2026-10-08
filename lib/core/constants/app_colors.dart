import 'package:flutter/material.dart';

/// Centralized color palette for the SLA Task Tracker.
class AppColors {
  // Brand Palette
  static const Color primary = Color(0xFF4F46E5);       // Indigo 600
  static const Color primaryDark = Color(0xFF3730A3);   // Indigo 800
  static const Color primaryLight = Color(0xFFEEF2FF);  // Indigo 50
  static const Color secondary = Color(0xFF0EA5E9);     // Sky 500
  static const Color accent = Color(0xFF8B5CF6);        // Violet 500

  // SLA Status Colors
  static const Color slaOnTrack = Color(0xFF10B981);    // Emerald 500
  static const Color slaAtRisk = Color(0xFFF59E0B);     // Amber 500
  static const Color slaOverdue = Color(0xFFEF4444);    // Rose / Crimson 500
  static const Color slaCompleted = Color(0xFF6366F1);  // Indigo 500

  // SLA Status Light Backgrounds
  static const Color slaOnTrackBg = Color(0xFFECFDF5);
  static const Color slaAtRiskBg = Color(0xFFFFFBEB);
  static const Color slaOverdueBg = Color(0xFFFEF2F2);
  static const Color slaCompletedBg = Color(0xFFEEF2FF);

  // SLA Status Borders
  static const Color slaOnTrackBorder = Color(0xFFA7F3D0);
  static const Color slaAtRiskBorder = Color(0xFFFDE68A);
  static const Color slaOverdueBorder = Color(0xFFFECACA);
  static const Color slaCompletedBorder = Color(0xFFC7D2FE);

  // Neutral Colors (Light Theme)
  static const Color background = Color(0xFFF8FAFC);    // Slate 50
  static const Color surface = Color(0xFFFFFFFF);       // Pure White
  static const Color surfaceMuted = Color(0xFFF1F5F9);  // Slate 100
  static const Color border = Color(0xFFE2E8F0);        // Slate 200
  static const Color borderSubtle = Color(0xFFF1F5F9);  // Slate 100

  // Neutral Colors (Dark Theme)
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B);    // Slate 800
  static const Color darkSurfaceMuted = Color(0xFF334155);// Slate 700
  static const Color darkBorder = Color(0xFF334155);     // Slate 700

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);   // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textTertiary = Color(0xFF94A3B8);  // Slate 400
  static const Color textOnPrimary = Colors.white;

  // Text Colors (Dark Theme)
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
}
