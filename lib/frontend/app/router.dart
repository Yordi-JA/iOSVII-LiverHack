import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/layout/app_shell.dart';
import '../features/candidate_profile/candidate_profile_page.dart';
import '../features/comparativa/comparativa_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/procesos/procesos_page.dart';
import '../features/shared/coming_soon_page.dart';

NoTransitionPage<void> _page(Widget child) => NoTransitionPage(child: child);

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', pageBuilder: (_, _) => _page(const DashboardPage())),
        GoRoute(
          path: '/procesos',
          pageBuilder: (_, _) => _page(const ProcesosPage()),
          routes: [
            GoRoute(
              path: 'candidato/:id',
              pageBuilder: (_, state) => _page(CandidateProfilePage(candidateId: state.pathParameters['id']!)),
            ),
          ],
        ),
        GoRoute(
          path: '/candidatos',
          pageBuilder: (_, _) => _page(const ComingSoonPage(
            title: 'Candidatos',
            description: 'Lista con perfil, visor de CV, compensación y AssessFirst.',
            icon: Icons.people_alt_outlined,
          )),
        ),
        GoRoute(path: '/comparativa', pageBuilder: (_, _) => _page(const ComparativaPage())),
        GoRoute(
          path: '/entrevistas',
          pageBuilder: (_, _) => _page(const ComingSoonPage(
            title: 'Entrevistas',
            description: 'Agenda, feedback en vivo a ciegas y decisión del Hiring Manager.',
            icon: Icons.forum_outlined,
          )),
        ),
        GoRoute(
          path: '/directorio',
          pageBuilder: (_, _) => _page(const ComingSoonPage(
            title: 'Directorio',
            description: 'Reclutadores, Hiring Managers y HRBPs con sus vacantes.',
            icon: Icons.badge_outlined,
          )),
        ),
        GoRoute(
          path: '/alertas',
          pageBuilder: (_, _) => _page(const ComingSoonPage(
            title: 'Alertas',
            description: 'SLA, feedback pendiente, compensación y agenda.',
            icon: Icons.notifications_none_rounded,
          )),
        ),
      ],
    ),
  ],
);
