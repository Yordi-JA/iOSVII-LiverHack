import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../attraction_metrics.dart';
import '../../candidatos/widgets/ui_kit.dart' show CColors;
import 'card_header.dart';

const _formula =
    'Puntaje de 0 a 100:\n'
    '40 % cumplimiento de SLA\n'
    '25 % aceptación de oferta\n'
    '20 % satisfacción del HM (÷ 5)\n'
    '15 % vacantes cubiertas (÷ máximo del equipo)';

/// Fotos del equipo que ya existen en assets/fotos.
const _fotos = {'Mariana Ortega': 'assets/fotos/mariana_ortega.jpg'};

/// Mejor desempeño del periodo y tabla con todo el equipo.
class RecruiterRankingCard extends StatelessWidget {
  const RecruiterRankingCard({super.key, required this.ranking, required this.periodo});

  final List<DesempenoReclutador> ranking;
  final Periodo periodo;

  @override
  Widget build(BuildContext context) {
    final mejor = ranking.firstOrNull;
    return GlassCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: 'Desempeño del equipo de AT',
            subtitle: periodo.label,
            trailing: const Tooltip(
              message: _formula,
              child: Icon(Icons.info_outline_rounded, size: 18, color: AppColors.inkMuted),
            ),
          ),
          if (mejor != null) ...[
            Row(
              children: [
                GradientAvatar(initials: initialsOf(mejor.nombre), size: 40, photoUrl: _fotos[mejor.nombre]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEJOR DESEMPEÑO',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      Text(
                        mejor.nombre,
                        style: AppTypography.label.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${mejor.puntaje}'),
                      TextSpan(
                        text: ' pts',
                        style: AppTypography.caption.copyWith(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  style: AppTypography.display.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.flowDone,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          const _Fila(
            celdas: ['AT', 'Cubiertas', 'Días prom.', 'En SLA', 'Aceptación', 'Sat. HM', 'Puntaje'],
            encabezado: true,
          ),
          for (final d in ranking)
            _Fila(
              celdas: [
                d.nombre,
                '${d.cubiertas}',
                d.cubiertas == 0 ? '—' : '${d.diasPromedio}',
                d.cubiertas == 0 ? '—' : '${(d.enSla * 100).round()} %',
                d.cubiertas == 0 ? '—' : '${(d.aceptacion * 100).round()} %',
                d.cubiertas == 0 ? '—' : d.satisfaccionHm.toStringAsFixed(1),
                '${d.puntaje}',
              ],
              colorSla: d.cubiertas == 0 ? null : _colorSla(d.enSla),
            ),
        ],
      ),
    );
  }

  static Color _colorSla(double v) => v >= 0.70
      ? AppColors.success
      : v >= 0.45
      ? AppColors.warning
      : AppColors.danger;
}

class _Fila extends StatelessWidget {
  const _Fila({required this.celdas, this.encabezado = false, this.colorSla});

  final List<String> celdas;
  final bool encabezado;
  final Color? colorSla;

  static const _flex = [30, 12, 13, 12, 13, 11, 11];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CColors.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < celdas.length; i++)
            Expanded(
              flex: _flex[i],
              child: Text(
                celdas[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                style: encabezado
                    ? AppTypography.caption.copyWith(fontSize: 11.5, color: AppColors.inkMuted)
                    : AppTypography.caption.copyWith(
                        fontSize: 13,
                        color: i == 3 && colorSla != null ? colorSla : AppColors.ink,
                        fontWeight: i == 0 || i == 6 || i == 3 ? FontWeight.w600 : FontWeight.w400,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
