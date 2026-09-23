import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/app_alert.dart';
import 'card_header.dart';

class AlertsCard extends StatelessWidget {
  const AlertsCard({super.key, required this.alerts});

  final List<AppAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: 'Alertas',
            subtitle: '${alerts.length} requieren atención',
            trailing: TextButton(onPressed: () => context.go('/alertas'), child: const Text('Ver todas')),
          ),
          for (final a in alerts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: a.severidad.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(a.tipo.icon, size: 18, color: a.severidad.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.mensaje, style: AppTypography.label.copyWith(height: 1.3)),
                        const SizedBox(height: 2),
                        Text(a.accion, style: AppTypography.caption.copyWith(color: AppColors.inkMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
