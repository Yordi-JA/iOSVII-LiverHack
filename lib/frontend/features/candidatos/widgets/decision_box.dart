import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/candidatos/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../candidatos_controller.dart';
import 'ui_kit.dart';

/// Decisión final del Hiring manager con justificación obligatoria.
class DecisionBox extends ConsumerStatefulWidget {
  const DecisionBox({super.key, required this.candidato});

  final Candidato candidato;

  static const minChars = 20;

  @override
  ConsumerState<DecisionBox> createState() => _DecisionBoxState();
}

class _DecisionBoxState extends ConsumerState<DecisionBox> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _decide(StatusProceso status) =>
      ref.read(candidatosProvider.notifier).decidir(widget.candidato.id, status, _controller.text);

  @override
  Widget build(BuildContext context) {
    final c = widget.candidato;
    if (c.status != StatusProceso.enProceso) {
      return SoftBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Decisión registrada: ${c.status.json}',
              style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
            ),
            if (c.statusJustificacion.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(c.statusJustificacion, style: AppTypography.body.copyWith(color: AppColors.inkSoft)),
            ],
          ],
        ),
      );
    }

    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, value, _) {
        final n = value.text.trim().length;
        final ready = n >= DecisionBox.minChars;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: 'Justificación obligatoria (mínimo ${DecisionBox.minChars} caracteres)',
                hintStyle: AppTypography.body.copyWith(color: AppColors.inkMuted),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.65),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.magenta, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$n / ${DecisionBox.minChars} caracteres mínimos',
              style: AppTypography.caption.copyWith(color: ready ? AppColors.success : AppColors.inkMuted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ToneButton(
                  label: 'Marcar finalista',
                  icon: Icons.check_rounded,
                  color: AppColors.success,
                  onTap: ready ? () => _decide(StatusProceso.finalista) : null,
                ),
                ToneButton(
                  label: 'Descartar',
                  icon: Icons.close_rounded,
                  color: AppColors.danger,
                  onTap: ready ? () => _decide(StatusProceso.descartado) : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
