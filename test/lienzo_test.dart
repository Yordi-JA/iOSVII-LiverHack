import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puerta_liverpool/backend/entrevistas/entrevistas_repository.dart';
import 'package:puerta_liverpool/backend/models/person.dart';
import 'package:puerta_liverpool/frontend/core/widgets/toast_host.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_controller.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_page.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/widgets/collaborative_canvas.dart';
import 'package:puerta_liverpool/frontend/features/session/role_provider.dart';

import 'candidatos_fixture.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('el repositorio de Firestore lee y escribe entrevistas/candidato_{id}', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreEntrevistasRepository(db);

    expect(await repo.watchNotas(7).first, '');
    await repo.actualizarNotas(7, 'Buena comunicación.', autor: 'HM');

    final doc = await db.collection('entrevistas').doc('candidato_7').get();
    expect(doc.data()!['notas'], 'Buena comunicación.');
    expect(doc.data()!['autor'], 'HM');
    expect(doc.data()!['candidato_id'], 7);
    expect(await repo.watchNotas(7).first, 'Buena comunicación.');
  });

  testWidgets('dos personas editan el mismo lienzo: se sincroniza con debounce de 500 ms', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = FakeFirebaseFirestore();
    await tester.pumpWidget(ProviderScope(
      overrides: [entrevistasRepositoryProvider.overrideWithValue(FirestoreEntrevistasRepository(db))],
      child: const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              // Reclutador y Hiring manager con la misma ficha abierta.
              Expanded(child: SingleChildScrollView(child: CollaborativeCanvas(key: Key('at'), candidatoId: 1))),
              Expanded(child: SingleChildScrollView(child: CollaborativeCanvas(key: Key('hm'), candidatoId: 1))),
            ],
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('🟢 Sincronizado en tiempo real'), findsNWidgets(2));

    final at = find.descendant(of: find.byKey(const Key('at')), matching: find.byType(TextField));
    final hm = find.descendant(of: find.byKey(const Key('hm')), matching: find.byType(TextField));

    await tester.enterText(at, 'Domina SAP EWM');
    await tester.pump(const Duration(milliseconds: 300));
    // Antes de los 500 ms no se ha escrito nada en Firestore.
    expect((await db.collection('entrevistas').doc('candidato_1').get()).exists, isFalse);
    expect(find.text('Guardando…'), findsOneWidget);

    await tester.enterText(at, 'Domina SAP EWM y última milla');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect((await db.collection('entrevistas').doc('candidato_1').get()).data()!['notas'], 'Domina SAP EWM y última milla');
    expect(tester.widget<TextField>(hm).controller!.text, 'Domina SAP EWM y última milla');

    // Y en sentido contrario.
    await tester.enterText(hm, 'Siguiente paso: llamada técnica');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(tester.widget<TextField>(at).controller!.text, 'Siguiente paso: llamada técnica');

    expect(tester.takeException(), isNull);
  });

  testWidgets('sin Firebase: modo local; el lienzo aparece solo en la etapa 5 y no en el pasado', (tester) async {
    tester.view.physicalSize = const Size(1700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final c = ProviderContainer(overrides: [liverhackSeedProvider.overrideWith((ref) async => fixtureSeed())]);
    addTearDown(c.dispose);
    c.read(currentRoleProvider.notifier).select(UserRole.hiringManager);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: Scaffold(body: ToastHost(child: CandidatosPage()))),
    ));
    await settle(tester);
    final n = c.read(candidatosProvider.notifier);

    // VAC-101 está en Selección: la ficha trae el lienzo en modo local.
    n.toggleOpen(1);
    await settle(tester);
    expect(find.text('Lienzo colaborativo de la entrevista'), findsOneWidget);
    expect(find.text('⚪ Modo local (Firebase no configurado)'), findsOneWidget);

    await tester.ensureVisible(find.byType(CollaborativeCanvas));
    await tester.enterText(
      find.descendant(of: find.byType(CollaborativeCanvas), matching: find.byType(TextField)),
      'Muy buena entrevista',
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.read(notasEntrevistaProvider(1)).value, 'Muy buena entrevista');

    // En la instantánea de Selección (tras el cierre) la ficha es de solo lectura: sin lienzo.
    n.seleccionarFinalista(1, 'La mejor combinación de experiencia y presupuesto.');
    await settle(tester);
    expect(find.text('Lienzo colaborativo de la entrevista'), findsNothing); // etapa 6
    n.verEtapa(5); // equivale a tocar "Selección" en el flujo
    await settle(tester);
    n.toggleOpen(1);
    await settle(tester);
    expect(find.textContaining('Solo lectura · instantánea'), findsOneWidget);
    expect(find.text('Lienzo colaborativo de la entrevista'), findsNothing);

    expect(tester.takeException(), isNull);
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
