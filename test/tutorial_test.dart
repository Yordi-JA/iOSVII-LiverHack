import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puerta_liverpool/backend/candidatos/seed_repository.dart';
import 'package:puerta_liverpool/backend/models/person.dart';
import 'package:puerta_liverpool/backend/providers.dart';
import 'package:puerta_liverpool/frontend/core/layout/app_shell.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_controller.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_page.dart';
import 'package:puerta_liverpool/frontend/features/session/role_provider.dart';
import 'package:puerta_liverpool/frontend/features/tutorial/tutorial.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'candidatos_fixture.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pumpApp(WidgetTester tester, {LiverhackStore store = const LiverhackStore(null)}) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        liverhackSeedProvider.overrideWith((ref) async => fixtureSeed()),
        liverhackStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AppShell(child: CandidatosPage())),
      ),
    );
    await settle(tester);
    return container;
  }

  testWidgets('El tutorial se abre desde la ayuda y recorre los puntos clave', (tester) async {
    final c = await pumpApp(tester);
    expect(find.text('Cambia de rol'), findsNothing); // sin almacenamiento no arranca solo

    await tester.tap(find.byTooltip('Ver tutorial'));
    await settle(tester);

    // Reclutador en VAC-101 (etapa 5): todos los pasos menos "Lo que toca hacer".
    final total = pasosTutorial.where((p) => p.target != 'accion').length;
    expect(find.text('Cambia de rol'), findsOneWidget);
    expect(find.text('1 / $total'), findsOneWidget);
    expect(find.text('Atrás'), findsNothing);

    await tester.tap(find.text('Siguiente'));
    await settle(tester);
    expect(find.text('Alertas de tu rol'), findsOneWidget);
    expect(find.text('2 / $total'), findsOneWidget);

    await tester.tap(find.text('Atrás'));
    await settle(tester);
    expect(find.text('Cambia de rol'), findsOneWidget);

    // Recorre todo con el teclado; el último paso dice "Terminar".
    for (var i = 1; i < total; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);
    }
    expect(find.text('Lista de candidatos'), findsNothing); // ya pasó
    expect(find.text('¿Quieres repasarlo?'), findsOneWidget);
    expect(find.text('$total / $total'), findsOneWidget);
    await tester.tap(find.text('Terminar'));
    await settle(tester);
    expect(c.read(tutorialProvider), isNull);
    expect(find.text('¿Quieres repasarlo?'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Se salta los pasos sin elemento en pantalla y se cierra con Saltar', (tester) async {
    final c = await pumpApp(tester);
    c.read(currentRoleProvider.notifier).select(UserRole.hrbp);
    c.read(candidatosProvider.notifier).selectVacante('VAC-103'); // etapa 1
    await settle(tester);

    await tester.tap(find.byTooltip('Ver tutorial'));
    await settle(tester);
    // HRBP en etapa 1: sin Dashboard, sin lista; con "Lo que toca hacer".
    final total = pasosTutorial.where((p) => p.target != 'menu-dashboard' && p.target != 'lista').length;
    expect(find.text('1 / $total'), findsOneWidget);

    await tester.tap(find.text('Saltar'));
    await settle(tester);
    expect(c.read(tutorialProvider), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arranca solo la primera vez y no vuelve a aparecer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LiverhackStore(prefs);

    final c = await pumpApp(tester, store: store);
    expect(find.text('Cambia de rol'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(c.read(tutorialProvider), isNull);
    expect(store.tutorialVisto, isTrue);
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
