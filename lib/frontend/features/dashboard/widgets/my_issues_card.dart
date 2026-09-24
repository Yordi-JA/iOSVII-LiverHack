import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../candidatos/widgets/ui_kit.dart' show CColors;
import 'card_header.dart';

/// Pendiente de "Mis asuntos".
typedef Asunto = ({IconData icon, Color color, String titulo, String detalle});

/// Pendientes del día según el rol (las reglas viven en dashboard_page.dart).
class MyIssuesCard extends StatelessWidget {
  const MyIssuesCard({super.key, required this.asuntos, required this.subtitulo});

  final List<Asunto> asuntos;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(title: 'Mis asuntos', subtitle: subtitulo),
          if (asuntos.isEmpty)
            Text('Sin pendientes por hoy.', style: AppTypography.body.copyWith(color: AppColors.inkMuted))
          else
            for (final (i, a) in asuntos.indexed)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: i == asuntos.length - 1 ? null : const Border(bottom: BorderSide(color: CColors.line)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(a.icon, size: 18, color: a.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.titulo, style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
                          if (a.detalle.isNotEmpty)
                            Text(
                              a.detalle,
                              style: AppTypography.caption.copyWith(fontSize: 12.5, color: AppColors.inkSoft),
                            ),
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
