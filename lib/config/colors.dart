import 'dart:ui';

import 'package:cupid_app/models/user_model.dart';
import 'package:flutter/material.dart';

UserModel? currentUser;

class AppColors {
  // ----------------------------------------------------------
  //  BRAND PRIMARY COLORS (from Puzzle Pics Style Guide)
  // ----------------------------------------------------------
  static const Color puzzleYellow = Color(0xFFFFD52E);
  static const Color primary = Color(0xFFFF3B7A);
  static const Color puzzleRed = Color(0xFFFF4B4B);
  static const Color puzzleBlue = Color(0xFF2EBBFF);
  static const Color puzzleGreen = Color(0xFF4BC463);
  static const Color cameraWhite = Color(0xFFFFFFFF);
  static const Color outlineBlack = Color(0xFF222222);

  // ----------------------------------------------------------
  //  SECONDARY / NEON COLORS (for neon logo + glow UI)
  // ----------------------------------------------------------
  static const Color neonPink = Color(0xFFFF3CF0);
  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color neonGreen = Color(0xFF32FF8A);
  static const Color neonPurpleBG = Color(0xFF5A2EFF); // background purple

  // ----------------------------------------------------------
  //  NEUTRALS
  // ----------------------------------------------------------
  static const Color softCream = Color(0xFFF5F2EB);
  static const Color shadowGray = Color(0xFFA0A0A0);
  static const Color deepNavy = Color(0xFF0D1A3A);

  // ----------------------------------------------------------
  //  BACKGROUND GRADIENTS (updated to match brand + neon logo)
  // ----------------------------------------------------------

  // Dark deep navy → neon purple → magenta vibe
  static const List<Color> backgroundGradient = [
    Color(0xFF0D1A3A),
    Color(0xFF2A1660), // deep purple transition
    Color(0xFF5A2EFF), // brand purple
  ];

  // ----------------------------------------------------------
  //  LOGO-LIKE MULTICOLOR GRADIENT (Blue → Pink)
  // ----------------------------------------------------------
  static const List<Color> logoGradient = [neonBlue, neonPink];

  // ----------------------------------------------------------
  //  BUTTON GRADIENTS (brand-based modern theme)
  // ----------------------------------------------------------

  // Login: Electric Blue → Puzzle Blue
  static const List<Color> loginButtonGradient = [neonBlue, puzzleBlue];

  // Signup: Neon Pink → Puzzle Red
  static const List<Color> signupButtonGradient = [neonPink, puzzleRed];

  // ----------------------------------------------------------
  //  Opacity whites for overlays, blur UI, cards, etc.
  // ----------------------------------------------------------
  static Color white10 = Colors.white.withOpacity(0.10);
  static Color white20 = Colors.white.withOpacity(0.20);
  static Color white40 = Colors.white.withOpacity(0.40);
  static Color white50 = Colors.white.withOpacity(0.50);
  static Color white70 = Colors.white.withOpacity(0.70);

  static const Color white = Colors.white;
}
