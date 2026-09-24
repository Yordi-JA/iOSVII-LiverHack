import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../backend/candidatos/rules.dart';
import '../../../backend/candidatos/seed_repository.dart';
import '../../../backend/models/person.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../dashboard/dashboard_page.dart';
import '../session/role_provider.dart';
import '../tutorial/spotlight.dart';
import 'candidatos_controller.dart';
import 'widgets/candidate_table.dart';
import 'widgets/comparison_view.dart';
import 'widgets/oferta.dart';
import 'widgets/sidebar.dart';
import 'widgets/stage_gate.dart';
import 'widgets/time_machine_view.dart';
import 'widgets/vacantes_view.dart';
import 'widgets/vacancy_header.dart';

/// Módulo de Candidatos: encabezado con selector de vacante, menú lateral
/// plegable y la vista activa (Candidatos o Comparativa).
class CandidatosPage extends ConsumerWidget {
  const CandidatosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    return ref
        .watch(candidatosProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: GlassCard(
              padding: const EdgeInsets.all(28),
              child: SizedBox(
                width: 460,
                child: Text(
                  'No se pudo cargar $seedAssetPath.\n$e',
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          data: (state) => _CandidatosLayout(state: state, role: role),
        );
  }
}

/// Panel lateral a la izquierda, a toda la altura; a la derecha, el
/// encabezado de la vacante y la vista activa, que son lo único que hace scroll.
class _CandidatosLayout extends ConsumerWidget {
  const _CandidatosLayout({required this.state, required this.role});

  final CandidatosState state;
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(candidatosProvider.notifier);
    final etapa = state.vacante.etapaActual;
    final comparativa = veComparativa(role, etapa);
    final view = switch (state.view) {
      CandidatosView.comparativa when !comparativa => CandidatosView.lista,
      CandidatosView.dashboard when !veDashboard(role) => CandidatosView.vacantes,
      final v => v,
    };

    // Las opciones dependen de la etapa real de la vacante, no de la que se
    // está viendo: en la máquina del tiempo el menú sigue ahí, sin opción
    // activa, y tocar una opción regresa al presente.
    void ir(CandidatosView v) {
      if (state.viendoPasado) notifier.verEtapa(null);
      notifier.setView(v);
    }

    final enVacantes = view == CandidatosView.vacantes;
    final enDashboard = view == CandidatosView.dashboard;
    final opciones = [
      if (veDashboard(role))
        SidebarOption(
          label: 'Dashboard',
          icon: Icons.space_dashboard_outlined,
          spotlightId: 'menu-dashboard',
          isActive: enDashboard,
          onTap: () => ir(CandidatosView.dashboard),
        ),
      // "Vacantes" es el Home para cambiar de contexto: siempre visible.
      SidebarOption(
        label: 'Vacantes',
        icon: Icons.work_outline_rounded,
        isActive: enVacantes,
        onTap: () => ir(CandidatosView.vacantes),
      ),
      if (veMenuCandidatos(etapa))
        SidebarOption(
          label: 'Candidatos',
          icon: Icons.people_alt_outlined,
          isActive: !state.viendoPasado && view == CandidatosView.lista,
          onTap: () => ir(CandidatosView.lista),
        ),
      if (comparativa)
        SidebarOption(
          label: 'Comparativa (${state.pick.length})',
          icon: Icons.view_column_outlined,
          isActive: !state.viendoPasado && view == CandidatosView.comparativa,
          onTap: () => ir(CandidatosView.comparativa),
        ),
    ];

    final List<Widget> content = enDashboard
        ? [const DashboardPage()]
        : enVacantes
        ? [VacantesView(state: state, role: role)]
        : state.viendoPasado
        ? [TimeMachineView(state: state, role: role)]
        : [
            switch (view) {
              CandidatosView.lista ||
              CandidatosView.vacantes ||
              CandidatosView.dashboard => _ListaView(state: state, role: role),
              CandidatosView.comparativa => ComparisonView(state: state, role: role),
            },
          ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1500),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CandidatosSidebar(opciones: opciones),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // El dashboard y la lista de vacantes no son de una vacante: van sin encabezado.
                    if (!enVacantes && !enDashboard) ...[VacancyHeader(state: state, role: role), const SizedBox(height: 16)],
                    ...content,
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaView extends StatelessWidget {
  const _ListaView({required this.state, required this.role});

  final CandidatosState state;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    // Requisición y Alineación se destraban con una acción de negocio; aún
    // no hay candidatos que listar.
    if (StageGate.appliesTo(state.vacante)) {
      return SpotlightTarget(id: 'accion', child: StageGate(state: state, role: role));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.vacante.etapaActual == 6) ...[OfertaCard(state: state, role: role), const SizedBox(height: 16)],
        SpotlightTarget(id: 'lista', child: CandidateListPanel(state: state, role: role)),
      ],
    );
  }
}

