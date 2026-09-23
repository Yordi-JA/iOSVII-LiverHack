import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulso/backend/providers.dart';
import 'package:pulso/frontend/features/procesos/procesos_controller.dart';
import 'package:pulso/frontend/features/procesos/procesos_page.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('la lista de postulantes sobrevive a filtros, selección y cambios de etapa', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // La fuente de pruebas (cuadros de ancho fijo) es más ancha que la real y
    // desborda el popup por píxeles; eso no es lo que este test verifica.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: ProcesosPage())),
    ));
    await settle(tester);

    final filter = container.read(stageFilterProvider.notifier);
    final selection = container.read(selectedCandidateProvider.notifier);
    final repo = container.read(talentRepositoryProvider);

    // Filtrar y quitar el filtro en cada etapa.
    for (var s = 1; s <= 6; s++) {
      filter.toggle(s);
      await settle(tester);
      filter.clear();
      await settle(tester);
    }

    // Con un popup abierto, avanzar candidatos de etapa (cambia el orden de la lista).
    for (final id in ['10', '1', '5', '3', '8']) {
      selection.select(id);
      await settle(tester);
      await repo.moveCandidate(id, 6);
      await settle(tester);
      selection.select(null);
      await settle(tester);
    }

    // Filtrar a una etapa y volver con elementos reordenados.
    filter.toggle(6);
    await settle(tester);
    filter.clear();
    await settle(tester);

    expect(tester.takeException(), isNull);
  });
}

/// Avanza el tiempo lo suficiente para terminar las animaciones de la fila
/// (hay animaciones continuas, así que pumpAndSettle nunca termina).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
