import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puerta_liverpool/backend/models/person.dart';
import 'package:puerta_liverpool/backend/seed/seed_data.dart';
import 'package:puerta_liverpool/backend/seed/seed_history.dart';
import 'package:puerta_liverpool/frontend/core/layout/app_shell.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_controller.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_page.dart';
import 'package:puerta_liverpool/frontend/features/dashboard/attraction_metrics.dart';
import 'package:puerta_liverpool/frontend/features/dashboard/dashboard_page.dart';
import 'package:puerta_liverpool/frontend/features/session/role_provider.dart';

import 'candidatos_fixture.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [liverhackSeedProvider.overrideWith((ref) async => fixtureSeed())]);
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

  testWidgets('Reclutador: el dashboard abre desde el menú con los indicadores de la demo', (tester) async {
    final c = await pumpApp(tester);

    await tester.tap(find.text('Dashboard'));
    await settle(tester);
    expect(c.read(candidatosProvider).value!.view, CandidatosView.dashboard);
    expect(find.text('Atracción de Talento'), findsOneWidget);

    // "Este año": 45 de 72 (7 abajo del ritmo), 15 abiertas, 7 tardías,
    // 2 en stand-by, 38 días de time to fill y 42 % en SLA.
    expect(find.text('45 de 72'), findsOneWidget);
    expect(find.text('7 abajo del ritmo'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('38 días'), findsOneWidget);
    expect(find.text('42 %'), findsOneWidget);

    // Cambiar el periodo actualiza los indicadores que dependen de él.
    final m30 = AttractionMetrics(
      records: generateHiringHistory(),
      hoy: demoToday,
      metaAnual: metaAnual,
      periodo: Periodo.dias30,
    );
    await tester.tap(find.text('30 días'));
    await settle(tester);
    expect(find.text('45 de 72'), findsNothing);
    expect(find.text('${m30.cubiertas.length}'), findsWidgets);
    expect(find.text('${m30.timeToFill} días'), findsOneWidget);
    expect(find.text('15'), findsOneWidget); // las abiertas no dependen del periodo

    // "Mis asuntos" del reclutador: solo lo suyo.
    expect(find.text('Tus pendientes de hoy'), findsOneWidget);

    // Las métricas del equipo están plegadas y se despliegan sin desbordes.
    expect(find.text('Hallazgos para el equipo'), findsNothing);
    await tester.ensureVisible(find.text('Métricas para el equipo'));
    await settle(tester);
    await tester.tap(find.text('Métricas para el equipo'));
    await settle(tester);
    await tester.ensureVisible(find.text('Embudo de candidatos'));
    await settle(tester);
    expect(find.text('Hallazgos para el equipo'), findsOneWidget);
    expect(find.text('Fuentes de contratación'), findsOneWidget);
    expect(find.text('Días reales vs SLA por etapa'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Solo el Reclutador ve el dashboard', (tester) async {
    final c = await pumpApp(tester);
    await tester.tap(find.text('Dashboard'));
    await settle(tester);

    for (final role in [UserRole.hiringManager, UserRole.hrbp]) {
      c.read(currentRoleProvider.notifier).select(role);
      await settle(tester);
      expect(find.text('Dashboard'), findsNothing, reason: role.name);
      expect(find.text('Atracción de Talento'), findsNothing, reason: role.name);
      expect(c.read(candidatosProvider).value!.view, isNot(CandidatosView.dashboard));
    }
    expect(tester.takeException(), isNull);
  });

  test('"Mis asuntos" cambia según el rol', () {
    final m = AttractionMetrics(records: generateHiringHistory(), hoy: demoToday, metaAnual: metaAnual);
    final propios = misAsuntos(role: UserRole.reclutador, nombre: 'Mariana Ortega', m: m, alertas: seedAlerts);
    final equipo = misAsuntos(role: UserRole.hrbp, nombre: 'Mayra Cuandon', m: m, alertas: seedAlerts);

    final deMariana = m.tardias.where((r) => r.reclutador == 'Mariana Ortega').length.clamp(0, 3);
    expect(propios.where((a) => a.icon == Icons.warning_amber_rounded), hasLength(deMariana));
    expect(propios.any((a) => a.titulo.contains('ritmo')), isFalse);
    expect(equipo.first.titulo, contains('abajo del ritmo'));
    expect(equipo.length, greaterThan(propios.length));
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
