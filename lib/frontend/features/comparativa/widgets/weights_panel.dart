import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_text.dart';
import '../comparativa_controller.dart';
import '../hcai_scoring.dart';

/// La persona reclutadora decide cuánto pesa cada factor.
class WeightsPanel extends ConsumerWidget {
  const WeightsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weights = ref.watch(hcaiWeightsProvider);
    final notifier = ref.read(hcaiWeightsProvider.notifier);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientMask(child: Icon(Icons.tune_rounded, size: 20)),
              const SizedBox(width: 8),
              Expanded(child: Text('Tú decides los pesos', style: AppTypography.headline)),
              TextButton(onPressed: notifier.reset, child: const Text('Restablecer')),
            ],
          ),
          Text('El ranking se recalcula al instante.', style: AppTypography.caption),
          const SizedBox(height: 12),
          for (final f in HcaiFactor.values) ...[
            Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: f.color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(f.label, style: AppTypography.label.copyWith(fontWeight: FontWeight.w600))),
                Text('${(weights.share(f) * 100).round()}%', style: AppTypography.label),
              ],
            ),
            Tooltip(
              message: f.description,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: f.color,
                  thumbColor: f.color,
                  inactiveTrackColor: f.color.withValues(alpha: 0.15),
                  overlayColor: f.color.withValues(alpha: 0.12),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: weights[f].toDouble(),
                  max: 50,
                  divisions: 10,
                  onChanged: (v) => notifier.set(f, v.round()),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Principios de IA centrada en las personas que sigue el ranking.
class HcaiPrinciplesCard extends StatelessWidget {
  const HcaiPrinciplesCard({super.key});

  @override
  Widget build(BuildContext context) {
    const principles = [
      (Icons.lightbulb_outline_rounded, 'Explicable', 'Cada puntaje muestra qué factores lo forman.'),
      (Icons.person_outline_rounded, 'La persona decide', 'La IA sugiere; la decisión final es del HM.'),
      (Icons.shield_outlined, 'Sin sesgos', 'Nunca usa datos sensibles para calificar.'),
      (Icons.history_rounded, 'Auditable', 'Pesos y decisiones quedan en la bitácora.'),
    ];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Principios HCAI', style: AppTypography.headline),
          const SizedBox(height: 12),
          for (final (icon, title, text) in principles)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientMask(child: Icon(icon, size: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: '$title. ', style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
                      TextSpan(text: text, style: AppTypography.label.copyWith(color: AppColors.inkSoft)),
                    ])),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text('No se usa: ${hcaiExcludedAttributes.join(', ')}.', style: AppTypography.caption),
        ],
      ),
    );
  }
}
