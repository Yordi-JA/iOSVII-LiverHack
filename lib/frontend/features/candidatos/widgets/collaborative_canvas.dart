import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/entrevistas/entrevistas_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../session/role_provider.dart';
import 'ui_kit.dart';

/// Lienzo de notas de la entrevista que Reclutamiento y el Hiring manager
/// editan al mismo tiempo. Lee y escribe `entrevistas/candidato_{id}` en
/// Firestore; sin Firebase configurado funciona en modo local.
class CollaborativeCanvas extends ConsumerStatefulWidget {
  const CollaborativeCanvas({super.key, required this.candidatoId});

  final int candidatoId;

  /// Espera tras la última tecla antes de escribir en Firestore.
  static const debounce = Duration(milliseconds: 500);

  @override
  ConsumerState<CollaborativeCanvas> createState() => _CollaborativeCanvasState();
}

class _CollaborativeCanvasState extends ConsumerState<CollaborativeCanvas> {
  final _controller = TextEditingController();
  Timer? _debounce;

  /// Hay cambios locales aún sin escribir: no se pisan con lo que llega del servidor.
  var _pendiente = false;
  Object? _errorAlGuardar;

  @override
  void initState() {
    super.initState();
    ref.listenManual(notasEntrevistaProvider(widget.candidatoId), (_, next) {
      final remoto = next.value;
      if (remoto == null || _pendiente || remoto == _controller.text) return;
      // Llega la versión de la otra persona: se aplica conservando el cursor.
      final cursor = _controller.selection.baseOffset.clamp(0, remoto.length);
      _controller.value = TextEditingValue(text: remoto, selection: TextSelection.collapsed(offset: cursor));
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    // Si quedaba algo por escribir, se guarda antes de cerrar la ficha.
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      _guardar(montado: false);
    }
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _pendiente = true;
    _debounce?.cancel();
    _debounce = Timer(CollaborativeCanvas.debounce, _guardar);
    setState(() {});
  }

  Future<void> _guardar({bool montado = true}) async {
    final repo = ref.read(entrevistasRepositoryProvider);
    final autor = ref.read(currentRoleProvider).label;
    try {
      await repo.actualizarNotas(widget.candidatoId, _controller.text, autor: autor);
      _errorAlGuardar = null;
    } catch (e) {
      _errorAlGuardar = e;
    }
    if (!montado || !mounted) return;
    setState(() => _pendiente = _debounce?.isActive ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final enLinea = ref.watch(entrevistasRepositoryProvider).enLinea;
    final notas = ref.watch(notasEntrevistaProvider(widget.candidatoId));

    final (etiqueta, color) = switch ((enLinea, notas)) {
      (false, _) => ('⚪ Modo local (Firebase no configurado)', AppColors.inkSoft),
      (true, AsyncError()) => ('🔴 Sin conexión con Firestore', AppColors.danger),
      _ when _errorAlGuardar != null => ('🔴 No se pudo guardar en Firestore', AppColors.danger),
      (true, AsyncLoading()) => ('⏳ Conectando…', AppColors.inkSoft),
      _ => ('🟢 Sincronizado en tiempo real', AppColors.success),
    };

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lienzo colaborativo de la entrevista',
                      style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reclutamiento y el Hiring manager escriben aquí al mismo tiempo.',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Text(etiqueta, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            onChanged: _onChanged,
            minLines: 6,
            maxLines: 14,
            style: AppTypography.body,
            decoration: InputDecoration(
              hintText: 'Notas de la entrevista: fortalezas observadas, dudas, acuerdos, siguientes pasos…',
              hintStyle: AppTypography.body.copyWith(color: AppColors.inkMuted),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.65),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: CColors.line)),
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
            _pendiente ? 'Guardando…' : 'Los cambios se guardan solos al dejar de escribir.',
            style: AppTypography.caption.copyWith(fontSize: 11.5, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
