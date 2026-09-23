import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_text.dart';
import 'nav_destinations.dart';

class SideNav extends StatelessWidget {
  const SideNav({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 18),
      child: SizedBox(
        width: 208,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Logo(),
            const SizedBox(height: 32),
            for (final d in navDestinations)
              _NavItem(destination: d, selected: _isSelected(d.path)),
          ],
        ),
      ),
    );
  }

  bool _isSelected(String path) => path == '/' ? location == '/' : location.startsWith(path);
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: AppColors.magenta.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: const Icon(Icons.monitor_heart_outlined, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientMask(child: Text('Pulso', style: AppTypography.title.copyWith(fontWeight: FontWeight.w700))),
            Text('Atracción de talento', style: AppTypography.caption.copyWith(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.destination, required this.selected});

  final NavDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(destination.icon, size: 20, color: selected ? Colors.white : AppColors.inkSoft);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.go(destination.path),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: selected ? Colors.white.withValues(alpha: 0.85) : Colors.transparent,
              border: Border.all(color: selected ? Colors.white : Colors.transparent),
              boxShadow: selected
                  ? [BoxShadow(color: AppColors.purple.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Row(
              children: [
                selected ? GradientMask(child: icon) : icon,
                const SizedBox(width: 12),
                Text(
                  destination.label,
                  style: AppTypography.label.copyWith(
                    color: selected ? AppColors.ink : AppColors.inkSoft,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
