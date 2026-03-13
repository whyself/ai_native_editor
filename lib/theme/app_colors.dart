// Design tokens for ai_native_editor
// Warm dark mode primary, VS Code-inspired but more scholarly
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Dark Mode ---
  static const darkBackground = Color(0xFF16171A);
  static const darkSurface1 = Color(0xFF1E1F24);   // panels
  static const darkSurface2 = Color(0xFF25262C);   // title bars, elevated
  static const darkSurface3 = Color(0xFF2D2E36);   // hover, selected
  static const darkBorderSubtle = Color(0xFF32333C);
  static const darkBorder = Color(0xFF3C3D47);

  static const darkTextPrimary = Color(0xFFE2E4ED);
  static const darkTextSecondary = Color(0xFF9DA3B4);
  static const darkTextMuted = Color(0xFF5C6070);

  static const darkPrimary = Color(0xFF7C6AF5);
  static const darkPrimaryDim = Color(0xFF5E50C8);
  static const darkPrimaryGlow = Color(0xFF9B8DF7);

  static const darkAiAccent = Color(0xFF4ECDC4);
  static const darkAiDim = Color(0xFF3AADA5);

  static const darkUserBubble = Color(0xFF2A2546);
  static const darkAiBubble = Color(0xFF1A2E2D);

  // --- Light Mode ---
  static const lightBackground = Color(0xFFF4F5F8);
  static const lightSurface1 = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFECEDF2);
  static const lightSurface3 = Color(0xFFE0E1EA);
  static const lightBorderSubtle = Color(0xFFDFE0E9);
  static const lightBorder = Color(0xFFC8CAD8);

  static const lightTextPrimary = Color(0xFF1A1B22);
  static const lightTextSecondary = Color(0xFF5C6070);
  static const lightTextMuted = Color(0xFF9DA3B4);

  static const lightPrimary = Color(0xFF6B5CF0);
  static const lightPrimaryDim = Color(0xFF5044C2);
  static const lightPrimaryGlow = Color(0xFF8A7CF2);

  static const lightAiAccent = Color(0xFF2AAFA6);
  static const lightUserBubble = Color(0xFFEEEBFF);
  static const lightAiBubble = Color(0xFFE6F7F6);

  // --- Semantic ---
  static const success = Color(0xFF6BCB77);
  static const warning = Color(0xFFFFD166);
  static const error = Color(0xFFFF6B6B);

  // --- Drop zone highlight ---
  static const dropHighlight = Color(0x407C6AF5);
  static const dropHighlightBorder = Color(0xFF7C6AF5);
}
