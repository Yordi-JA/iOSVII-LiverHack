import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import 'card_header.dart';

const _meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

/// Cubiertas por mes del año con la meta mensual como línea punteada. Los
/// meses que cumplieron la meta van en morado sólido; los demás, en claro.
class MonthlyHiresChart extends StatelessWidget {
  const MonthlyHiresChart({super.key, required this.porMes, required this.metaMensual, required this.mesActual});

  final List<int> porMes;
  final double metaMensual;

  /// Mes en curso (1 a 12): los siguientes aún no tienen datos.
  final int mesActual;

  static const _alto = 210.0;

  @override
  Widget build(BuildContext context) {
    final maximo = [...porMes, metaMensual.ceil()].reduce((a, b) => a > b ? a : b) * 1.2;
    final cumplidos = [for (var m = 0; m < mesActual; m++) porMes[m]].where((n) => n >= metaMensual).length;

    return GlassCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: 'Vacantes cubiertas por mes',
            subtitle: '$cumplidos de $mesActual meses cumplieron la meta de ${metaMensual.round()} al mes',
          ),
          SizedBox(
            height: _alto + 22,
            child: Stack(
              children: [
                // Meta mensual.
                Positioned(left: 0, right: 0, bottom: 22 + _alto * metaMensual / maximo, child: const _LineaPunteada()),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var m = 0; m < 12; m++)
                      Expanded(
                        child: Tooltip(
                          message: m < mesActual ? '${_meses[m]}: ${porMes[m]} cubiertas' : _meses[m],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (m < mesActual)
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: _alto * porMes[m] / maximo),
                                  duration: Duration(milliseconds: 400 + m * 40),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, h, _) => Container(
                                    height: h,
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: porMes[m] >= metaMensual
                                          ? AppColors.flowDone
                                          : AppColors.flowDone.withValues(alpha: 0.22),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                _meses[m],
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: m < mesActual ? AppColors.inkSoft : AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Línea punteada de la meta mensual. Se pinta (en lugar de medirse con
/// LayoutBuilder) para que la tarjeta pueda igualar su alto con la vecina.
class _LineaPunteada extends StatelessWidget {
  const _LineaPunteada();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 1.5, child: CustomPaint(painter: _Puntos()));
}

class _Puntos extends CustomPainter {
  const _Puntos();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inkMuted
      ..strokeWidth = size.height;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + 4, size.height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_Puntos oldDelegate) => false;
}
