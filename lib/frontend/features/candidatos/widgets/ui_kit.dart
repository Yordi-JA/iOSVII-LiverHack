import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../backend/candidatos/models.dart';
import '../../../../backend/candidatos/rules.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../../core/widgets/status_pill.dart';

/// Colores del módulo tomados de la paleta actual de la app.
abstract final class CColors {
  static const line = Color(0x141C1B2E);
  static const glass2 = Color(0x8CFFFFFF);

  /// Morado de selección activa.
  static const sel = AppColors.purple;
}

Color toneColor(Tone tone) => switch (tone) {
  Tone.ok => AppColors.success,
  Tone.warn => AppColors.warning,
  Tone.bad => AppColors.danger,
  Tone.mute => AppColors.inkSoft,
};

Color slaColor(SlaLevel level) => switch (level) {
  SlaLevel.red => AppColors.danger,
  SlaLevel.amber => AppColors.warning,
  SlaLevel.green => AppColors.success,
  SlaLevel.none => AppColors.inkMuted,
};

Color? veredictoColor(Veredicto? v) => switch (v) {
  Veredicto.recomendado => AppColors.success,
  Veredicto.noRecomendado => AppColors.danger,
  null => AppColors.warning,
};

String veredictoLabel(Veredicto? v, {String pending = 'Veredicto pendiente'}) => v?.json ?? pending;

/// Pill de la app: fondo del color al 14% y borde al 25%.
/// El tono `mute` usa vidrio con borde de línea.
class TonePill extends StatelessWidget {
  const TonePill({super.key, required this.label, required this.tone});

  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) =>
      tone == Tone.mute ? MutePill(label: label) : StatusPill(label: label, color: toneColor(tone));
}

class MutePill extends StatelessWidget {
  const MutePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CColors.glass2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CColors.line),
      ),
      child: Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class SlaPill extends StatelessWidget {
  const SlaPill({super.key, required this.info});

  final SlaInfo info;

  @override
  Widget build(BuildContext context) => TonePill(label: info.text, tone: info.tone);
}

class EstatusPill extends StatelessWidget {
  const EstatusPill({super.key, required this.candidato});

  final Candidato candidato;

  @override
  Widget build(BuildContext context) => switch (candidato) {
    Candidato(status: StatusProceso.finalista) => const StatusPill(label: 'Finalista', color: AppColors.success),
    Candidato(status: StatusProceso.oferta) => const StatusPill(label: 'En oferta', color: AppColors.flowDone),
    Candidato(status: StatusProceso.descartado) => const MutePill(label: 'Descartado'),
    Candidato(enviadoHm: true) => const StatusPill(label: 'Con HM', color: AppColors.magenta),
    _ => const StatusPill(label: 'Filtro de reclutamiento', color: AppColors.info),
  };
}

/// Barra de compatibilidad con el gradiente de marca y el porcentaje.
class FitBar extends StatelessWidget {
  const FitBar({super.key, required this.value, this.width = 90});

  /// 0 a 100.
  final int value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(color: AppColors.ink.withValues(alpha: 0.07)),
                FractionallySizedBox(
                  widthFactor: (value / 100).clamp(0, 1),
                  child: const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.brandGradientHorizontal)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value%', style: AppTypography.label.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// Anillo de compatibilidad de AssessFirst.
class CompatRing extends StatelessWidget {
  const CompatRing({super.key, required this.value, this.size = 76});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value / 100),
        child: Center(
          child: Text('$value%', style: AppTypography.headline.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.ink.withValues(alpha: 0.07),
    );
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * fraction.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [AppColors.purple, AppColors.magenta, AppColors.orange, AppColors.purple],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

/// Medidor de 3 segmentos para la visión estratégica.
class VisionMeter extends StatelessWidget {
  const VisionMeter({super.key, required this.vision});

  final String vision;

  @override
  Widget build(BuildContext context) {
    final filled = visionSegments(vision);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 18,
            height: 6,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: i < filled ? AppColors.purple : AppColors.ink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class CandidatoAvatar extends StatelessWidget {
  const CandidatoAvatar({super.key, required this.candidato, this.size = 38});

  final Candidato candidato;
  final double size;

  @override
  Widget build(BuildContext context) =>
      GradientAvatar(initials: initialsOf(candidato.nombre), size: size, tintIndex: candidato.id, ringWidth: 2);
}

/// Título de sección dentro de los paneles.
class PanelTitle extends StatelessWidget {
  const PanelTitle(this.text, {super.key, this.hint, this.trailing});

  final String text;
  final String? hint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: AppTypography.headline.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
              if (hint != null) ...[
                const SizedBox(height: 3),
                Text(hint!, style: AppTypography.caption.copyWith(fontSize: 13.5, color: AppColors.inkMuted)),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Etiqueta pequeña en mayúsculas para subtítulos de cajas.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: AppTypography.caption.copyWith(color: AppColors.inkMuted, fontWeight: FontWeight.w600),
    ),
  );
}

/// Caja de vidrio secundaria para agrupar datos dentro de un panel.
class SoftBox extends StatelessWidget {
  const SoftBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? Colors.white.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: borderColor ?? Colors.white),
    ),
    child: child,
  );
}

/// Botón sólido de color (Aprobar / Descartar) o de vidrio (secundario).
class ToneButton extends StatelessWidget {
  const ToneButton({super.key, required this.label, required this.onTap, this.color, this.icon});

  final String label;
  final VoidCallback? onTap;

  /// `null` = botón secundario de vidrio.
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = color == null ? AppColors.ink : Colors.white;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: color ?? Colors.white.withValues(alpha: 0.6),
        shape: StadiumBorder(side: BorderSide(color: color == null ? CColors.line : Colors.transparent)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.label.copyWith(color: fg, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];

/// Fecha corta es_MX: "12 sept".
String fechaCorta(DateTime d) => '${d.day} ${_meses[d.month - 1]}';

/// Correo simulado del candidato: nombre.apellido@correo.com, sin acentos.
String correoSimulado(String nombre) {
  const accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};
  final parts = nombre.toLowerCase().split(RegExp(r'\s+'));
  final user = [
    parts.first,
    if (parts.length > 1) parts[1],
  ].join('.').split('').map((ch) => accents[ch] ?? ch).join().replaceAll(RegExp(r'[^a-z.]'), '');
  return '$user@correo.com';
}

/// "hace un momento", "hace 5 min", "hace 2 h" o la fecha corta.
String fechaRelativa(DateTime fecha) {
  final d = DateTime.now().difference(fecha);
  if (d.inMinutes < 1) return 'hace un momento';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  return fechaCorta(fecha);
}
