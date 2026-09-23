import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../../../backend/models/candidate.dart';

/// Rostro del postulante con su puntaje AIRA. Seleccionado, lo rodea
/// un anillo punteado que gira.
class CandidateFace extends StatefulWidget {
  const CandidateFace({
    super.key,
    required this.candidate,
    required this.selected,
    required this.onTap,
    this.size = 56,
    this.showName = true,
  });

  final Candidate candidate;
  final bool selected;
  final VoidCallback onTap;
  final double size;
  final bool showName;

  @override
  State<CandidateFace> createState() => _CandidateFaceState();
}

class _CandidateFaceState extends State<CandidateFace> with SingleTickerProviderStateMixin {
  bool _hover = false;
  late final _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void initState() {
    super.initState();
    if (widget.selected) _spin.repeat();
  }

  @override
  void didUpdateWidget(CandidateFace old) {
    super.didUpdateWidget(old);
    if (widget.selected && !_spin.isAnimating) _spin.repeat();
    if (!widget.selected && _spin.isAnimating) _spin.stop();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.candidate;
    final scale = widget.selected ? 1.1 : (_hover ? 1.06 : 1.0);
    final ringSize = widget.size + 16;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: ringSize,
                height: ringSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (widget.selected)
                      RotationTransition(
                        turns: _spin,
                        child: CustomPaint(size: Size.square(ringSize), painter: _DashedRingPainter()),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.magenta.withValues(alpha: widget.selected ? 0.4 : 0.12),
                            blurRadius: widget.selected ? 20 : 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: GradientAvatar(
                        initials: c.initials,
                        size: widget.size,
                        tintIndex: int.tryParse(c.id) ?? 0,
                        photoUrl: c.fotoUrl,
                      ),
                    ),
                    Positioned(right: 0, bottom: 4, child: _AiraBadge(score: c.airaScore)),
                    if (c.status == CandidateStatus.descartado)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.showName)
                Text(
                  c.firstName,
                  style: AppTypography.caption.copyWith(
                    color: widget.selected ? AppColors.ink : AppColors.inkSoft,
                    fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashes = 14;
    const gap = 0.45;
    final rect = (Offset.zero & size).deflate(2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = AppColors.brandGradient.createShader(rect);
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * (1 - gap), false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter oldDelegate) => false;
}

class _AiraBadge extends StatelessWidget {
  const _AiraBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradientHorizontal,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        '$score',
        style: AppTypography.caption.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
