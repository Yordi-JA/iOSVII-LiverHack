import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puerta_liverpool/backend/candidatos/models.dart';
import 'package:puerta_liverpool/backend/models/person.dart';
import 'package:puerta_liverpool/frontend/core/widgets/toast_host.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_controller.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_page.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/widgets/candidate_table.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/widgets/decision_box.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/widgets/vacancy_header.dart';
import 'package:puerta_liverpool/frontend/features/procesos/widgets/stage_stepper.dart';
import 'package:puerta_liverpool/frontend/features/session/role_provider.dart';

import 'candidatos_fixture.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [liverhackSeedProvider.overrideWith((ref) async => fixtureSeed())],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: ToastHost(child: CandidatosPage()))),
    ));
    await settle(tester);
    return container;
  }

  testWidgets('AT: lista, alertas, límite de comparación y envío al HM', (tester) async {
    final container = await pumpPage(tester);
    final notifier = container.read(candidatosProvider.notifier);

    expect(find.text('Gerente de Proyectos E-commerce'), findsWidgets);
    // Sin avisos ni recuadros de conteo sobre la lista.
    expect(find.textContaining('sin veredicto de Aileen Vargas'), findsNothing);
    expect(find.text('Candidatos en la vacante'), findsNothing);
    // Solo la lista: sin compensación, sin título ni texto de ayuda.
    expect(find.text('Actual → deseada'), findsNothing);
    expect(find.textContaining('Compensación'), findsNothing);
    expect(find.textContaining('Haz clic en un candidato'), findsNothing);
    expect(find.textContaining('Prototipo con seed'), findsNothing);
    expect(find.text('Urgente, 6 días'), findsOneWidget);

    for (final id in [1, 2, 3, 4]) {
      notifier.togglePick(id);
    }
    notifier.togglePick(5);
    await settle(tester);
    expect(container.read(candidatosProvider).value!.pick, [1, 2, 3, 4]);
    expect(find.text('Puedes comparar hasta 4 candidatos a la vez.'), findsOneWidget);

    notifier.toggleOpen(4);
    await settle(tester);
    await tapVisible(tester, find.text('Enviar a Aileen Vargas'));
    await settle(tester);
    final mario = container.read(candidatosProvider).value!.candidatos.firstWhere((c) => c.id == 4);
    expect(mario.enviadoHm, isTrue);
    expect(mario.diasEsperandoHm, 0);
    expect(find.textContaining('Arranca el reloj de 3 días'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('La vista Vacantes del menú lateral cambia de vacante; el título es estático', (tester) async {
    final container = await pumpPage(tester);

    expect(find.text('Ver detalles'), findsNothing);
    expect(
      find.descendant(of: find.byType(VacancyHeader), matching: find.byIcon(Icons.keyboard_arrow_down_rounded)),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Cambiar de vacante'), findsNothing);

    await tapVisible(tester, find.text('Vacantes'));
    await settle(tester);
    expect(container.read(candidatosProvider).value!.view, CandidatosView.vacantes);
    expect(find.text('Tus vacantes'), findsOneWidget);
    expect(find.byType(StageStepper), findsNothing); // la lista de vacantes va sin encabezado

    await tapVisible(tester, find.text('Analista de Datos'));
    await settle(tester);
    final state = container.read(candidatosProvider).value!;
    expect(state.vacanteId, 'VAC-102');
    expect(state.view, CandidatosView.lista);
    expect(find.text('Tus vacantes'), findsNothing);
    expect(find.byType(StageStepper), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Requisición (HRBP) y Alineación (HM) avanzan la vacante con acciones de negocio', (tester) async {
    final container = await pumpPage(tester);
    final notifier = container.read(candidatosProvider.notifier);
    int etapa() => container.read(candidatosProvider).value!.vacante.etapaActual;
    int stepperStep() => tester.widget<StageStepper>(find.byType(StageStepper)).currentStep;

    // Etapa 1: el reclutador no ve candidatos, solo a quién se espera.
    notifier.selectVacante('VAC-103');
    await settle(tester);
    expect(find.text('Requisición en revisión'), findsOneWidget);
    expect(find.text('Validar posición y aprobar presupuesto'), findsNothing);
    expect(find.byType(CandidateListPanel), findsNothing);

    container.read(currentRoleProvider.notifier).select(UserRole.hrbp);
    await settle(tester);
    expect(find.text(r'$950k'), findsOneWidget);
    await tapVisible(tester, find.text('Validar posición y aprobar presupuesto'));
    await settle(tester);
    expect(etapa(), 2);
    expect(stepperStep(), 2);
    expect(find.textContaining('Presupuesto aprobado para'), findsOneWidget);
    expect(find.text('Esperando la alineación de Andrés Molina'), findsOneWidget);

    // Etapa 2: el HM ve la vacante en su desplegable y aprueba la alineación.
    container.read(currentRoleProvider.notifier).select(UserRole.hiringManager);
    await settle(tester);
    final hmVacantes = container.read(candidatosProvider).value!.vacantesVisibles(UserRole.hiringManager);
    expect(hmVacantes.map((v) => v.id), containsAll(['VAC-103', 'VAC-104']));
    expect(find.text('Retail 5+ años'), findsOneWidget);
    await tapVisible(tester, find.text('Aprobar Alineación'));
    await settle(tester);
    expect(etapa(), 3);
    expect(stepperStep(), 3);
    expect(find.textContaining('arranca el SLA'), findsOneWidget);
    expect(find.text('Aprobar Alineación'), findsNothing);
    expect(find.text('Búsqueda en curso'), findsOneWidget);

    // Solo se avanza un paso hacia adelante.
    notifier.avanzarEtapaVacante('VAC-103', 5);
    expect(etapa(), 3);

    expect(tester.takeException(), isNull);
  });

  testWidgets('HM: solo ve enviados, sin compensación actual, y decide con justificación', (tester) async {
    final container = await pumpPage(tester);
    container.read(currentRoleProvider.notifier).select(UserRole.hiringManager);
    await settle(tester);

    final state = container.read(candidatosProvider).value!;
    expect(state.visibles(UserRole.hiringManager).map((c) => c.id), [1, 2, 3]);
    expect(find.text('Tienes 2 candidatos esperando tu veredicto'), findsNothing);
    expect(find.text('Candidatos enviados a ti'), findsNothing);
    expect(find.text('Resumen'), findsNothing);
    expect(find.text('Actual → deseada'), findsNothing);
    expect(find.textContaining('Presupuesto hasta'), findsNothing);

    container.read(candidatosProvider.notifier).toggleOpen(1);
    await settle(tester);
    expect(find.text('Decisión del HM'), findsOneWidget);

    final finalistaButton = find.text('Marcar finalista');
    await tester.ensureVisible(campoDecision);
    await tester.enterText(campoDecision, 'Muy buena');
    await settle(tester);
    await tapVisible(tester, finalistaButton);
    await settle(tester);
    expect(container.read(candidatosProvider).value!.candidatos.first.status, StatusProceso.enProceso);

    await tester.ensureVisible(campoDecision);
    await tester.enterText(campoDecision, 'Cumple todos los no negociables y el presupuesto.');
    await settle(tester);
    await tapVisible(tester, finalistaButton);
    await settle(tester);

    final ana = container.read(candidatosProvider).value!.candidatos.first;
    expect(ana.status, StatusProceso.finalista);
    expect(ana.diasEsperandoHm, isNull);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Comparativa en tabla y radar; el menú lateral respeta etapa y rol', (tester) async {
    final container = await pumpPage(tester);
    final notifier = container.read(candidatosProvider.notifier);

    notifier.togglePick(1);
    notifier.togglePick(3);
    notifier.setView(CandidatosView.comparativa);
    await settle(tester);
    expect(find.text('Comparativa lado a lado'), findsOneWidget);
    expect(find.text('% de compatibilidad (potencial global)'), findsOneWidget);
    expect(find.text('Compensación actual'), findsOneWidget);

    notifier.setCmpMode(CmpMode.radar);
    await settle(tester);
    expect(find.text('Liderazgo'), findsWidgets);

    // Etapa 5: Candidatos y Comparativa en el menú lateral; se cambia de vista con él.
    expect(find.text('Resumen'), findsNothing);
    expect(find.text('Comparativa (2)'), findsOneWidget);
    await tapVisible(tester, find.text('Candidatos').last);
    await settle(tester);
    expect(container.read(candidatosProvider).value!.view, CandidatosView.lista);
    expect(find.text('Comparativa lado a lado'), findsNothing);

    // El menú se pliega a solo íconos y se vuelve a desplegar.
    await tapVisible(tester, find.byTooltip('Plegar menú'));
    await settle(tester);
    expect(find.text('Comparativa (2)'), findsNothing);
    expect(find.byTooltip('Desplegar menú'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Desplegar menú'));
    await settle(tester);
    expect(find.text('Comparativa (2)'), findsOneWidget);

    // El HRBP nunca ve la Comparativa, aunque la vista activa lo fuera.
    notifier.setView(CandidatosView.comparativa);
    container.read(currentRoleProvider.notifier).select(UserRole.hrbp);
    await settle(tester);
    expect(container.read(candidatosProvider).value!.view, CandidatosView.lista);
    expect(find.textContaining('Comparativa ('), findsNothing);
    expect(find.text('Comparativa lado a lado'), findsNothing);
    expect(find.byTooltip('Plegar menú'), findsOneWidget);

    // Etapa 1: el menú lateral solo ofrece "Vacantes".
    notifier.selectVacante('VAC-103');
    await settle(tester);
    expect(find.byTooltip('Plegar menú'), findsOneWidget);
    expect(find.text('Vacantes'), findsOneWidget);
    expect(find.textContaining('Comparativa ('), findsNothing);
    expect(find.byIcon(Icons.people_alt_outlined), findsNothing);

    expect(tester.takeException(), isNull);
  });
}

/// Avanza el reloj lo suficiente para animaciones y toasts sin esperar a que
/// terminen las animaciones continuas del flujo de etapas.
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

/// Campo de justificación de la caja de decisión del HM (la ficha también
/// tiene el lienzo colaborativo, con su propio TextField).
final campoDecision = find.descendant(of: find.byType(DecisionBox), matching: find.byType(TextField));
