import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/person.dart';
import '../../data/providers.dart';
import '../../features/session/role_provider.dart';
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
    final alertCount = ref.watch(alertsProvider).value?.where((a) => !a.leida).length ?? 0;

    return Row(
      children: [
        GradientAvatar(initials: initialsOf(name), size: 52, tintIndex: 1, photoUrl: photoFor(role)),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola,', style: AppTypography.caption),
            Text(name, style: AppTypography.title),
          ],
        ),
        const Spacer(),
        const _RoleSwitcher(),
        const SizedBox(width: 12),
        const _SearchPill(),
        const SizedBox(width: 12),
        _BellButton(count: alertCount),
      ],
    );
  }
}

class _RoleSwitcher extends ConsumerWidget {
  const _RoleSwitcher();

  static const _roles = [UserRole.reclutador, UserRole.hiringManager, UserRole.hrbp];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentRoleProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          for (final role in _roles)
            GestureDetector(
              onTap: () => ref.read(currentRoleProvider.notifier).select(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: role == current ? AppColors.brandGradientHorizontal : null,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  role.label,
                  style: AppTypography.label.copyWith(
                    fontSize: 12,
                    color: role == current ? Colors.white : AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: AppColors.inkSoft),
          const SizedBox(width: 8),
          Text('Buscar candidato', style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.go('/alertas'),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white),
        ),
        child: Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          backgroundColor: AppColors.magenta,
          child: const Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 20),
        ),
      ),
    );
  }
}
