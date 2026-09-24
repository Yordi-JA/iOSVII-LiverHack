import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../attraction_metrics.dart';
import '../../candidatos/widgets/ui_kit.dart' show CColors;
import 'card_header.dart';

/// Vacantes que requieren intervención: tardías por días de retraso y luego
/// las de stand-by con su motivo. Muestra 6 y se expande con "Ver todas".
class AttentionCard extends StatefulWidget {
  const AttentionCard({super.key, required this.vacantes});

  final List<VacanteEnAtencion> vacantes;

  @override
  State<AttentionCard> createState() => _AttentionCardState();
}

class _AttentionCardState extends State<AttentionCard> {
  static const _visibles = 6;
  var _todas = false;

  @override
  Widget build(BuildContext context) {
    final lista = _todas ? widget.vacantes : widget.vacantes.take(_visibles).toList();
    final tardias = widget.vacantes.where((v) => v.retraso != null).length;

    return GlassCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: 'Requieren atención',
            subtitle: '$tardias tardías · ${widget.vacantes.length - tardias} en stand-by',
          ),
          if (lista.isEmpty)
            Text('Ninguna vacante requiere atención.', style: AppTypography.body.copyWith(color: AppColors.inkMuted)),
          for (final (i, e) in lista.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                border: i == lista.length - 1 ? null : const Border(bottom: BorderSide(color: CColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.vacante.puesto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          e.retraso == null
                              ? '${e.vacante.reclutador} · ${e.vacante.motivoStandby ?? 'En pausa'}'
                              : '${e.vacante.reclutador} · ${e.vacante.nivel.label}, SLA de ${e.vacante.diasSla} días',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(fontSize: 12.5, color: AppColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    e.retraso == null ? 'Stand-by' : '+${e.retraso} días',
                    style: AppTypography.caption.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: e.retraso == null ? AppColors.inkSoft : AppColors.danger,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          if (widget.vacantes.length > _visibles)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _todas = !_todas),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.flowDone,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
                ),
                child: Text(_todas ? 'Ver menos' : 'Ver todas (${widget.vacantes.length})'),
              ),
            ),
        ],
      ),
    );
  }
}
