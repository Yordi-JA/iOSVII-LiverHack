import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_text.dart';
import 'comparativa_controller.dart';
import 'hcai_scoring.dart';
import 'widgets/comparison_table.dart';
import 'widgets/ranking_row.dart';
import 'widgets/weights_panel.dart';

/// Top 10 de candidatos por potencial HCAI y comparativa lado a lado.
class ComparativaPage extends ConsumerWidget {
  const ComparativaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(hcaiRankingProvider);
    final blind = ref.watch(blindModeProvider);
    final selectedIds = ref.watch(compareSelectionProvider);
    final selection = ref.read(compareSelectionProvider.notifier);

    if (ranking == null) return const Center(child: CircularProgressIndicator());

    final compared = [
      for (final id in selectedIds) ...ranking.where((r) => r.candidate.id == id),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Top 10 · Potencial ', style: AppTypography.display),
                        GradientMask(child: Text('HCAI', style: AppTypography.display)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'IA centrada en las personas: explica cada puntaje y la decisión final es tuya.',
                      style: AppTypography.body.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              FilterChip(
                selected: blind,
                onSelected: (_) => ref.read(blindModeProvider.notifier).toggle(),
                avatar: Icon(blind ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                label: const Text('Modo ciego'),
                tooltip: 'Oculta nombres y fotos para evaluar sin sesgos',
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                selectedColor: AppColors.magenta.withValues(alpha: 0.15),
                side: const BorderSide(color: Colors.white),
                shape: const StadiumBorder(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text('Ranking', style: AppTypography.headline),
                          const Spacer(),
                          for (final f in HcaiFactor.values) ...[
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: f.color, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(f.label, style: AppTypography.caption.copyWith(fontSize: 11)),
                            const SizedBox(width: 10),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Marca hasta 3 para compararlos · toca una fila para ver el perfil',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: 14),
                      for (var i = 0; i < ranking.length; i++)
                        RankingRow(
                          key: ValueKey(ranking[i].candidate.id),
                          rank: i + 1,
                          result: ranking[i],
                          blind: blind,
                          selected: selectedIds.contains(ranking[i].candidate.id),
                          onToggleCompare: () => selection.toggle(ranking[i].candidate.id),
                          onOpen: () => context.go('/procesos/candidato/${ranking[i].candidate.id}'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                flex: 2,
                child: Column(
                  children: [
                    WeightsPanel(),
                    SizedBox(height: 16),
                    HcaiPrinciplesCard(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (compared.isEmpty)
            GlassCard(
              child: Row(
                children: [
                  const GradientMask(child: Icon(Icons.view_column_outlined, size: 24)),
                  const SizedBox(width: 12),
                  Text('Marca candidatos en el ranking para verlos lado a lado.', style: AppTypography.body),
                ],
              ),
            )
          else
            ComparisonTable(results: compared, blind: blind, onClear: selection.clear),
        ],
      ),
    );
  }
}
