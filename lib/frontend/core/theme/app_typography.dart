import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografía corporativa de Puerta Liverpool: Montserrat (geométrica y
/// limpia), servida por google_fonts. Todos los estilos parten de [_base].
abstract final class AppTypography {
  static TextStyle get _base => GoogleFonts.montserrat(color: AppColors.ink);

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

  /// Tema de texto global: los widgets sin estilo propio heredan Montserrat.
  static TextTheme textTheme() => GoogleFonts.montserratTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      );
}
