import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../backend/candidatos/models.dart';
import '../../../backend/candidatos/rules.dart';
import '../../../backend/candidatos/seed_repository.dart';
import '../../../backend/models/person.dart';
import '../../../backend/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/toast_host.dart';
import '../session/role_provider.dart';
import '../workspace/workspace_style.dart';

/// Vista activa: el dashboard del área (solo Reclutador), la lista de
/// vacantes (el "Home" para cambiar de vacante), la lista de candidatos (o la
/// tarjeta de la etapa) y la comparativa.
enum CandidatosView { dashboard, vacantes, lista, comparativa }

enum CmpMode { tabla, radar }

const defaultVacanteId = 'VAC-101';
const maxPick = 4;

class CandidatosState {
  const CandidatosState({
    required this.seed,
    required this.vacantes,
    required this.todos,
    required this.vacanteId,
    this.view = CandidatosView.lista,
    this.openId,
    this.pick = const [],
    this.cmpMode = CmpMode.tabla,
    this.zoom = const {},
    this.eventos = const [],
    this.etapaVista,
  });

  final LiverhackSeed seed;

  /// Copias del seed con los cambios del usuario (etapa y perfil de cada
  /// vacante; importación, envíos y decisiones de cada candidato).
  final List<Vacante> vacantes;

  /// Todos los candidatos, incluidos los que siguen en el ATS sin importar.
  final List<Candidato> todos;
  final String vacanteId;
  final CandidatosView view;

  /// Candidato con la ficha desplegada.
  final int? openId;

  /// Seleccionados (casillas), en orden de selección.
  final List<int> pick;
  final CmpMode cmpMode;

  /// Zoom del visor de CV por candidato (0.6 a 1.6).
  final Map<int, double> zoom;

  /// Bitácora de acciones de negocio, de la más antigua a la más reciente.
  final List<Evento> eventos;

  /// Etapa pasada (1 a 5) que se está viendo como instantánea; `null` = el presente.
  final int? etapaVista;

  /// La pantalla muestra una etapa pasada de la vacante activa (solo lectura).
  bool get viendoPasado => etapaVista != null && etapaVista! < vacante.etapaActual;

  /// La vacante activa tal como estaba al cerrar la [etapa]: el presupuesto y
  /// los no negociables previos a cualquier negociación posterior.
  Vacante vacanteEnEtapa(int etapa) {
    final v = vacante;
    final negociaciones = eventos
        .where((e) => e.vacanteId == v.id && e.tipo == TipoEvento.negociacion && e.etapa > etapa)
        .toList();
    if (negociaciones.isEmpty) return v.copyWith(etapaActual: etapa);
    final antes = negociaciones.first.datos;
    return v.copyWith(
      etapaActual: etapa,
      presupuestoMax: (antes['presupuesto_antes'] as num?)?.toInt(),
      perfilNoNegociables: (antes['no_negociables_antes'] as List?)?.map((e) => '$e').toList(),
    );
  }

  /// Candidatos de la vacante activa tal como estaban al cerrar la [etapa]
  /// (4 o 5), sin nada de lo que pasó después:
  /// - Atracción: nadie enviado al HM todavía, sin entrevistas ni decisiones.
  /// - Selección: se deshace el cierre (el de Oferta vuelve a finalista y los
  ///   descartados automáticamente vuelven a estar en proceso).
  List<Candidato> candidatosEnEtapa(int etapa, UserRole role) {
    final lista = [
      for (final c in candidatos.where((c) => c.vacanteId == vacanteId))
        if (etapa <= 4)
          c.copyWith(
            status: StatusProceso.enProceso,
            statusJustificacion: '',
            enviadoHm: false,
            diasEsperandoHm: null,
            entrevistas: const [],
          )
        else if (c.status == StatusProceso.oferta)
          c.copyWith(status: StatusProceso.finalista)
        else if (c.status == StatusProceso.descartado && c.statusJustificacion.startsWith('Descarte automático'))
          c.copyWith(status: StatusProceso.enProceso, statusJustificacion: '')
        else
          c,
    ];
    return lista.where((c) => candidatoVisible(c, role)).toList()
      ..sort((a, b) => b.assessFirst.compatibilidad.compareTo(a.assessFirst.compatibilidad));
  }

  /// Eventos de [vacanteId] en la [etapa], del más reciente al más antiguo.
  List<Evento> eventosDe(String vacanteId, int etapa) =>
      eventos.where((e) => e.vacanteId == vacanteId && e.etapa == etapa).toList().reversed.toList();

  SlaConfig get sla => seed.sla;

  /// Candidatos ya importados a la plataforma: los únicos que ve la UI.
  List<Candidato> get candidatos => todos.where((c) => c.importado).toList();

  /// Candidatos que siguen en el ATS (Aira) para [vacanteId].
  List<Candidato> enAts(String vacanteId) => todos.where((c) => c.vacanteId == vacanteId && !c.importado).toList();

  Vacante get vacante => vacantes.firstWhere((v) => v.id == vacanteId, orElse: () => vacantes.first);

  Vacante vacanteDe(Candidato c) => vacantes.firstWhere((v) => v.id == c.vacanteId, orElse: () => vacante);

  List<Candidato> candidatosDe(String vacanteId, UserRole role) =>
      candidatos.where((c) => c.vacanteId == vacanteId && candidatoVisible(c, role)).toList();

  /// Candidatos de la vacante activa visibles para el rol, por compatibilidad descendente.
  List<Candidato> visibles(UserRole role) =>
      candidatosDe(vacanteId, role)
        ..sort((a, b) => b.assessFirst.compatibilidad.compareTo(a.assessFirst.compatibilidad));

  /// El HM ve las vacantes con candidatos enviados y las que esperan su
  /// aprobación de alineación (etapa 2).
  List<Vacante> vacantesVisibles(UserRole role) => isHm(role)
      ? vacantes
            .where((v) => v.etapaActual == 2 || candidatos.any((c) => c.vacanteId == v.id && c.enviadoHm))
            .toList()
      : vacantes;

  List<Candidato> alertasDe(String vacanteId) =>
      candidatos.where((c) => c.vacanteId == vacanteId && enAlerta(c, sla)).toList();

  /// Candidatos en alerta en todas las vacantes, por días de espera descendente.
  List<Candidato> get alertas =>
      candidatos.where((c) => enAlerta(c, sla)).toList()
        ..sort((a, b) => (b.diasEsperandoHm ?? 0).compareTo(a.diasEsperandoHm ?? 0));

  List<Candidato> get picked => [for (final id in pick) ...candidatos.where((c) => c.id == id)];

  /// Seleccionados que Reclutamiento todavía puede mover a entrevista con el HM.
  List<Candidato> get movibles =>
      picked.where((c) => !c.enviadoHm && c.status == StatusProceso.enProceso).toList();

  double zoomOf(int id) => zoom[id] ?? 1;

  /// Candidato de la oferta final de la vacante: el que el HM movió a
  /// Oferta o, en vacantes que ya llegaron a Oferta desde el seed, su finalista.
  Candidato? ofertaDe(String vacanteId) {
    final deVacante = candidatos.where((c) => c.vacanteId == vacanteId);
    final enOferta = deVacante.where((c) => c.status == StatusProceso.oferta).firstOrNull;
    if (enOferta != null) return enOferta;
    final v = vacantes.where((v) => v.id == vacanteId).firstOrNull;
    return v != null && v.etapaActual == 6
        ? deVacante.where((c) => c.status == StatusProceso.finalista).firstOrNull
        : null;
  }

  CandidatosState copyWith({
    List<Vacante>? vacantes,
    List<Candidato>? todos,
    String? vacanteId,
    CandidatosView? view,
    Object? openId = _unset,
    List<int>? pick,
    CmpMode? cmpMode,
    Map<int, double>? zoom,
    List<Evento>? eventos,
    Object? etapaVista = _unset,
  }) => CandidatosState(
    seed: seed,
    vacantes: vacantes ?? this.vacantes,
    todos: todos ?? this.todos,
    vacanteId: vacanteId ?? this.vacanteId,
    view: view ?? this.view,
    openId: identical(openId, _unset) ? this.openId : openId as int?,
    pick: pick ?? this.pick,
    cmpMode: cmpMode ?? this.cmpMode,
    zoom: zoom ?? this.zoom,
    eventos: eventos ?? this.eventos,
    etapaVista: identical(etapaVista, _unset) ? this.etapaVista : etapaVista as int?,
  );

  static const _unset = Object();
}

/// Seed del módulo. Los tests lo sobrescriben con datos propios.
final liverhackSeedProvider = FutureProvider<LiverhackSeed>((ref) => loadLiverhackSeed());

class CandidatosNotifier extends AsyncNotifier<CandidatosState> {
  LiverhackStore get _store => ref.read(liverhackStoreProvider);

  /// Tiempo que simula la consulta al ATS. Los tests lo reducen.
  static var atsDelay = const Duration(seconds: 1);

  @override
  Future<CandidatosState> build() async {
    ref.listen(currentRoleProvider, (prev, next) {
      if (prev != null && prev != next) _onRoleChanged(next);
    });

    final seed = await ref.watch(liverhackSeedProvider.future);
    final saved = _store.vacanteId;
    final ids = seed.vacantes.map((v) => v.id).toSet();
    final vacanteId = ids.contains(saved)
        ? saved!
        : ids.contains(defaultVacanteId)
        ? defaultVacanteId
        : seed.vacantes.first.id;
    return CandidatosState(
      seed: seed,
      vacantes: _store.applyVacanteOverrides(seed.vacantes),
      todos: _store.applyOverrides(seed.candidatos),
      vacanteId: vacanteId,
      eventos: _store.eventos,
    );
  }

  void _update(CandidatosState Function(CandidatosState s) fn) {
    final s = state.value;
    if (s != null) state = AsyncData(fn(s));
  }

  void _toast(String message) => ref.read(toastProvider.notifier).show(message);

  void _onRoleChanged(UserRole role) {
    _update(
      (s) => s.copyWith(
        pick: const [],
        openId: null,
        view: switch (s.view) {
          CandidatosView.comparativa when !veComparativa(role, s.vacante.etapaActual) => CandidatosView.lista,
          CandidatosView.dashboard when !veDashboard(role) => CandidatosView.vacantes,
          _ => null,
        },
      ),
    );
  }

  /// Viaja a la instantánea de una etapa pasada. Tocar la misma etapa, la
  /// actual o una futura (o pasar `null`) vuelve al presente.
  void verEtapa(int? etapa) => _update((s) {
    final pasada = etapa != null && etapa < s.vacante.etapaActual && etapa != s.etapaVista;
    return s.copyWith(etapaVista: pasada ? etapa : null, openId: null, pick: const []);
  });

  /// Mientras se ve el pasado no se permite ninguna escritura: avisa y devuelve `true`.
  bool _bloqueadoPorPasado() {
    if (state.value?.viendoPasado != true) return false;
    _toast('Estás viendo una etapa pasada. **Toca la etapa actual** en el flujo para hacer cambios.');
    return true;
  }

  void selectVacante(String id) {
    _update(
      (s) => s.copyWith(vacanteId: id, pick: const [], openId: null, view: CandidatosView.lista, etapaVista: null),
    );
    _store.vacanteId = id;
  }

  void toggleOpen(int id) => _update((s) => s.copyWith(openId: s.openId == id ? null : id));

  void togglePick(int id) {
    final s = state.value;
    if (s == null || _bloqueadoPorPasado()) return;
    if (s.pick.contains(id)) {
      _update((s) => s.copyWith(pick: s.pick.where((e) => e != id).toList()));
    } else if (s.pick.length >= maxPick) {
      _toast('Puedes comparar hasta $maxPick candidatos a la vez.');
    } else {
      _update((s) => s.copyWith(pick: [...s.pick, id]));
    }
  }

  void setView(CandidatosView view) => _update((s) => s.copyWith(view: view));

  void setCmpMode(CmpMode mode) => _update((s) => s.copyWith(cmpMode: mode));

  void zoom(int id, double delta) => _update((s) {
    final next = ((s.zoomOf(id) + delta) * 10).round() / 10;
    return s.copyWith(zoom: {...s.zoom, id: next.clamp(0.6, 1.6)});
  });

  /// Aplica [fn] a los candidatos [ids] y persiste.
  void _mutate(Set<int> ids, Candidato Function(Candidato c) fn) {
    _update((s) => s.copyWith(todos: [for (final c in s.todos) ids.contains(c.id) ? fn(c) : c]));
    final s = state.value;
    if (s != null) _store.saveCandidatos(s.seed.candidatos, s.todos);
  }

  /// Aplica [fn] a la vacante [vacanteId] y persiste.
  void _mutateVacante(String vacanteId, Vacante Function(Vacante v) fn) {
    _update((s) => s.copyWith(vacantes: [for (final v in s.vacantes) v.id == vacanteId ? fn(v) : v]));
    final s = state.value;
    if (s != null) _store.saveVacantes(s.seed.vacantes, s.vacantes);
  }

  /// Registra una acción en la bitácora de la vacante, en la etapa en que
  /// ocurrió (por defecto, la etapa actual), y la persiste.
  void _registrar(String vacanteId, TipoEvento tipo, String texto, {int? etapa, Map<String, Object?> datos = const {}}) {
    final s = state.value;
    final v = s?.vacantes.where((v) => v.id == vacanteId).firstOrNull;
    if (s == null || v == null) return;
    final evento = Evento(
      vacanteId: vacanteId,
      etapa: etapa ?? v.etapaActual,
      tipo: tipo,
      fecha: DateTime.now(),
      actor: ref.read(currentRoleProvider).label,
      texto: texto,
      datos: datos,
    );
    _update((s) => s.copyWith(eventos: [...s.eventos, evento]));
    _store.saveEventos(state.value!.eventos);
  }

  /// Sube la vacante un paso si está en [desde]. Devuelve si avanzó.
  bool _avanzarSiEsta(String vacanteId, int desde) {
    final v = state.value?.vacantes.where((v) => v.id == vacanteId).firstOrNull;
    if (v == null || v.etapaActual != desde || desde >= stages.length) return false;
    _mutateVacante(vacanteId, (v) => v.copyWith(etapaActual: desde + 1, diasEnEtapa: 0));
    return true;
  }

  void enviarAHm(int id) => moverAEntrevistaHm([id]);

  /// Etapa 4 (Atracción): Reclutamiento mueve a los seleccionados a
  /// entrevista con el HM. Quedan visibles para el HM con el reloj en 0. Con
  /// el primer candidato movido, la vacante pasa a Selección.
  void moverAEntrevistaHm(List<int> ids) {
    final s = state.value;
    if (s == null || _bloqueadoPorPasado()) return;
    final mover = s.candidatos
        .where((c) => ids.contains(c.id) && !c.enviadoHm && c.status == StatusProceso.enProceso)
        .toList();
    if (mover.isEmpty) return;

    _mutate({for (final c in mover) c.id}, (c) => c.copyWith(enviadoHm: true, diasEsperandoHm: 0));
    _update((s) => s.copyWith(pick: s.pick.where((id) => !ids.contains(id)).toList()));
    final v = s.vacanteDe(mover.first);
    _registrar(
      v.id,
      TipoEvento.envio,
      '${mover.map((c) => c.nombre).join(', ')} ${mover.length == 1 ? 'se envió' : 'se enviaron'} a entrevista con ${v.hiringManager}.',
    );
    final avanzo = _avanzarSiEsta(v.id, 4);

    final quien = mover.length == 1 ? mover.first.nombre : '${mover.length} candidatos';
    _toast(
      '$quien ${mover.length == 1 ? 'se envió' : 'se enviaron'} a **${v.hiringManager}**. '
      '${avanzo ? 'La vacante pasa a Selección y arranca' : 'Arranca'} el reloj de 3 días para su veredicto.',
    );
  }

  void decidir(int id, StatusProceso status, String justificacion) {
    final s = state.value;
    if (s == null || _bloqueadoPorPasado()) return;
    final c = s.candidatos.firstWhere((c) => c.id == id);
    _mutate({id}, (c) => c.copyWith(status: status, statusJustificacion: justificacion.trim(), diasEsperandoHm: null));
    _registrar(
      c.vacanteId,
      TipoEvento.decision,
      '${c.nombre} ${status == StatusProceso.descartado ? 'fue descartado' : 'es finalista'}: "${justificacion.trim()}"',
    );
    if (status == StatusProceso.descartado) {
      // Regla de negocio: todo descarte dispara el correo de retroalimentación.
      ref
          .read(workspaceSnackProvider.notifier)
          .show('Candidato descartado. Correo automático de retroalimentación enviado vía Gmail.', icon: Icons.mail_outline);
    } else {
      _toast('**${c.nombre}** es finalista. Siguiente paso: selecciónalo para la oferta final desde su ficha.');
    }
  }

  /// Etapa 5 → 6 (HM): el ganador pasa a Oferta y el resto de los candidatos
  /// activos de la vacante se descartan automáticamente (cierre del embudo).
  /// Devuelve cuántos candidatos se descartaron.
  int seleccionarFinalista(int idGanador, String justificacion) {
    final s = state.value;
    final ganador = s?.candidatos.where((c) => c.id == idGanador).firstOrNull;
    if (s == null || ganador == null || _bloqueadoPorPasado()) return 0;
    final v = s.vacanteDe(ganador);
    final descartar = [
      for (final c in s.candidatos)
        if (c.vacanteId == v.id &&
            c.id != idGanador &&
            (c.status == StatusProceso.enProceso || c.status == StatusProceso.finalista))
          c.id,
    ];

    _mutate(
      {idGanador},
      (c) => c.copyWith(status: StatusProceso.oferta, statusJustificacion: justificacion.trim(), diasEsperandoHm: null),
    );
    _mutate(
      descartar.toSet(),
      (c) => c.copyWith(
        status: StatusProceso.descartado,
        statusJustificacion: 'Descarte automático: ${v.hiringManager} seleccionó a ${ganador.nombre} para la oferta final.',
        diasEsperandoHm: null,
      ),
    );
    final n = descartar.length;
    _registrar(
      v.id,
      TipoEvento.oferta,
      '${ganador.nombre} fue seleccionado para la oferta final: "${justificacion.trim()}". '
      '${n == 0 ? 'No había otros candidatos activos.' : '$n candidato${n == 1 ? '' : 's'} descartado${n == 1 ? '' : 's'} con correo automático.'}',
    );
    if (v.etapaActual < stages.length) {
      _mutateVacante(v.id, (v) => v.copyWith(etapaActual: stages.length, diasEnEtapa: 0));
    }
    _update((s) => s.copyWith(pick: const []));

    ref
        .read(workspaceSnackProvider.notifier)
        .show(
          n == 0
              ? '¡Candidato movido a Oferta!'
              : '¡Candidato movido a Oferta! Se ${n == 1 ? 'envió 1 correo automático' : 'enviaron $n correos automáticos'} '
                    'de agradecimiento a los descartados.',
          icon: Icons.mark_email_read_outlined,
        );
    return n;
  }

  /// Etapa 6 (HRBP): aprueba el paquete de compensación y cierra el flujo.
  void aprobarOferta(String vacanteId) {
    final s = state.value;
    final v = s?.vacantes.where((v) => v.id == vacanteId).firstOrNull;
    if (s == null || v == null || v.ofertaAprobada || _bloqueadoPorPasado()) return;
    final c = s.ofertaDe(vacanteId);
    _mutateVacante(vacanteId, (v) => v.copyWith(ofertaAprobada: true));
    _registrar(
      vacanteId,
      TipoEvento.contratacion,
      'Presupuesto de la oferta aprobado${c == null ? '' : ' para ${c.nombre}'}. Trámites de contratación iniciados.',
    );
    ref
        .read(workspaceSnackProvider.notifier)
        .show(
          'Trámites de contratación iniciados${c == null ? '' : ' para ${c.nombre}'}. Se notificó a ${v.reclutador} y a ${v.hiringManager}.',
          icon: Icons.verified_outlined,
        );
  }

  /// Avanza la vacante a [nuevaEtapa] por una acción de negocio: solo un
  /// paso hacia adelante. Reinicia el conteo de días de la etapa y persiste.
  void avanzarEtapaVacante(String vacanteId, int nuevaEtapa) {
    final v = state.value?.vacantes.where((v) => v.id == vacanteId).firstOrNull;
    if (v == null || nuevaEtapa != v.etapaActual + 1 || _bloqueadoPorPasado()) return;
    _registrar(vacanteId, TipoEvento.aprobacion, switch (nuevaEtapa) {
      2 => 'Posición validada y presupuesto de ${formatMoneyShort(v.presupuestoMax)} aprobado.',
      3 => 'Perfil alineado y aprobado. Arranca el SLA de la búsqueda con ${v.reclutador}.',
      _ => 'La vacante avanzó a ${stages[nuevaEtapa - 1]}.',
    });
    if (!_avanzarSiEsta(vacanteId, v.etapaActual)) return;

    _toast(switch (nuevaEtapa) {
      2 => 'Presupuesto aprobado para **${v.titulo}**. La vacante pasa a Alineación con ${v.hiringManager}.',
      3 => 'Alineación aprobada. **${v.titulo}** pasa a Búsqueda y arranca el SLA de ${v.reclutador}.',
      _ => '**${v.titulo}** avanzó a ${stages[nuevaEtapa - 1]}.',
    });
  }

  /// Etapa 2 (Alineación): el HM negocia el presupuesto y los no negociables.
  void editarPerfilVacante(String vacanteId, {required int presupuestoMax, required List<String> noNegociables}) {
    final v = state.value?.vacantes.where((v) => v.id == vacanteId).firstOrNull;
    if (v == null || _bloqueadoPorPasado()) return;
    final limpios = [for (final n in noNegociables) if (n.trim().isNotEmpty) n.trim()];
    _mutateVacante(vacanteId, (v) => v.copyWith(presupuestoMax: presupuestoMax, perfilNoNegociables: limpios));
    _registrar(
      vacanteId,
      TipoEvento.negociacion,
      'Perfil negociado: presupuesto ${formatMoneyShort(v.presupuestoMax)} → ${formatMoneyShort(presupuestoMax)}; '
      'no negociables: ${limpios.join(', ')}.',
      datos: {
        'presupuesto_antes': v.presupuestoMax,
        'presupuesto': presupuestoMax,
        'no_negociables_antes': v.perfilNoNegociables,
        'no_negociables': limpios,
      },
    );
    _toast('Perfil de **${v.titulo}** actualizado. ${v.reclutador} buscará con los nuevos criterios.');
  }

  /// Etapa 3 (Búsqueda): trae de Aira los candidatos de la vacante. Con los
  /// primeros candidatos en la tabla, la vacante pasa a Atracción.
  /// Devuelve cuántos se importaron.
  Future<int> importarDesdeAts(String vacanteId) async {
    if (_bloqueadoPorPasado()) return 0;
    await Future<void>.delayed(atsDelay);
    final s = state.value;
    if (s == null) return 0;
    final nuevos = s.enAts(vacanteId);
    final v = s.vacantes.firstWhere((v) => v.id == vacanteId);
    if (nuevos.isEmpty) {
      _toast('Aira no tiene candidatos nuevos para **${v.titulo}**.');
      return 0;
    }

    _mutate({for (final c in nuevos) c.id}, (c) => c.copyWith(importado: true));
    _registrar(
      vacanteId,
      TipoEvento.importacion,
      'Se importaron ${nuevos.length} candidatos desde Aira: ${nuevos.map((c) => c.nombre).join(', ')}.',
    );
    final avanzo = _avanzarSiEsta(vacanteId, 3);
    _toast(
      'Se importaron **${nuevos.length} candidatos** desde Aira'
      '${avanzo ? '. La vacante pasa a Atracción.' : '.'}',
    );
    return nuevos.length;
  }

  /// Desde la campana: va a la vacante del candidato y abre su ficha.
  void openFromAlert(Candidato c) {
    _update(
      (s) => s.copyWith(vacanteId: c.vacanteId, view: CandidatosView.lista, openId: c.id, pick: const [], etapaVista: null),
    );
    _store.vacanteId = c.vacanteId;
  }
}

final candidatosProvider = AsyncNotifierProvider<CandidatosNotifier, CandidatosState>(CandidatosNotifier.new);
