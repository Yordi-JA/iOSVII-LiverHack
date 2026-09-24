import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../backend/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'tutorial.dart';

/// Marca un elemento que el tutorial puede resaltar con el id [id].
class SpotlightTarget extends StatefulWidget {
  const SpotlightTarget({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  static final _montados = <String, GlobalKey>{};

  /// Contexto del elemento [id] si está en pantalla.
  static BuildContext? contexto(String id) => _montados[id]?.currentContext;

  @override
  State<SpotlightTarget> createState() => _SpotlightTargetState();
}

class _SpotlightTargetState extends State<SpotlightTarget> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    SpotlightTarget._montados[widget.id] = _key;
  }

  @override
  void dispose() {
    if (SpotlightTarget._montados[widget.id] == _key) SpotlightTarget._montados.remove(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}

/// Capa del tutorial: oscurece la app, deja visible el elemento del paso con
/// un borde naranja y muestra la explicación junto a él. La primera vez que
/// se abre la app arranca solo.
class SpotlightHost extends ConsumerStatefulWidget {
  const SpotlightHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SpotlightHost> createState() => _SpotlightHostState();
}

class _SpotlightHostState extends ConsumerState<SpotlightHost> {
  Rect? _rect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ref.read(liverhackStoreProvider);
      if (mounted && store.persistente && !store.tutorialVisto) ref.read(tutorialProvider.notifier).iniciar();
    });
  }

  /// Pasos cuyo elemento está en pantalla ahora mismo.
  List<PasoTutorial> get _disponibles =>
      pasosTutorial.where((p) => SpotlightTarget.contexto(p.target) != null).toList();

  /// Lleva el elemento del paso a la vista y mide su posición.
  Future<void> _enfocar(int paso) async {
    final disponibles = _disponibles;
    if (disponibles.isEmpty) return;
    final target = disponibles[paso.clamp(0, disponibles.length - 1)].target;
    final ctx = SpotlightTarget.contexto(target);
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0.2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    if (mounted) setState(() => _rect = _medir(target));
  }

  Rect? _medir(String target) {
    final box = SpotlightTarget.contexto(target)?.findRenderObject();
    final host = context.findRenderObject();
    if (box is! RenderBox || host is! RenderBox || !box.attached) return null;
    return box.localToGlobal(Offset.zero, ancestor: host) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tutorialProvider, (_, paso) {
      if (paso != null) WidgetsBinding.instance.addPostFrameCallback((_) => _enfocar(paso));
    });
    final paso = ref.watch(tutorialProvider);
    final disponibles = paso == null ? const <PasoTutorial>[] : _disponibles;

    if (paso != null && disponibles.isNotEmpty) {
      // Si cambia el tamaño de la ventana, el hueco sigue al elemento.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final actual = _medir(disponibles[paso.clamp(0, disponibles.length - 1)].target);
        if (actual != null && actual != _rect) setState(() => _rect = actual);
      });
    }

    return Stack(
      children: [
        widget.child,
        if (paso != null && disponibles.isNotEmpty)
          Positioned.fill(
            child: _Recorrido(pasos: disponibles, indice: paso.clamp(0, disponibles.length - 1), rect: _rect),
          ),
      ],
    );
  }
}

class _Recorrido extends ConsumerWidget {
  const _Recorrido({required this.pasos, required this.indice, required this.rect});

  final List<PasoTutorial> pasos;
  final int indice;
  final Rect? rect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorial = ref.read(tutorialProvider.notifier);
    final ultimo = indice == pasos.length - 1;
    void siguiente() => ultimo ? tutorial.cerrar() : tutorial.ir(indice + 1);
    void atras() => indice > 0 ? tutorial.ir(indice - 1) : null;
    final hueco = rect?.inflate(6);

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        switch (event.logicalKey) {
          case LogicalKeyboardKey.escape:
            tutorial.cerrar();
          case LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.enter:
            siguiente();
          case LogicalKeyboardKey.arrowLeft:
            atras();
          default:
            return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: Stack(
        children: [
          // Velo: bloquea la app mientras dura el recorrido.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              // Mientras se mide el primer elemento solo hay velo; después
              // el hueco se desliza de un paso al siguiente.
              child: hueco == null
                  ? CustomPaint(painter: _Velo(null))
                  : TweenAnimationBuilder<Rect?>(
                      tween: RectTween(end: hueco),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      builder: (context, r, _) => CustomPaint(painter: _Velo(r)),
                    ),
            ),
          ),
          Positioned.fill(
            child: CustomSingleChildLayout(
              delegate: _Colocar(hueco),
              child: _Tarjeta(
                paso: pasos[indice],
                numero: indice + 1,
                total: pasos.length,
                ultimo: ultimo,
                onSaltar: tutorial.cerrar,
                onAtras: indice > 0 ? atras : null,
                onSiguiente: siguiente,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fondo oscuro con un hueco redondeado sobre el elemento y borde naranja.
class _Velo extends CustomPainter {
  _Velo(this.hueco);

  final Rect? hueco;

  @override
  void paint(Canvas canvas, Size size) {
    final todo = Path()..addRect(Offset.zero & size);
    final velo = Paint()..color = AppColors.ink.withValues(alpha: 0.62);
    if (hueco == null) {
      canvas.drawPath(todo, velo);
      return;
    }
    // Mismo redondeo que las tarjetas; en botones pequeños queda casi circular.
    final radio = Radius.circular(hueco!.shortestSide / 2 < 24 ? hueco!.shortestSide / 2 : 24);
    final rrect = RRect.fromRectAndRadius(hueco!, radio);
    // Regla par-impar en lugar de Path.combine: en el renderer web la
    // diferencia de trazos no recortaba el hueco y el apartado quedaba oscuro.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(rrect),
      velo,
    );
    // Brillo naranja alrededor del borde para que el apartado destaque.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = AppColors.orange.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.orange,
    );
  }

  @override
  bool shouldRepaint(_Velo old) => old.hueco != hueco;
}

/// Coloca la tarjeta debajo del elemento; si no cabe, arriba; y siempre
/// dentro de la pantalla.
class _Colocar extends SingleChildLayoutDelegate {
  _Colocar(this.hueco);

  final Rect? hueco;

  static const _margen = 16.0;
  static const _separacion = 14.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(Size((constraints.maxWidth - 2 * _margen).clamp(0, 360), constraints.maxHeight));

  @override
  Offset getPositionForChild(Size size, Size child) {
    final h = hueco;
    if (h == null) return Offset((size.width - child.width) / 2, (size.height - child.height) / 2);
    final maxX = size.width - child.width - _margen;
    final maxY = size.height - child.height - _margen;
    double enX(double x) => x.clamp(_margen, maxX < _margen ? _margen : maxX);
    double enY(double y) => y.clamp(_margen, maxY < _margen ? _margen : maxY);

    // Debajo, arriba, a la derecha o a la izquierda: el primer lado donde
    // cabe sin tapar el elemento.
    final abajo = h.bottom + _separacion;
    if (abajo <= maxY) return Offset(enX(h.left), abajo);
    final arriba = h.top - _separacion - child.height;
    if (arriba >= _margen) return Offset(enX(h.left), arriba);
    final derecha = h.right + _separacion;
    if (derecha <= maxX) return Offset(derecha, enY(h.top));
    final izquierda = h.left - _separacion - child.width;
    if (izquierda >= _margen) return Offset(izquierda, enY(h.top));
    return Offset(enX(h.left), maxY < _margen ? _margen : maxY);
  }

  @override
  bool shouldRelayout(_Colocar old) => old.hueco != hueco;
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.paso,
    required this.numero,
    required this.total,
    required this.ultimo,
    required this.onSaltar,
    required this.onAtras,
    required this.onSiguiente,
  });

  final PasoTutorial paso;
  final int numero;
  final int total;
  final bool ultimo;
  final VoidCallback onSaltar;
  final VoidCallback? onAtras;
  final VoidCallback onSiguiente;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paso.titulo,
                style: AppTypography.headline.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.flowDone,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                paso.texto,
                style: AppTypography.body.copyWith(fontSize: 13.5, color: AppColors.inkSoft, height: 1.45),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$numero / $total',
                    style: AppTypography.caption.copyWith(fontSize: 12, color: AppColors.inkMuted),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (!ultimo)
                          TextButton(
                            onPressed: onSaltar,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.inkMuted,
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: const Text('Saltar'),
                          ),
                        if (onAtras != null)
                          TextButton(
                            onPressed: onAtras,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.inkSoft,
                              backgroundColor: AppColors.bgTop,
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Atrás'),
                          ),
                        FilledButton(
                          onPressed: onSiguiente,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.flowDone,
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
                          ),
                          child: Text(ultimo ? 'Terminar' : 'Siguiente'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
