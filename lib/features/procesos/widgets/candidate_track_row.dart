import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/candidate.dart';
import '../../../data/models/pipeline_stage.dart';
import 'candidate_face.dart';
import 'candidate_popover.dart';
import 'stage_stepper.dart';

/// Carril de un postulante: una línea alineada con los 6 círculos del flujo
/// y su rostro colocado en la etapa donde va.
class CandidateTrackRow extends StatefulWidget {
  const CandidateTrackRow({
    super.key,
    required this.candidate,
    required this.selected,
    required this.onSelect,
    required this.onDismiss,
    required this.onOpenProfile,
  });

  final Candidate candidate;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDismiss;
  final VoidCallback onOpenProfile;

  static const height = 96.0;
  static const _lineTop = 38.0;

  @override
  State<CandidateTrackRow> createState() => _CandidateTrackRowState();
}

class _CandidateTrackRowState extends State<CandidateTrackRow> {
  final _popover = OverlayPortalController();
  final _link = LayerLink();

  @override
  void initState() {
    super.initState();
    if (widget.selected) WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(CandidateTrackRow old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) _sync();
  }

  void _sync() {
    if (!mounted) return;
    widget.selected ? _popover.show() : _popover.hide();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.candidate;
    // Del lado derecho, el popup se abre hacia la izquierda para no salirse.
    final opensLeft = c.etapaActual >= 5;

    return SizedBox(
      height: CandidateTrackRow.height,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final start = StageStepper.centerOf(1, w);
          final end = StageStepper.centerOf(PipelineStage.values.length, w);
          final here = StageStepper.centerOf(c.etapaActual, w);
          const lineTop = CandidateTrackRow._lineTop;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: start,
                width: end - start,
                top: lineTop,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.inkMuted.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                left: start,
                top: lineTop,
                height: 4,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: here - start),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, width, _) => Container(
                    width: width,
                    decoration: BoxDecoration(
                      gradient: c.status == CandidateStatus.descartado ? null : AppColors.brandGradientHorizontal,
                      color: c.status == CandidateStatus.descartado ? AppColors.danger.withValues(alpha: 0.35) : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              for (final s in PipelineStage.values)
                Positioned(
                  left: StageStepper.centerOf(s.number, w) - 5,
                  top: lineTop - 3,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.number <= c.etapaActual ? Colors.white : AppColors.bgTop,
                      border: Border.all(
                        color: s.number <= c.etapaActual ? AppColors.magenta : AppColors.inkMuted.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                left: here - 36,
                top: lineTop + 2 - 36,
                child: TapRegion(
                  groupId: c.id,
                  child: CompositedTransformTarget(
                    link: _link,
                    child: OverlayPortal(
                      controller: _popover,
                      // Align suelta las restricciones del Overlay para que el
                      // follower tome el tamaño del popup y no el de la pantalla.
                      overlayChildBuilder: (context) => Align(
                        alignment: Alignment.topLeft,
                        child: CompositedTransformFollower(
                          link: _link,
                          showWhenUnlinked: false,
                          targetAnchor: opensLeft ? Alignment.topLeft : Alignment.topRight,
                          followerAnchor: opensLeft ? Alignment.topRight : Alignment.topLeft,
                          offset: Offset(opensLeft ? -8 : 8, -20),
                          child: TapRegion(
                            groupId: c.id,
                            onTapOutside: (_) => widget.onDismiss(),
                            child: Material(
                              type: MaterialType.transparency,
                              child: CandidatePopover(candidate: c, onOpenProfile: widget.onOpenProfile),
                            ),
                          ),
                        ),
                      ),
                      child: CandidateFace(
                        candidate: c,
                        selected: widget.selected,
                        onTap: widget.selected ? widget.onDismiss : widget.onSelect,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
