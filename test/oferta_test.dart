import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puerta_liverpool/backend/candidatos/models.dart';
import 'package:puerta_liverpool/backend/candidatos/seed_repository.dart';
import 'package:puerta_liverpool/backend/models/person.dart';
import 'package:puerta_liverpool/backend/providers.dart';
import 'package:puerta_liverpool/frontend/core/widgets/toast_host.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_controller.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_page.dart';
import 'package:puerta_liverpool/frontend/features/notifications/role_alerts.dart';
import 'package:puerta_liverpool/frontend/features/session/role_provider.dart';
import 'package:puerta_liverpool/frontend/features/workspace/workspace_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'candidatos_fixture.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('seleccionar finalista cierra el embudo y el HRBP aprueba la oferta; todo persiste', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer app() {
      final c = ProviderContainer(
        overrides: [
          liverhackSeedProvider.overrideWith((ref) async => fixtureSeed()),
          liverhackStoreProvider.overrideWithValue(LiverhackStore(prefs)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    final c = app();
    await c.read(candidatosProvider.future);
    final n = c.read(candidatosProvider.notifier);

    // VAC-101: Ana (1) gana; los otros 4 activos de la vacante se descartan.
    expect(n.seleccionarFinalista(1, 'Cumple todos los no negociables y el presupuesto.'), 4);
    var s = c.read(candidatosProvider).value!;
    final vac = s.candidatos.where((x) => x.vacanteId == 'VAC-101').toList();
    expect(vac.firstWhere((x) => x.id == 1).status, StatusProceso.oferta);
    expect(vac.where((x) => x.id != 1).every((x) => x.status == StatusProceso.descartado), isTrue);
    expect(vac.firstWhere((x) => x.id == 3).statusJustificacion, contains('Descarte automático'));
    expect(s.vacantes.firstWhere((v) => v.id == 'VAC-101').etapaActual, 6);
    expect(
      c.read(workspaceSnackProvider)?.message,
      '¡Candidato movido a Oferta! Se enviaron 4 correos automáticos de agradecimiento a los descartados.',
    );
    // El candidato de otra vacante no se toca.
    expect(s.candidatos.firstWhere((x) => x.id == 6).status, StatusProceso.enProceso);

    // El HRBP recibe la notificación de compensación.
    c.read(currentRoleProvider.notifier).select(UserRole.hrbp);
    expect(
      c.read(roleAlertsProvider).first.title,
      '💰 El HM ha seleccionado a Ana López. Requiere tu aprobación de paquete de compensación (Expectativa: \$1.2M).',
    );

    n.aprobarOferta('VAC-101');
    s = c.read(candidatosProvider).value!;
    expect(s.vacantes.firstWhere((v) => v.id == 'VAC-101').ofertaAprobada, isTrue);
    expect(c.read(workspaceSnackProvider)?.message, startsWith('Trámites de contratación iniciados para Ana López'));
    expect(c.read(roleAlertsProvider).where((a) => a.title.startsWith('💰')), isEmpty);

    // "Recarga".
    final despues = app();
    final r = await despues.read(candidatosProvider.future);
    expect(r.candidatos.firstWhere((x) => x.id == 1).status, StatusProceso.oferta);
    expect(r.candidatos.firstWhere((x) => x.id == 2).status, StatusProceso.descartado);
    expect(r.vacantes.firstWhere((v) => v.id == 'VAC-101').etapaActual, 6);
    expect(r.vacantes.firstWhere((v) => v.id == 'VAC-101').ofertaAprobada, isTrue);
  });

  testWidgets('HM selecciona para oferta con justificación; HRBP aprueba el presupuesto', (tester) async {
    tester.view.physicalSize = const Size(1700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final c = ProviderContainer(overrides: [liverhackSeedProvider.overrideWith((ref) async => fixtureSeed())]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        home: Scaffold(body: WorkspaceSnackHost(child: ToastHost(child: CandidatosPage()))),
      ),
    ));
    await settle(tester);

    // El reclutador no ve el botón.
    c.read(candidatosProvider.notifier).toggleOpen(1);
    await settle(tester);
    expect(find.text('Seleccionar para Oferta'), findsNothing);

    c.read(currentRoleProvider.notifier).select(UserRole.hiringManager);
    await settle(tester);
    c.read(candidatosProvider.notifier).toggleOpen(1);
    await settle(tester);
    await tapVisible(tester, find.text('Seleccionar para Oferta'));
    await settle(tester);
    expect(
      find.text(
        '¿Estás seguro de seleccionar a Ana López para la oferta final? '
        'Los demás candidatos en este proceso serán descartados automáticamente.',
      ),
      findsOneWidget,
    );

    FilledButton confirmar() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirmar selección'));
    expect(confirmar().onPressed, isNull);
    await tester.enterText(find.widgetWithText(TextField, 'Justificación de selección'), 'Muy buena');
    await settle(tester);
    expect(confirmar().onPressed, isNull);
    await tester.enterText(
      find.widgetWithText(TextField, 'Justificación de selección'),
      'La mejor combinación de experiencia y ajuste al presupuesto.',
    );
    await settle(tester);
    expect(confirmar().onPressed, isNotNull);
    await tester.tap(find.text('Confirmar selección'));
    await settle(tester);

    expect(find.textContaining('¡Candidato movido a Oferta!'), findsOneWidget);
    expect(find.text('Oferta final'), findsOneWidget);
    expect(find.text('Esperando la aprobación de Paola Núñez (HRBP).'), findsOneWidget);

    c.read(currentRoleProvider.notifier).select(UserRole.hrbp);
    await settle(tester);
    await tapVisible(tester, find.text('Aprobar Presupuesto'));
    await settle(tester);
    expect(find.text('Trámites de contratación iniciados.'), findsOneWidget);
    expect(find.text('Contratación en trámite'), findsOneWidget);

    expect(tester.takeException(), isNull);
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
