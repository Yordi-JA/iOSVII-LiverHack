import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../../backend/models/pipeline_stage.dart';

/// Flujo de 6 círculos: completados con palomita, el actual brillando
/// y los pendientes en vidrio gris.
class StageStepper extends StatelessWidget {
  const StageStepper({
    super.key,
    required this.currentStep,
    this.counts,
    this.captions,
    this.highlightedStep,
    this.onStepTap,
    this.showCaptions = true,
  });

  /// Etapa actual (1 a 6).
  final int currentStep;

  /// Candidatos por etapa. Si se indica, se muestra bajo cada etiqueta.
  final Map<int, int>? counts;

  /// Texto bajo cada etapa (por ejemplo, días permitidos). Tiene prioridad sobre [counts].
  final Map<int, String>? captions;

  /// Etapa cuyo feedback se está viendo.
  final int? highlightedStep;
  final ValueChanged<int>? onStepTap;

  /// Si es `false`, bajo cada etapa solo va su nombre.
  final bool showCaptions;

  static const _circleSize = 60.0;
  /// Ancho de cada paso. Los carriles de Procesos lo usan para alinear
  /// los rostros con los círculos.
  static const stepWidth = 118.0;

  /// Posición horizontal del centro del paso [step] (1 a 6) en un ancho [width].
  static double centerOf(int step, double width) =>
      stepWidth / 2 + (step - 1) * (width - stepWidth) / (PipelineStage.values.length - 1);

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final stage in PipelineStage.values) {
      final n = stage.number;
      if (n > 1) {
        children.add(Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: _circleSize / 2 - 2),
            child: _Connector(done: n <= currentStep),
          ),
        ));
      }
      children.add(SizedBox(
        width: stepWidth,
        child: _Step(
          stage: stage,
          state: n < currentStep
              ? _StepState.done
              : n == currentStep
                  ? _StepState.active
                  : _StepState.pending,
          count: counts?[n],
          caption: captions?[n],
          showCaption: showCaptions,
          highlighted: highlightedStep == n,
          onTap: onStepTap == null ? null : () => onStepTap!(n),
        ),
      ));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

enum _StepState { done, active, pending }

class _Connector extends StatelessWidget {
  const _Connector({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: done ? AppColors.flowDone : AppColors.inkMuted.withValues(alpha: 0.3),
        boxShadow: done
            ? [BoxShadow(color: AppColors.flowDone.withValues(alpha: 0.3), blurRadius: 8)]
            : null,
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.stage,
    required this.state,
    required this.count,
    required this.caption,
    required this.highlighted,
    required this.onTap,
    required this.showCaption,
  });

  final PipelineStage stage;
  final _StepState state;
  final int? count;
  final String? caption;
  final bool highlighted;
  final VoidCallback? onTap;
  final bool showCaption;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      stage.label,
      textAlign: TextAlign.center,
      style: AppTypography.label.copyWith(
        fontWeight: state == _StepState.pending ? FontWeight.w500 : FontWeight.w600,
        color: state == _StepState.pending ? AppColors.inkMuted : AppColors.ink,
      ),
    );
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              height: StageStepper._circleSize,
              child: Center(
                child: switch (state) {
                  _StepState.done => _DoneCircle(highlighted: highlighted),
                  _StepState.active => _ActiveCircle(number: stage.number),
                  _StepState.pending => _PendingCircle(number: stage.number, highlighted: highlighted),
                },
              ),
            ),
            const SizedBox(height: 10),
            highlighted ? GradientMask(child: label) : label,
            if (showCaption) ...[
              const SizedBox(height: 2),
              // Alto fijo para que el flujo no cambie de tamaño entre modos.
              SizedBox(
                height: 30,
                child: Text(
                  caption ?? (count == null ? stage.description : '$count candidato${count == 1 ? '' : 's'}'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DoneCircle extends StatelessWidget {
  const _DoneCircle({required this.highlighted});

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.flowDone,
        border: Border.all(color: Colors.white, width: highlighted ? 3 : 0),
        boxShadow: [
          BoxShadow(
            color: AppColors.flowDone.withValues(alpha: highlighted ? 0.45 : 0.25),
            blurRadius: highlighted ? 18 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 26),
    );
  }
}

/// Círculo de la etapa actual con un halo que "respira".
class _ActiveCircle extends StatefulWidget {
  const _ActiveCircle({required this.number});

  final int number;

  @override
  State<_ActiveCircle> createState() => _ActiveCircleState();
}

class _ActiveCircleState extends State<_ActiveCircle> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              // Halo rosa de 6 px al 20% que "respira".
              BoxShadow(color: AppColors.flowCurrent.withValues(alpha: 0.2), spreadRadius: 6),
              BoxShadow(
                color: AppColors.flowCurrent.withValues(alpha: 0.15 + 0.2 * t),
                blurRadius: 12 + 12 * t,
                spreadRadius: 6 + 2 * t,
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: child,
        );
      },
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.flowCurrent),
        alignment: Alignment.center,
        child: Text(
          '${widget.number}',
          style: AppTypography.title.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _PendingCircle extends StatelessWidget {
  const _PendingCircle({required this.number, required this.highlighted});

  final int number;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.7),
        border: Border.all(
          color: highlighted ? AppColors.magenta : AppColors.inkMuted.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Text(
        '$number',
        style: AppTypography.headline.copyWith(color: AppColors.inkMuted),
      ),
    );
  }
}
