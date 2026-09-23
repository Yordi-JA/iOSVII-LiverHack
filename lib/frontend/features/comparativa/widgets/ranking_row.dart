import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/status_pill.dart';
import '../hcai_scoring.dart';
import 'hcai_stacked_bar.dart';

class RankingRow extends StatelessWidget {
  const RankingRow({
    super.key,
    required this.rank,
    required this.result,
    required this.blind,
    required this.selected,
    required this.onToggleCompare,
    required this.onOpen,
  });

  final int rank;
  final HcaiResult result;
  final bool blind;
  final bool selected;
  final VoidCallback onToggleCompare;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = result.candidate;
    final name = blind ? 'Candidato ${String.fromCharCode(64 + int.parse(c.id))}' : c.nombre;
    final strongest = result.strongest;
    final weakest = result.weakest;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: selected ? 0.85 : 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.magenta.withValues(alpha: 0.5) : Colors.white),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: rank <= 3
                  ? GradientMask(child: Text('$rank', style: AppTypography.title.copyWith(fontWeight: FontWeight.w800)))
                  : Text('$rank', style: AppTypography.title.copyWith(color: AppColors.inkMuted)),
            ),
            blind
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.ink.withValues(alpha: 0.06)),
                    child: const Icon(Icons.visibility_off_outlined, size: 18, color: AppColors.inkSoft),
                  )
                : GradientAvatar(initials: c.initials, size: 44, photoUrl: c.fotoUrl, tintIndex: int.tryParse(c.id) ?? 0),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: AppTypography.headline)),
                      const SizedBox(width: 8),
                      StatusPill(label: c.status.label, color: c.status.color),
                    ],
                  ),
                  Text(c.puestoActual, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Destaca en ', style: AppTypography.caption),
                      TextSpan(
                        text: strongest.label,
                        style: AppTypography.caption.copyWith(color: strongest.color, fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: '  ·  A vigilar: ', style: AppTypography.caption),
                      TextSpan(
                        text: weakest.label,
                        style: AppTypography.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: HcaiStackedBar(result: result)),
            const SizedBox(width: 16),
            SizedBox(
              width: 54,
              child: Text(
                result.score.round().toString(),
                textAlign: TextAlign.right,
                style: AppTypography.metric.copyWith(fontSize: 26),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: selected ? 'Quitar de la comparación' : 'Comparar (máx. 3)',
              child: Checkbox(
                value: selected,
                onChanged: (_) => onToggleCompare(),
                activeColor: AppColors.magenta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
