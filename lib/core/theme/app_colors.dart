import 'package:flutter/material.dart';

/// Paleta de Pulso inspirada en El Puerto de Liverpool:
/// morado → rosa Liverpool → naranja.
abstract final class AppColors {
  static const purple = Color(0xFF6B2BD9);
  static const magenta = Color(0xFFE10098);
  static const orange = Color(0xFFFF7A1A);

  static const ink = Color(0xFF1C1B2E);
  static const inkSoft = Color(0xFF6B6A80);
  static const inkMuted = Color(0xFFA3A2B5);

  static const success = Color(0xFF1FA971);
  static const warning = Color(0xFFF2A516);
  static const danger = Color(0xFFE5484D);
  static const info = Color(0xFF3B82F6);

  static const bgTop = Color(0xFFF1ECFB);
  static const bgMiddle = Color(0xFFFBEFF5);
  static const bgBottom = Color(0xFFFFF3EA);

  static const brandGradient = LinearGradient(
    colors: [purple, magenta, orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const brandGradientHorizontal = LinearGradient(
    colors: [purple, magenta, orange],
  );

  /// Tonos pastel para los avatares de candidatos.
  static const avatarTints = [
    Color(0xFFE9DEFF),
    Color(0xFFFFDDF0),
    Color(0xFFFFE6D3),
    Color(0xFFDDF3EA),
    Color(0xFFDDE9FF),
  ];
}
