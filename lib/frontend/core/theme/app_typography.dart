import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografía estilo Apple (SF Pro). Inter es la alternativa libre más
/// cercana; el tracking negativo en títulos imita a SF Display.
abstract final class AppTypography {
  static TextStyle get _base => GoogleFonts.inter(color: AppColors.ink);

  static TextStyle get display => _base.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
        height: 1.1,
      );

  static TextStyle get title => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      );

  static TextStyle get headline => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );

  static TextStyle get body => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.45,
      );

  static TextStyle get label => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
      );

  static TextStyle get caption => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.inkSoft,
      );

  static TextStyle get metric => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        height: 1,
      );

  static TextTheme textTheme() => GoogleFonts.interTextTheme().apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      );
}
