import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Brand Colors ---
  static const Color primary = Color(0xFF4F46E5); // Modern Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color secondary = Color(0xFF0D9488); // Teal for accents

  // --- Status Colors ---
  static const Color success = Color(0xFF10B981); // Resolved / Closed
  static const Color warning = Color(0xFFF59E0B); // In Progress
  static const Color error = Color(0xFFEF4444);   // Open / High Priority
  static const Color info = Color(0xFF3B82F6);    // New / Info

  // --- Light Theme Colors ---
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500

  // --- Dark Theme Colors ---
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
}