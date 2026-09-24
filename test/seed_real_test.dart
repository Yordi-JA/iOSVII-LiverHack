import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puerta_liverpool/backend/candidatos/models.dart';
import 'package:puerta_liverpool/backend/models/person.dart';
import 'package:puerta_liverpool/frontend/core/widgets/toast_host.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_controller.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_page.dart';
import 'package:puerta_liverpool/frontend/features/session/role_provider.dart';

LiverhackSeed realSeed() => LiverhackSeed.fromJson(
      jsonDecode(File('assets/seed_data_liverhack.json').readAsStringSync()) as Map<String, dynamic>,
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('el seed real trae 11 vacantes y 34 candidatos (6 aún en Aira), todos con vacante', () {
    final seed = realSeed();
    final ids = seed.vacantes.map((v) => v.id).toSet();
    expect(seed.vacantes, hasLength(11));
    expect(seed.vacantes.where((v) => v.etapaActual <= 2).map((v) => v.id), ['VAC-110', 'VAC-111']);
    expect(seed.candidatos, hasLength(34));
    expect(seed.candidatos.where((c) => !c.importado).map((c) => c.vacanteId).toSet(), {'VAC-110', 'VAC-111'});
    expect(seed.candidatos.where((c) => !ids.contains(c.vacanteId)), isEmpty);
  });

  testWidgets('todas las vacantes, roles y vistas se renderizan con el seed real', (tester) async {
    tester.view.physicalSize = const Size(1700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final seed = realSeed();
    final container = ProviderContainer(overrides: [liverhackSeedProvider.overrideWith((ref) async => seed)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: ToastHost(child: CandidatosPage()))),
    ));
    await settle(tester);

    final notifier = container.read(candidatosProvider.notifier);
    for (final role in [UserRole.reclutador, UserRole.hiringManager, UserRole.hrbp]) {
      container.read(currentRoleProvider.notifier).select(role);
      await settle(tester);
      for (final v in seed.vacantes) {
        notifier.selectVacante(v.id);
        final visibles = container.read(candidatosProvider).value!.visibles(role);
        if (visibles.isNotEmpty) notifier.toggleOpen(visibles.first.id);
        await settle(tester);
        for (final c in visibles.take(4)) {
          notifier.togglePick(c.id);
        }
        notifier.setView(CandidatosView.comparativa);
        notifier.setCmpMode(CmpMode.tabla);
        await settle(tester);
        notifier.setCmpMode(CmpMode.radar);
        await settle(tester);
        notifier.setView(CandidatosView.vacantes);
        await settle(tester);
        notifier.setView(CandidatosView.lista);
        await settle(tester);
        final e = tester.takeException();
        expect(e, isNull, reason: '${role.name} ${v.id}: $e');
      }
    }
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
