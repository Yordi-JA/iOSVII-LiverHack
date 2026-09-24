import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.arrow_forward_rounded,
    this.enabled = true,
    this.large = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;

  /// Versión grande para la acción principal de una pantalla.
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.brandGradientHorizontal,
            borderRadius: BorderRadius.circular(large ? 20 : 14),
            boxShadow: [
              BoxShadow(
                color: AppColors.magenta.withValues(alpha: large ? 0.38 : 0.3),
                blurRadius: large ? 24 : 14,
                offset: Offset(0, large ? 10 : 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(large ? 20 : 14),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: large
                  ? const EdgeInsets.symmetric(vertical: 22, horizontal: 28)
                  : const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: (large ? AppTypography.title : AppTypography.label).copyWith(
                        color: Colors.white,
                        fontWeight: large ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    SizedBox(width: large ? 10 : 6),
                    Icon(icon, color: Colors.white, size: large ? 24 : 18),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassOutlineButton extends StatelessWidget {
  const GlassOutlineButton({super.key, required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: Colors.white.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        side: const BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
