import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puerta_liverpool/backend/candidatos/models.dart';
import 'package:puerta_liverpool/backend/models/person.dart';
import 'package:puerta_liverpool/frontend/app/app.dart';
import 'package:puerta_liverpool/frontend/core/widgets/toast_host.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_controller.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_page.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/widgets/decision_box.dart';
import 'package:puerta_liverpool/frontend/features/notifications/role_alerts.dart';
import 'package:puerta_liverpool/frontend/features/session/role_provider.dart';
import 'package:puerta_liverpool/frontend/features/workspace/workspace_style.dart';

import 'candidatos_fixture.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [liverhackSeedProvider.overrideWith((ref) async => fixtureSeed())]);
    addTearDown(c.dispose);
    return c;
  }

  test('las alertas cambian según el rol activo', () async {
    final c = container();
    await c.read(candidatosProvider.future);

    c.read(currentRoleProvider.notifier).select(UserRole.hiringManager);
    final hm = c.read(roleAlertsProvider);
    expect(hm.first.title, '3 candidatos esperan tu feedback hace más de 3 días (SLA en riesgo).');
    expect(hm.map((a) => a.title), contains('Alineación pendiente: Coordinador de Logística.'));

    c.read(currentRoleProvider.notifier).select(UserRole.hrbp);
    final hrbp = c.read(roleAlertsProvider);
    expect(hrbp.single.title, 'La requisición excede el tabulador, requiere aprobación.');
    expect(hrbp.single.vacanteId, 'VAC-103');

    // Al aprobar la alineación, Reclutamiento recibe el aviso.
    c.read(currentRoleProvider.notifier).select(UserRole.reclutador);
    c.read(candidatosProvider.notifier).avanzarEtapaVacante('VAC-104', 3);
    final at = c.read(roleAlertsProvider);
    expect(at.map((a) => a.title), contains('El HM aprobó la alineación.'));

    // Abrir la campana las marca como vistas.
    expect(c.read(unseenRoleAlertsProvider), at.length);
    c.read(seenRoleAlertsProvider.notifier).markSeen(at.map((a) => a.id));
    expect(c.read(unseenRoleAlertsProvider), 0);
  });

  test('descartar dispara el aviso del correo automático de Gmail', () async {
    final c = container();
    await c.read(candidatosProvider.future);
    c.read(candidatosProvider.notifier).decidir(3, StatusProceso.descartado, 'No cubre el presupuesto de la vacante.');
    expect(
      c.read(workspaceSnackProvider)?.message,
      'Candidato descartado. Correo automático de retroalimentación enviado vía Gmail.',
    );
  });

  testWidgets('Hub de Workspace: Chat, Gmail con template y SnackBar de descarte', (tester) async {
    tester.view.physicalSize = const Size(1700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final c = container();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        home: Scaffold(body: WorkspaceSnackHost(child: ToastHost(child: CandidatosPage()))),
      ),
    ));
    await settle(tester);
    c.read(candidatosProvider.notifier).toggleOpen(1);
    await settle(tester);

    // Chat.
    await tapVisible(tester, find.text('Chat'));
    await settle(tester);
    expect(find.text('Mensaje a Ana'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Mensaje a Ana'), '¿Te queda bien a las 5?');
    await tester.tap(find.byTooltip('Enviar mensaje'));
    await settle(tester);
    expect(find.text('¿Te queda bien a las 5?'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar').last);
    await settle(tester);

    // Gmail con template (Reclutador).
    await tapVisible(tester, find.text('Gmail'));
    await settle(tester);
    expect(find.text('Mensaje nuevo'), findsOneWidget);
    expect(find.text('ana.lopez@correo.com'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await settle(tester);
    await tester.tap(find.text('Agendar llamada técnica').last);
    await settle(tester);
    expect(find.text('Llamada técnica – Gerente de Proyectos E-commerce'), findsOneWidget);
    await tester.tap(find.text('Enviar'));
    await settle(tester);
    expect(find.text('Mensaje nuevo'), findsNothing);
    expect(find.text('Mensaje enviado a ana.lopez@correo.com.'), findsOneWidget);

    // Gmail es solo para Reclutamiento.
    c.read(currentRoleProvider.notifier).select(UserRole.hiringManager);
    await settle(tester);
    c.read(candidatosProvider.notifier).toggleOpen(3);
    await settle(tester);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Gmail'), findsNothing);

    // Descarte desde la caja de decisión del HM.
    await tester.ensureVisible(campoDecision);
    await tester.enterText(campoDecision, 'No cubre los no negociables de la vacante.');
    await settle(tester);
    await tapVisible(tester, find.text('Descartar'));
    await settle(tester);
    expect(find.text('Candidato descartado. Correo automático de retroalimentación enviado vía Gmail.'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('La barra superior: menú de rol desplegable, sin buscador, controles a la derecha', (tester) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final c = container();
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const PuertaLiverpoolApp()));
    await settle(tester);
    tester.takeException(); // desbordes de la fuente de pruebas, ajenos a este test

    expect(find.text('Buscar candidato'), findsNothing);
    // Orden de izquierda a derecha: marca … rol, campana, perfil.
    final xRol = tester.getCenter(find.byTooltip('Cambiar de rol')).dx;
    final xCampana = tester.getCenter(find.byTooltip('Notificaciones')).dx;
    final xPerfil = tester.getCenter(find.text('Hola,')).dx;
    expect(xRol < xCampana && xCampana < xPerfil, isTrue);

    await tester.tap(find.byTooltip('Cambiar de rol'));
    await settle(tester);
    expect(find.text('HM'), findsOneWidget);
    await tester.tap(find.text('HRBP').last);
    await settle(tester);
    expect(c.read(currentRoleProvider), UserRole.hrbp);
    expect(find.text('HRBP'), findsWidgets);
  });

  testWidgets('La campana de la barra superior muestra las alertas del rol y navega', (tester) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final c = container();
    c.read(currentRoleProvider.notifier).select(UserRole.hrbp);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const PuertaLiverpoolApp()));
    await settle(tester);
    // La fuente de pruebas es más ancha que Inter; los desbordes de texto no son el objeto de este test.
    tester.takeException();

    await tester.tap(find.byTooltip('Notificaciones'));
    await settle(tester);
    expect(find.text('Notificaciones · HRBP'), findsOneWidget);
    await tester.tap(find.text('La requisición excede el tabulador, requiere aprobación.'));
    await settle(tester);
    expect(c.read(candidatosProvider).value!.vacanteId, 'VAC-103');
    expect(c.read(unseenRoleAlertsProvider), 0);
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

/// Campo de justificación de la caja de decisión del HM (la ficha también
/// tiene el lienzo colaborativo, con su propio TextField).
final campoDecision = find.descendant(of: find.byType(DecisionBox), matching: find.byType(TextField));
