import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../../backend/models/candidate.dart';
import '../hcai_scoring.dart';

/// Comparativa lado a lado con la estructura del Excel de candidatos.
class ComparisonTable extends StatelessWidget {
  const ComparisonTable({super.key, required this.results, required this.blind, required this.onClear});

  final List<HcaiResult> results;
  final bool blind;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, Widget Function(HcaiResult))>[
      ('Potencial HCAI', (r) => Text('${r.score.round()} / 100', style: AppTypography.headline)),
      for (final f in HcaiFactor.values)
        (f.label, (r) => Text('${((r.values[f] ?? 0) * 100).round()}%', style: AppTypography.label.copyWith(color: f.color, fontWeight: FontWeight.w600))),
      ('Puesto actual', (r) => _text(r.candidate.puestoActual)),
      ('Empresa actual', (r) => _text(r.candidate.empresaActual)),
      ('Escolaridad', (r) => _text(r.candidate.escolaridad)),
      ('Otros estudios', (r) => _text(r.candidate.otrosEstudios)),
      ('Idiomas', (r) => _text(r.candidate.idiomas)),
      ('Compensación actual', (r) => _text(formatMoney(r.candidate.compensacionActual))),
      ('Compensación deseada', (r) => _text(formatMoney(r.candidate.compensacionDeseada))),
      ('Fortalezas', (r) => _text(r.candidate.assessFirst.fortalezas)),
      ('Áreas de oportunidad', (r) => _text(r.candidate.assessFirst.areasOportunidad)),
      ('Recomendación', (r) => _text(r.candidate.assessFirst.recomendaciones)),
      ('Estatus', (r) => Align(alignment: Alignment.centerLeft, child: StatusPill(label: r.candidate.status.label, color: r.candidate.status.color))),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Comparativa lado a lado', style: AppTypography.headline),
              const Spacer(),
              TextButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exportar a Excel: próximamente')),
                ),
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Exportar Excel'),
              ),
              TextButton(onPressed: onClear, child: const Text('Limpiar')),
            ],
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: {0: const FixedColumnWidth(170), for (var i = 1; i <= results.length; i++) i: const FlexColumnWidth()},
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              TableRow(
                children: [
                  const SizedBox(),
                  for (final r in results) _Header(candidate: r.candidate, blind: blind),
                ],
              ),
              for (final (label, cell) in rows)
                TableRow(
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.9)))),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    for (final r in results)
                      Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 10), child: cell(r)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _text(String s) => Text(s, style: AppTypography.label.copyWith(height: 1.35));
}

class _Header extends StatelessWidget {
  const _Header({required this.candidate, required this.blind});

  final Candidate candidate;
  final bool blind;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          if (!blind) ...[
            GradientAvatar(initials: candidate.initials, size: 40, photoUrl: candidate.fotoUrl, tintIndex: int.tryParse(candidate.id) ?? 0),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              blind ? 'Candidato ${String.fromCharCode(64 + int.parse(candidate.id))}' : candidate.nombre,
              style: AppTypography.headline.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
