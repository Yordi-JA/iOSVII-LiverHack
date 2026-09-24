import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puerta_liverpool/backend/candidatos/models.dart';
import 'package:puerta_liverpool/backend/candidatos/rules.dart';
import 'package:puerta_liverpool/backend/candidatos/seed_repository.dart';
import 'package:puerta_liverpool/backend/models/person.dart';
import 'package:puerta_liverpool/backend/providers.dart';
import 'package:puerta_liverpool/frontend/core/widgets/toast_host.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_controller.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/candidatos_page.dart';
import 'package:puerta_liverpool/frontend/features/candidatos/widgets/candidate_table.dart';
import 'package:puerta_liverpool/frontend/features/session/role_provider.dart';
import 'package:puerta_liverpool/frontend/features/workspace/workspace_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'candidatos_fixture.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('cada acción de negocio queda en la bitácora de su etapa y persiste', () async {
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

    c.read(currentRoleProvider.notifier).select(UserRole.hrbp);
    n.avanzarEtapaVacante('VAC-103', 2);
    c.read(currentRoleProvider.notifier).select(UserRole.hiringManager);
    n.decidir(1, StatusProceso.finalista, 'Cumple todos los no negociables.');
    n.seleccionarFinalista(1, 'La mejor combinación de experiencia y presupuesto.');

    var s = c.read(candidatosProvider).value!;
    final requisicion = s.eventosDe('VAC-103', 1).single;
    expect(requisicion.tipo, TipoEvento.aprobacion);
    expect(requisicion.actor, 'HRBP');
    expect(requisicion.texto, contains(r'$950k'));
    final seleccion = s.eventosDe('VAC-101', 5);
    expect(seleccion.map((e) => e.tipo), [TipoEvento.oferta, TipoEvento.decision]); // más reciente primero
    expect(seleccion.last.texto, contains('Ana López es finalista'));
    expect(seleccion.first.texto, contains('4 candidatos descartados'));

    n.aprobarOferta('VAC-101');
    s = c.read(candidatosProvider).value!;
    expect(s.eventosDe('VAC-101', 6).single.tipo, TipoEvento.contratacion);

    // "Recarga".
    final r = await app().read(candidatosProvider.future);
    expect(r.eventos, hasLength(4));
    expect(r.eventosDe('VAC-101', 5).last.actor, 'Hiring manager');
  });

  test('las instantáneas muestran el presupuesto previo a la negociación y solo se visitan etapas pasadas', () async {
    final c = ProviderContainer(overrides: [liverhackSeedProvider.overrideWith((ref) async => fixtureSeed())]);
    addTearDown(c.dispose);
    await c.read(candidatosProvider.future);
    final n = c.read(candidatosProvider.notifier);
    c.read(currentRoleProvider.notifier).select(UserRole.hiringManager);
    n.selectVacante('VAC-104');
    n.editarPerfilVacante('VAC-104', presupuestoMax: 750000, noNegociables: ['Última milla', 'Inglés B2']);
    n.avanzarEtapaVacante('VAC-104', 3);

    CandidatosState s() => c.read(candidatosProvider).value!;
    expect(s().vacanteEnEtapa(1).presupuestoMax, 700000);
    expect(s().vacanteEnEtapa(1).perfilNoNegociables, ['Última milla', 'SAP EWM']);
    expect(s().vacanteEnEtapa(2).presupuestoMax, 750000);

    n.verEtapa(3); // etapa actual: vuelve al presente
    expect(s().etapaVista, isNull);
    n.verEtapa(5); // etapa futura: no se puede
    expect(s().etapaVista, isNull);
    n.verEtapa(1);
    expect(s().viendoPasado, isTrue);
    n.verEtapa(1); // tocar la misma etapa regresa
    expect(s().etapaVista, isNull);
  });

  testWidgets('Máquina del tiempo: la pantalla se ve como en la etapa pasada, en solo lectura', (tester) async {
    tester.view.physicalSize = const Size(1700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final c = ProviderContainer(overrides: [liverhackSeedProvider.overrideWith((ref) async => fixtureSeed())]);
    addTearDown(c.dispose);
    c.read(currentRoleProvider.notifier).select(UserRole.hiringManager);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        home: Scaffold(body: WorkspaceSnackHost(child: ToastHost(child: CandidatosPage()))),
      ),
    ));
    await settle(tester);
    final n = c.read(candidatosProvider.notifier);

    // Etapa 2: la tarjeta de Alineación en solo lectura y sin candidatos.
    // El encabezado no lleva textos de ayuda bajo el flujo.
    expect(find.text('Toca una etapa completada para ver cómo estaba el proceso'), findsNothing);
    await tester.tap(find.text('Alineación'));
    await settle(tester);
    expect(find.text('Volver al presente'), findsNothing);
    expect(find.textContaining('instantánea histórica'), findsNothing);
    expect(find.text('Toca la etapa actual para regresar al presente'), findsNothing);
    expect(find.text('Alineación del perfil'), findsOneWidget);
    expect(find.text('Completada'), findsOneWidget);
    expect(find.text('Aprobar Alineación'), findsNothing);
    expect(find.byType(CandidateListPanel), findsNothing);
    expect(find.text('Se completó antes de registrar acciones en Puerta Liverpool.'), findsOneWidget);

    // Desde el pasado no se puede escribir.
    n.decidir(1, StatusProceso.descartado, 'Intento de cambio desde el pasado.');
    expect(c.read(candidatosProvider).value!.candidatos.first.status, StatusProceso.enProceso);
    await settle(tester);
    expect(find.textContaining('Toca la etapa actual'), findsWidgets);

    // Tocar la etapa actual regresa al presente.
    await tester.tap(find.text('Selección').first);
    await settle(tester);
    expect(find.text('Alineación del perfil'), findsNothing);
    expect(find.byType(CandidateListPanel), findsOneWidget);

    // Etapa 4 (como Reclutador): lista sin envíos ni entrevistas, casillas deshabilitadas.
    c.read(currentRoleProvider.notifier).select(UserRole.reclutador);
    await settle(tester);
    await tester.tap(find.text('Atracción'));
    await settle(tester);
    expect(find.text('Solo lectura'), findsOneWidget);
    expect(find.text('Con Hiring manager'), findsNothing); // sin recuadros de conteo
    expect(find.textContaining('Mover seleccionados'), findsNothing);
    expect(tester.widgetList<Checkbox>(find.byType(Checkbox)).every((cb) => cb.onChanged == null), isTrue);
    expect(find.text('Sin entrevistas'), findsNWidgets(5));

    // Tocar la etapa actual regresa al presente.
    await tester.tap(find.text('Selección').first);
    await settle(tester);
    expect(find.text('Solo lectura'), findsNothing);

    // Etapa 5 después del cierre: se deshacen la oferta y los descartes automáticos.
    c.read(currentRoleProvider.notifier).select(UserRole.hiringManager);
    n.seleccionarFinalista(1, 'La mejor combinación de experiencia y presupuesto.');
    await settle(tester);
    await tester.tap(find.text('Selección').first);
    await settle(tester);
    expect(c.read(candidatosProvider).value!.viendoPasado, isTrue);
    expect(find.text('En oferta'), findsNothing);
    expect(find.text('Descartado'), findsNothing);
    expect(find.text('Finalista'), findsOneWidget);
    n.toggleOpen(1);
    await settle(tester);
    expect(find.text('Solo lectura · instantánea de la Etapa 5 (Selección)'), findsOneWidget);
    expect(find.text('Seleccionar para Oferta'), findsNothing);
    expect(find.text('Chat'), findsNothing);
    expect(find.textContaining('fue seleccionado para la oferta final'), findsOneWidget); // cierre de la etapa

    expect(tester.takeException(), isNull);
  });

  for (final ancho in [1700.0, 900.0]) {
    testWidgets('Requisición como resumen ejecutivo (ancho $ancho) y sin contador de días en el pasado', (tester) async {
      tester.view.physicalSize = Size(ancho, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final c = ProviderContainer(overrides: [liverhackSeedProvider.overrideWith((ref) async => fixtureSeed())]);
      addTearDown(c.dispose);
      c.read(currentRoleProvider.notifier).select(UserRole.hrbp);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: Scaffold(body: ToastHost(child: CandidatosPage()))),
      ));
      await settle(tester);
      final n = c.read(candidatosProvider.notifier);

      // Presente (HRBP en VAC-103, etapa 1): cifras grandes y directorio sin cajas.
      n.selectVacante('VAC-103');
      await settle(tester);
      expect(find.text('PRESUPUESTO MÁXIMO ANUAL'), findsOneWidget);
      expect(find.text('SLA TOTAL ESTIMADO'), findsOneWidget);
      // Complejidad como cifra en texto (no como cápsula), y sin título de sección.
      expect(find.text('COMPLEJIDAD'), findsOneWidget);
      expect(find.text('Alto'), findsWidgets);
      expect(find.textContaining('Requisición: valida'), findsNothing);
      expect(find.text('Solicitud de la posición y presupuesto aprobados por el HRBP.'), findsNothing);
      expect(find.byIcon(Icons.business), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsNWidgets(2));
      expect(find.textContaining('Requisición: día'), findsNothing); // sin contador de días en el encabezado

      // Pasado (VAC-104 aprobada; se ve la etapa 1): sin la pill "día X de Y" del presente.
      c.read(currentRoleProvider.notifier).select(UserRole.hiringManager);
      n.selectVacante('VAC-104');
      n.avanzarEtapaVacante('VAC-104', 3);
      await settle(tester);
      expect(find.textContaining('Búsqueda: día'), findsOneWidget); // solo la tarjeta de espera
      n.verEtapa(1);
      await settle(tester);
      expect(find.text('PRESUPUESTO MÁXIMO ANUAL'), findsOneWidget);
      expect(find.textContaining(': día '), findsNothing);
      expect(find.text('Etapa completada'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('El flujo muestra el tiempo del proceso y no los días bajo cada etapa', (tester) async {
    tester.view.physicalSize = const Size(1700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final c = ProviderContainer(overrides: [liverhackSeedProvider.overrideWith((ref) async => fixtureSeed())]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: Scaffold(body: ToastHost(child: CandidatosPage()))),
    ));
    await settle(tester);

    final state = c.read(candidatosProvider).value!;
    final v = state.vacante;
    final dias = diasDelProceso(v, state.sla);
    final estimados = diasEstimadosProceso(v, state.sla);
    expect(find.text('$dias días en proceso'), findsOneWidget);
    expect(find.text('Faltan ${estimados - dias} de $estimados días estimados'), findsOneWidget);
    for (var i = 0; i < stages.length; i++) {
      final d = stageDays(v, i, state.sla);
      expect(find.text('$d ${d == 1 ? 'día' : 'días'}'), findsNothing);
    }

    // En la máquina del tiempo no se muestra.
    c.read(candidatosProvider.notifier).verEtapa(1);
    await settle(tester);
    expect(find.textContaining('en proceso'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Pasado con RBAC: "Tarea completada" sin permisos y el menú sigue la etapa real', (tester) async {
    tester.view.physicalSize = const Size(1700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final c = ProviderContainer(overrides: [liverhackSeedProvider.overrideWith((ref) async => fixtureSeed())]);
    addTearDown(c.dispose);
    c.read(currentRoleProvider.notifier).select(UserRole.reclutador);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: Scaffold(body: ToastHost(child: CandidatosPage()))),
    ));
    await settle(tester);
    final n = c.read(candidatosProvider.notifier);
    const tareaCompletada = 'Esta etapa fue gestionada y aprobada por el HRBP y el Hiring Manager.';

    // Reclutador en la Requisición de VAC-101 (etapa 5): sin presupuesto ni SLA.
    n.verEtapa(1);
    await settle(tester);
    expect(find.text('Tarea completada'), findsOneWidget);
    expect(find.text(tareaCompletada), findsOneWidget);
    expect(find.text('PRESUPUESTO MÁXIMO ANUAL'), findsNothing);
    expect(find.text('SLA TOTAL ESTIMADO'), findsNothing);

    // El menú depende de la etapa real (5), no de la que se ve (1).
    expect(find.byTooltip('Plegar menú'), findsOneWidget);
    expect(find.text('Comparativa (0)'), findsOneWidget);

    // Reclutador sí ve la Alineación.
    n.verEtapa(2);
    await settle(tester);
    expect(find.text('Tarea completada'), findsNothing);
    expect(find.text('Alineación del perfil'), findsOneWidget);

    // HRBP: ve la Requisición, pero no la Alineación.
    c.read(currentRoleProvider.notifier).select(UserRole.hrbp);
    await settle(tester);
    expect(find.text('Tarea completada'), findsOneWidget);
    expect(find.text('Alineación del perfil'), findsNothing);
    n.verEtapa(1);
    await settle(tester);
    expect(find.text('Tarea completada'), findsNothing);
    expect(find.text('PRESUPUESTO MÁXIMO ANUAL'), findsOneWidget);

    // Tocar una opción del menú desde el pasado regresa al presente.
    await tester.tap(find.text('Candidatos').last);
    await settle(tester);
    expect(c.read(candidatosProvider).value!.viendoPasado, isFalse);
    expect(find.byType(CandidateListPanel), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
