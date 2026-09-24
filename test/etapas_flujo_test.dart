import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puerta_liverpool/backend/candidatos/seed_repository.dart';
import 'package:puerta_liverpool/backend/models/person.dart';
import 'package:puerta_liverpool/backend/providers.dart';
import 'package:puerta_liverpool/frontend/core/widgets/toast_host.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_controller.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_page.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/widgets/candidate_table.dart';
import 'package:puerta_liverpool/frontend/features/procesos/widgets/stage_stepper.dart';
import 'package:puerta_liverpool/frontend/features/session/role_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'candidatos_fixture.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Etapas 2 a 5: negociar el perfil, importar desde Aira y mover a entrevista con el HM', (tester) async {
    tester.view.physicalSize = const Size(1700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [liverhackSeedProvider.overrideWith((ref) async => fixtureSeed())]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: ToastHost(child: CandidatosPage()))),
    ));
    await settle(tester);

    final notifier = container.read(candidatosProvider.notifier);
    CandidatosState state() => container.read(candidatosProvider).value!;
    int stepper() => tester.widget<StageStepper>(find.byType(StageStepper)).currentStep;

    // Etapa 2 (HM): negocia presupuesto y no negociables.
    container.read(currentRoleProvider.notifier).select(UserRole.hiringManager);
    notifier.selectVacante('VAC-104');
    await settle(tester);
    expect(find.text('Aprobar Alineación'), findsOneWidget);

    await tapVisible(tester, find.text('Editar Perfil / Negociar'));
    await settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '750000');
    await tester.enterText(find.byType(TextFormField).at(1), 'Última milla\n\nSAP EWM\nInglés B2');
    await tester.tap(find.text('Guardar cambios'));
    await settle(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(state().vacante.presupuestoMax, 750000);
    expect(state().vacante.perfilNoNegociables, ['Última milla', 'SAP EWM', 'Inglés B2']);
    expect(find.text('Inglés B2'), findsOneWidget);
    expect(find.textContaining(r'$750k'), findsOneWidget);

    await tapVisible(tester, find.text('Aprobar Alineación'));
    await settle(tester);
    expect(state().vacante.etapaActual, 3);
    expect(stepper(), 3);

    // Etapa 3 (Reclutador): importa desde Aira; con los candidatos, pasa a Atracción.
    container.read(currentRoleProvider.notifier).select(UserRole.reclutador);
    await settle(tester);
    expect(find.byType(CandidateListPanel), findsNothing);
    expect(find.textContaining('2 perfiles de Aira'), findsOneWidget);
    await tapVisible(tester, find.text('Importar candidatos desde ATS (Aira)'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Consultando Aira…'), findsOneWidget);
    expect(state().vacante.etapaActual, 3);
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(state().vacante.etapaActual, 4);
    expect(stepper(), 4);
    expect(find.byType(CandidateListPanel), findsOneWidget);
    expect(find.text('Luis Arriaga'), findsOneWidget);
    expect(find.text('Karla Méndez'), findsOneWidget);

    // Etapa 4 (Reclutador): mueve a los seleccionados a entrevista con el HM.
    // La barra de acciones solo aparece con candidatos marcados.
    expect(find.textContaining('Mover seleccionados'), findsNothing);
    notifier.togglePick(7);
    notifier.togglePick(8);
    await settle(tester);
    await tapVisible(tester, find.text('Mover seleccionados a Entrevista con HM (2)'));
    await settle(tester);
    expect(state().candidatos.where((c) => c.vacanteId == 'VAC-104').every((c) => c.enviadoHm && c.diasEsperandoHm == 0), isTrue);
    expect(state().vacante.etapaActual, 5);
    expect(stepper(), 5);
    expect(find.textContaining('La vacante pasa a Selección'), findsOneWidget);

    // El HM ya los ve.
    container.read(currentRoleProvider.notifier).select(UserRole.hiringManager);
    await settle(tester);
    expect(state().visibles(UserRole.hiringManager).map((c) => c.id), containsAll([7, 8]));

    expect(tester.takeException(), isNull);
  });

  test('los avances de las etapas 2 a 5 sobreviven a una recarga', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    CandidatosNotifier.atsDelay = Duration.zero;
    addTearDown(() => CandidatosNotifier.atsDelay = const Duration(seconds: 1));

    ProviderContainer app() => ProviderContainer(
      overrides: [
        liverhackSeedProvider.overrideWith((ref) async => fixtureSeed()),
        liverhackStoreProvider.overrideWithValue(LiverhackStore(prefs)),
      ],
    );

    final antes = app();
    await antes.read(candidatosProvider.future);
    final n = antes.read(candidatosProvider.notifier);
    n.editarPerfilVacante('VAC-104', presupuestoMax: 750000, noNegociables: ['Última milla', 'Inglés B2']);
    n.avanzarEtapaVacante('VAC-104', 3);
    expect(await n.importarDesdeAts('VAC-104'), 2);
    n.moverAEntrevistaHm([7]);
    antes.dispose();

    // "Recarga": un contenedor nuevo con el mismo almacenamiento.
    final despues = app();
    addTearDown(despues.dispose);
    final s = await despues.read(candidatosProvider.future);
    final v = s.vacantes.firstWhere((v) => v.id == 'VAC-104');
    expect(v.etapaActual, 5);
    expect(v.presupuestoMax, 750000);
    expect(v.perfilNoNegociables, ['Última milla', 'Inglés B2']);
    expect(s.candidatos.where((c) => c.vacanteId == 'VAC-104').map((c) => c.id), [7, 8]);
    expect(s.candidatos.firstWhere((c) => c.id == 7).enviadoHm, isTrue);
    expect(s.candidatos.firstWhere((c) => c.id == 8).enviadoHm, isFalse);
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await settle(tester);
  await tester.tap(finder);
}
