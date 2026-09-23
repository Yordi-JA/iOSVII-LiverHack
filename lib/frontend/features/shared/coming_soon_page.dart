import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_text.dart';

/// Marcador para los módulos que aún no se construyen.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, required this.description, required this.icon});

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(40),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GradientMask(child: Icon(icon, size: 48)),
              const SizedBox(height: 16),
              Text(title, style: AppTypography.display),
              const SizedBox(height: 8),
              Text(description, style: AppTypography.body, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text('Módulo en construcción', style: AppTypography.caption),
            ],
          ),
        ),
      ),
    );
  }
}
