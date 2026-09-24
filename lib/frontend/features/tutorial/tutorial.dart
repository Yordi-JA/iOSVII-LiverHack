import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../backend/providers.dart';

/// Paso del tutorial: resalta el elemento marcado con [SpotlightTarget] de
/// id [target] y explica para qué sirve.
typedef PasoTutorial = ({String target, String titulo, String texto});

/// Recorrido por los puntos clave de la app, en orden. Los pasos cuyo
/// elemento no está en pantalla (por el rol o la etapa) se saltan solos.
const pasosTutorial = <PasoTutorial>[
  (
    target: 'rol',
    titulo: 'Cambia de rol',
    texto:
        'La demo simula tres perfiles: Reclutador, Hiring manager y HRBP. Cada uno ve información y '
        'acciones distintas. Cámbialo cuando quieras para recorrer el proceso completo.',
  ),
  (
    target: 'campana',
    titulo: 'Alertas de tu rol',
    texto:
        'Aquí llegan los pendientes que dependen de ti: veredictos atrasados, aprobaciones y avisos de SLA. '
        'Al tocar una alerta vas directo al candidato o a la vacante.',
  ),
  (
    target: 'menu',
    titulo: 'Menú de la vacante',
    texto:
        'En Vacantes cambias de vacante. Candidatos y Comparativa solo aparecen cuando la etapa y tu rol '
        'lo permiten.',
  ),
  (
    target: 'menu-dashboard',
    titulo: 'Dashboard del área',
    texto:
        'Vacantes cubiertas contra la meta, tardías, desempeño del equipo y tus pendientes del día. '
        'Solo lo ve Reclutamiento.',
  ),
  (
    target: 'flujo',
    titulo: 'Flujo de 6 etapas',
    texto:
        'Requisición, Alineación, Búsqueda, Atracción, Selección y Oferta. La vacante avanza con las '
        'acciones de cada rol, no a mano.',
  ),
  (
    target: 'flujo',
    titulo: 'Máquina del tiempo',
    texto:
        'Toca una etapa completada para ver cómo estaba el proceso en ese momento, en solo lectura. '
        'Toca la etapa actual para volver al presente.',
  ),
  (
    target: 'tiempo',
    titulo: 'Tiempo del proceso',
    texto:
        'Días que lleva la vacante contra los estimados para las 6 etapas. Se pone en rojo cuando el '
        'proceso se pasa del tiempo.',
  ),
  (
    target: 'accion',
    titulo: 'Lo que toca hacer',
    texto:
        'En Requisición, Alineación y Búsqueda aquí aparece la acción del rol responsable, o a quién '
        'se está esperando.',
  ),
  (
    target: 'lista',
    titulo: 'Lista de candidatos',
    texto:
        'Abre un candidato para ver su CV, el resumen de AssessFirst, sus entrevistas y el lienzo '
        'colaborativo. Marca casillas para compararlos o moverlos a entrevista.',
  ),
  (
    target: 'ayuda',
    titulo: '¿Quieres repasarlo?',
    texto: 'Vuelve a abrir este recorrido desde aquí cuando lo necesites.',
  ),
];

/// Paso activo del tutorial (índice entre los pasos visibles) o `null` si
/// está cerrado.
class TutorialNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void iniciar() => state = 0;

  void ir(int paso) => state = paso;

  /// Cierra el recorrido (al terminar o al saltarlo) y ya no se abre solo.
  void cerrar() {
    state = null;
    ref.read(liverhackStoreProvider).tutorialVisto = true;
  }
}

final tutorialProvider = NotifierProvider<TutorialNotifier, int?>(TutorialNotifier.new);
