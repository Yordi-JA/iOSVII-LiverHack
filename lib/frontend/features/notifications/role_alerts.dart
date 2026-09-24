import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../backend/candidatos/models.dart';
import '../../../backend/candidatos/rules.dart';
import '../../../backend/models/person.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../candidatos/candidatos_controller.dart';
import '../session/role_provider.dart';
import '../workspace/workspace_style.dart';

/// Notificación dirigida al rol activo. Al tocarla se abre la vacante o la
/// ficha del candidato relacionado.
class RoleAlert {
  const RoleAlert({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    this.body,
    this.vacanteId,
    this.candidato,
  });

  /// Cambia cuando cambia el contenido, para volver a marcarla como nueva.
  final String id;
  final IconData icon;
  final Color color;
  final String title;
  final String? body;
  final String? vacanteId;
  final Candidato? candidato;
}

/// Notificaciones según el rol (RBAC), calculadas con el estado actual.
final roleAlertsProvider = Provider<List<RoleAlert>>((ref) {
  final role = ref.watch(currentRoleProvider);
  final s = ref.watch(candidatosProvider).value;
  if (s == null) return const [];

  final enAlerta = s.alertas;
  final n = enAlerta.length;
  final plural = n == 1 ? '' : 's';

  return switch (role) {
    UserRole.hiringManager => [
      if (n > 0)
        RoleAlert(
          id: 'hm-sla-$n',
          icon: Icons.schedule,
          color: AppColors.danger,
          title: '$n candidato$plural ${n == 1 ? 'espera' : 'esperan'} tu feedback hace más de 3 días (SLA en riesgo).',
          body: enAlerta.take(3).map((c) => '${c.nombre} (${c.diasEsperandoHm} días)').join(', '),
          candidato: enAlerta.first,
        ),
      for (final v in s.vacantes.where((v) => v.etapaActual == 2))
        RoleAlert(
          id: 'hm-align-${v.id}',
          icon: Icons.handshake_outlined,
          color: AppColors.flowCurrent,
          title: 'Alineación pendiente: ${v.titulo}.',
          body: 'Lleva ${v.diasEnEtapa} días; el SLA permite ${stageDays(v, 1, s.sla)}.',
          vacanteId: v.id,
        ),
    ],
    UserRole.reclutador => [
      for (final v in s.vacantes.where((v) => v.etapaActual == 3))
        RoleAlert(
          id: 'at-align-${v.id}',
          icon: Icons.task_alt,
          color: AppColors.success,
          title: 'El HM aprobó la alineación.',
          body: '${v.hiringManager} aprobó ${v.titulo}. Importa candidatos desde Aira.',
          vacanteId: v.id,
        ),
      if (s.candidatos.where((c) => c.nombre == 'Carlos Mendoza').firstOrNull case final carlos?)
        RoleAlert(
          id: 'at-drive-carlos',
          icon: Icons.add_to_drive_outlined,
          color: GColors.blue,
          title: 'Carlos Mendoza compartió un archivo en Drive.',
          body: '"Portafolio_Carlos_Mendoza.pdf" · ${s.vacanteDe(carlos).titulo}',
          candidato: carlos,
        ),
      if (n > 0)
        RoleAlert(
          id: 'at-sla-$n',
          icon: Icons.schedule,
          color: AppColors.warning,
          title: '$n candidato$plural ${n == 1 ? 'lleva' : 'llevan'} 3 días o más sin veredicto del HM.',
          body: 'Se envió un recordatorio automático a los Hiring managers.',
          candidato: enAlerta.first,
        ),
    ],
    _ => [
      for (final v in s.vacantes.where((v) => v.etapaActual == 6 && !v.ofertaAprobada))
        if (s.candidatos.where((c) => c.vacanteId == v.id && c.status == StatusProceso.oferta).firstOrNull case final c?)
          RoleAlert(
            id: 'hrbp-oferta-${c.id}',
            icon: Icons.payments_outlined,
            color: AppColors.flowDone,
            title:
                '💰 El HM ha seleccionado a ${c.nombre}. Requiere tu aprobación de paquete de compensación '
                '(Expectativa: ${formatMoneyShort(c.compensacionDeseada)}).',
            body: '${v.titulo} · presupuesto ${formatMoneyShort(v.presupuestoMax)}',
            vacanteId: v.id,
          ),
      for (final v in s.vacantes.where((v) => v.etapaActual <= 2 && excedeTabulador(v)))
        RoleAlert(
          id: 'hrbp-tab-${v.id}-${v.presupuestoMax}',
          icon: Icons.request_quote_outlined,
          color: AppColors.danger,
          title: 'La requisición excede el tabulador, requiere aprobación.',
          body:
              '${v.titulo}: ${formatMoneyShort(v.presupuestoMax)} contra un tope de '
              '${formatMoneyShort(tabuladorReferencia[v.complejidad]!)} (${v.complejidad.toLowerCase()}).',
          vacanteId: v.id,
        ),
      for (final c in s.candidatos.where((c) => c.status == StatusProceso.finalista && !s.vacanteDe(c).ofertaAprobada))
        RoleAlert(
          id: 'hrbp-fin-${c.id}',
          icon: Icons.workspace_premium_outlined,
          color: AppColors.success,
          title: 'Finalista definido: ${c.nombre}.',
          body: '${s.vacanteDe(c).titulo}. Aprueba el paquete de oferta.',
          candidato: c,
        ),
    ],
  };
});

/// Notificaciones ya vistas (se marcan al abrir el menú).
class SeenRoleAlertsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void markSeen(Iterable<String> ids) => state = {...state, ...ids};
}

final seenRoleAlertsProvider = NotifierProvider<SeenRoleAlertsNotifier, Set<String>>(SeenRoleAlertsNotifier.new);

/// Número de notificaciones del rol que aún no se han visto.
final unseenRoleAlertsProvider = Provider<int>((ref) {
  final seen = ref.watch(seenRoleAlertsProvider);
  return ref.watch(roleAlertsProvider).where((a) => !seen.contains(a.id)).length;
});
