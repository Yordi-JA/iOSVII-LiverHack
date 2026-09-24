import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

const seedAssetPath = 'assets/seed_data_liverhack.json';

/// Lee y parsea el seed del módulo de Candidatos.
Future<LiverhackSeed> loadLiverhackSeed([AssetBundle? bundle]) async {
  final raw = await (bundle ?? rootBundle).loadString(seedAssetPath);
  return LiverhackSeed.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// Cambios del usuario sobre el seed, guardados en `shared_preferences`
/// bajo la clave `lh26`: rol, vacante activa y, por candidato, solo los
/// campos que difieren del seed.
class LiverhackStore {
  const LiverhackStore(this._prefs);

  static const key = 'lh26';

  final SharedPreferences? _prefs;

  Map<String, dynamic> _read() {
    try {
      final raw = _prefs?.getString(key);
      return raw == null ? {} : (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return {};
    }
  }

  void _write(Map<String, dynamic> data) {
    try {
      _prefs?.setString(key, jsonEncode(data));
    } catch (_) {
      // Sin persistencia la demo sigue funcionando desde el seed.
    }
  }

  String? get role => _read()['role'] as String?;

  set role(String? value) => _write({..._read(), 'role': value});

  /// Hay almacenamiento real (en los tests no lo hay).
  bool get persistente => _prefs != null;

  /// El usuario ya vio o saltó el tutorial de bienvenida.
  bool get tutorialVisto => _read()['tutorial'] == true;

  set tutorialVisto(bool value) => _write({..._read(), 'tutorial': value});

  String? get vacanteId => _read()['vacante'] as String?;

  set vacanteId(String? value) => _write({..._read(), 'vacante': value});

  /// Aplica los cambios guardados sobre los candidatos del seed.
  List<Candidato> applyOverrides(List<Candidato> seed) {
    final overrides = ((_read()['candidatos'] as Map?) ?? const {}).cast<String, dynamic>();
    if (overrides.isEmpty) return seed;
    return [
      for (final c in seed)
        if (overrides['${c.id}'] case final Map o)
          c.copyWith(
            status: o.containsKey('status_proceso') ? StatusProceso.fromJson(o['status_proceso'] as String?) : null,
            statusJustificacion: o['status_justificacion'] as String?,
            enviadoHm: o['enviado_hm'] as bool?,
            diasEsperandoHm: o.containsKey('dias_esperando_hm')
                ? (o['dias_esperando_hm'] as num?)?.toInt()
                : c.diasEsperandoHm,
            importado: o['importado'] as bool?,
          )
        else
          c,
    ];
  }

  /// Guarda solo los campos de [current] que difieren de [seed].
  void saveCandidatos(List<Candidato> seed, List<Candidato> current) {
    final byId = {for (final c in seed) c.id: c};
    final diffs = <String, dynamic>{};
    for (final c in current) {
      final s = byId[c.id];
      if (s == null) continue;
      final d = <String, dynamic>{
        if (c.status != s.status) 'status_proceso': c.status.json,
        if (c.statusJustificacion != s.statusJustificacion) 'status_justificacion': c.statusJustificacion,
        if (c.enviadoHm != s.enviadoHm) 'enviado_hm': c.enviadoHm,
        if (c.diasEsperandoHm != s.diasEsperandoHm) 'dias_esperando_hm': c.diasEsperandoHm,
        if (c.importado != s.importado) 'importado': c.importado,
      };
      if (d.isNotEmpty) diffs['${c.id}'] = d;
    }
    _write({..._read(), 'candidatos': diffs});
  }

  /// Bitácora de acciones de negocio (histórico del proceso).
  List<Evento> get eventos {
    try {
      return [
        for (final e in (_read()['eventos'] as List?) ?? const [])
          Evento.fromJson((e as Map).cast<String, dynamic>()),
      ];
    } catch (_) {
      return const [];
    }
  }

  void saveEventos(List<Evento> eventos) => _write({
    ..._read(),
    'eventos': [for (final e in eventos) e.toJson()],
  });

  /// Aplica la etapa y el perfil negociado de cada vacante sobre el seed.
  List<Vacante> applyVacanteOverrides(List<Vacante> seed) {
    final overrides = ((_read()['vacantes'] as Map?) ?? const {}).cast<String, dynamic>();
    if (overrides.isEmpty) return seed;
    return [
      for (final v in seed)
        if (overrides[v.id] case final Map o)
          v.copyWith(
            etapaActual: (o['etapa_actual'] as num?)?.toInt(),
            diasEnEtapa: (o['dias_en_etapa'] as num?)?.toInt(),
            presupuestoMax: (o['presupuesto_max'] as num?)?.toInt(),
            perfilNoNegociables: (o['perfil_no_negociables'] as List?)?.map((e) => '$e').toList(),
            ofertaAprobada: o['oferta_aprobada'] as bool?,
          )
        else
          v,
    ];
  }

  /// Guarda, por vacante, solo los campos que difieren del seed: etapa,
  /// días en etapa, presupuesto, no negociables y aprobación de la oferta.
  void saveVacantes(List<Vacante> seed, List<Vacante> current) {
    final byId = {for (final v in seed) v.id: v};
    final diffs = <String, dynamic>{};
    for (final v in current) {
      final s = byId[v.id];
      if (s == null) continue;
      final d = <String, dynamic>{
        if (v.etapaActual != s.etapaActual) 'etapa_actual': v.etapaActual,
        if (v.diasEnEtapa != s.diasEnEtapa) 'dias_en_etapa': v.diasEnEtapa,
        if (v.presupuestoMax != s.presupuestoMax) 'presupuesto_max': v.presupuestoMax,
        if (!_sameList(v.perfilNoNegociables, s.perfilNoNegociables))
          'perfil_no_negociables': v.perfilNoNegociables,
        if (v.ofertaAprobada != s.ofertaAprobada) 'oferta_aprobada': v.ofertaAprobada,
      };
      if (d.isNotEmpty) diffs[v.id] = d;
    }
    _write({..._read(), 'vacantes': diffs});
  }
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
