import 'package:flutter/material.dart';

import '../../../../backend/candidatos/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/status_pill.dart';
import 'ui_kit.dart';

/// Línea de tiempo vertical de entrevistas, de la más reciente a la más antigua.
class InterviewTimeline extends StatelessWidget {
  const InterviewTimeline({super.key, required this.entrevistas});

  final List<Entrevista> entrevistas;

  @override
  Widget build(BuildContext context) {
    if (entrevistas.isEmpty) {
      return Text(
        'Sin entrevistas registradas todavía.',
        style: AppTypography.body.copyWith(color: AppColors.inkMuted),
      );
    }
    final sorted = [...entrevistas]..sort((a, b) => b.diasDesdeHoy.compareTo(a.diasDesdeHoy));
    return Column(
      children: [for (var i = 0; i < sorted.length; i++) _Entry(entrevista: sorted[i], last: i == sorted.length - 1)],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.entrevista, required this.last});

  final Entrevista entrevista;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final e = entrevista;
    final color = veredictoColor(e.veredicto)!;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
                  ),
                ),
                if (!last) Expanded(child: Container(width: 2, color: CColors.line)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(fechaCorta(e.fecha), style: AppTypography.caption.copyWith(color: AppColors.inkMuted)),
                      Text(
                        e.entrevistadores.join(' y '),
                        style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
                      ),
                      StatusPill(label: veredictoLabel(e.veredicto), color: color),
                    ],
                  ),
                  if (e.notas.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(e.notas, style: AppTypography.body.copyWith(color: AppColors.inkSoft)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
