import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../backend/models/person.dart';
import '../../features/candidatos/candidatos_controller.dart';
import '../../features/notifications/role_alerts.dart';
import '../../features/session/role_provider.dart';
import '../../features/tutorial/spotlight.dart';
import '../../features/tutorial/tutorial.dart';
import '../../features/workspace/workspace_style.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';
import '../widgets/gradient_avatar.dart';

class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final name = displayNameFor(role);

    // Patrón Z: la marca ancla la izquierda y los controles de sistema y de
    // usuario se agrupan a la derecha (rol → notificaciones → perfil).
    return LayoutBuilder(
      builder: (context, box) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Brand(compact: box.maxWidth < 1000),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SpotlightTarget(id: 'rol', child: _RoleMenu()),
              const SizedBox(width: 24),
              const SpotlightTarget(id: 'ayuda', child: _HelpButton()),
              const SizedBox(width: 12),
              const SpotlightTarget(id: 'campana', child: _BellButton()),
              const SizedBox(width: 24),
              _Profile(role: role, name: name, showGreeting: box.maxWidth >= 760),
            ],
          ),
        ],
      ),
    );
  }
}

/// Perfil del usuario simulado: avatar y saludo.
class _Profile extends StatelessWidget {
  const _Profile({required this.role, required this.name, required this.showGreeting});

  final UserRole role;
  final String name;

  /// En pantallas angostas queda solo el avatar.
  final bool showGreeting;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sesión de $name, ${role.label}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GradientAvatar(initials: initialsOf(name), size: 46, tintIndex: 1, photoUrl: photoFor(role)),
          if (showGreeting) ...[
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hola,', style: AppTypography.caption),
                  Text(
                    name,
                    style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Marca de la app: monograma con el gradiente de marca y "Puerta Liverpool".
class _Brand extends StatelessWidget {
  const _Brand({this.compact = false});

  /// Solo el monograma, para pantallas angostas.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.title.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4);
    return Semantics(
      header: true,
      label: 'Puerta Liverpool',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [BoxShadow(color: AppColors.magenta.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Text('P', style: style.copyWith(color: Colors.white, fontSize: 20)),
            ),
            if (!compact) ...[
            const SizedBox(width: 10),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Puerta '),
                  TextSpan(text: 'Liverpool', style: style.copyWith(color: AppColors.magenta)),
                ],
              ),
              style: style,
            ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Selector de rol como menú desplegable: muestra solo el rol activo y, al
/// abrirlo, las tres opciones.
class _RoleMenu extends ConsumerWidget {
  const _RoleMenu();

  static const _roles = [UserRole.reclutador, UserRole.hiringManager, UserRole.hrbp];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentRoleProvider);
    return PopupMenuButton<UserRole>(
      tooltip: 'Cambiar de rol',
      initialValue: current,
      offset: const Offset(0, 50),
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: GColors.outline)),
      onSelected: (role) => ref.read(currentRoleProvider.notifier).select(role),
      itemBuilder: (context) => [
        for (final role in _roles)
          PopupMenuItem<UserRole>(
            value: role,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: role == current ? const Icon(Icons.check_rounded, size: 18, color: AppColors.magenta) : null,
                ),
                const SizedBox(width: 8),
                Text(
                  role.label,
                  style: AppTypography.label.copyWith(fontWeight: role == current ? FontWeight.w700 : FontWeight.w500),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 42,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white),
        ),
        child: Text(current.label, style: AppTypography.label.copyWith(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Campana de notificaciones según el rol (RBAC). Al abrirla se marcan como
/// vistas; al tocar una se abre la vacante o la ficha relacionada.
/// Vuelve a abrir el tutorial desde la vista de la vacante, en el presente.
class _HelpButton extends ConsumerWidget {
  const _HelpButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Ver tutorial',
      child: Material(
        color: Colors.white.withValues(alpha: 0.55),
        shape: const CircleBorder(side: BorderSide(color: Colors.white)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            GoRouter.maybeOf(context)?.go('/candidatos');
            final notifier = ref.read(candidatosProvider.notifier);
            notifier.verEtapa(null);
            notifier.setView(CandidatosView.lista);
            ref.read(tutorialProvider.notifier).iniciar();
          },
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Icon(Icons.help_outline_rounded, color: AppColors.ink, size: 22),
          ),
        ),
      ),
    );
  }
}

class _BellButton extends ConsumerWidget {
  const _BellButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final alerts = ref.watch(roleAlertsProvider);
    final unseen = ref.watch(unseenRoleAlertsProvider);

    return PopupMenuButton<RoleAlert>(
      tooltip: 'Notificaciones',
      offset: const Offset(0, 52),
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 380),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: GColors.outline)),
      onOpened: () => ref.read(seenRoleAlertsProvider.notifier).markSeen(alerts.map((a) => a.id)),
      onSelected: (alert) {
        final notifier = ref.read(candidatosProvider.notifier);
        if (alert.candidato case final c?) {
          notifier.openFromAlert(c);
        } else if (alert.vacanteId case final id?) {
          notifier.selectVacante(id);
        }
        context.go('/candidatos');
      },
      itemBuilder: (context) => [
        PopupMenuItem<RoleAlert>(
          enabled: false,
          height: 40,
          child: Text('Notificaciones · ${role.label}', style: gText(size: 14, weight: FontWeight.w500)),
        ),
        const PopupMenuDivider(height: 1),
        if (alerts.isEmpty)
          PopupMenuItem<RoleAlert>(
            enabled: false,
            child: Text('No tienes notificaciones.', style: gText(color: GColors.textSoft)),
          )
        else
          for (final a in alerts)
            PopupMenuItem<RoleAlert>(
              value: a,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: a.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(a.icon, color: a.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: gText(size: 13.5, weight: FontWeight.w500)),
                        if (a.body != null) ...[
                          const SizedBox(height: 2),
                          Text(a.body!, style: gText(size: 12.5, color: GColors.textSoft)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
      child: Container(
        width: 42,
        height: 42,
        // Sin alinear, el ícono ocupaba el círculo desde la esquina superior izquierda.
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white),
        ),
        child: Badge(
          isLabelVisible: unseen > 0,
          label: Text('$unseen'),
          backgroundColor: GColors.red,
          child: const Icon(Icons.notifications_none, color: AppColors.ink, size: 22),
        ),
      ),
    );
  }
}
