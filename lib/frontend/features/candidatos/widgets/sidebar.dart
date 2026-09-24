import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../tutorial/spotlight.dart';

/// Opción del menú lateral. Qué opciones existen lo deciden las reglas de
/// etapa y rol en la página; aquí solo se dibujan.
class SidebarOption {
  const SidebarOption({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.spotlightId,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  /// Id para que el tutorial pueda resaltar esta opción.
  final String? spotlightId;
}

/// Panel lateral plegable de la vacante, a toda la altura. Desplegado
/// muestra íconos y texto; plegado, solo los íconos. Sin opciones se oculta
/// por completo y el contenido ocupa todo el ancho.
class CandidatosSidebar extends StatefulWidget {
  const CandidatosSidebar({super.key, required this.opciones});

  final List<SidebarOption> opciones;

  @override
  State<CandidatosSidebar> createState() => _CandidatosSidebarState();
}

class _CandidatosSidebarState extends State<CandidatosSidebar> {
  static const _anchoDesplegado = 224.0;
  static const _anchoPlegado = 80.0;
  static const _separacion = 16.0;

  /// `null` = automático: desplegado solo si la pantalla es ancha.
  bool? _desplegado;

  @override
  Widget build(BuildContext context) {
    final pantallaAncha = MediaQuery.sizeOf(context).width >= 1100;
    final desplegado = _desplegado ?? pantallaAncha;
    final ancho = widget.opciones.isEmpty
        ? 0.0
        : desplegado
        ? _anchoDesplegado
        : _anchoPlegado;

    return SpotlightTarget(
      id: 'menu',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: ancho,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Durante la animación se decide con el ancho real de cada cuadro,
              // así el texto nunca se desborda.
              final w = constraints.maxWidth;
              if (w < _anchoPlegado - 8) return const SizedBox.shrink();
              final conTexto = w >= _anchoDesplegado - 24;
              return Padding(
                padding: const EdgeInsets.only(right: _separacion),
                child: GlassCard(
                  radius: 22,
                  padding: EdgeInsets.fromLTRB(conTexto ? 12 : 8, 12, conTexto ? 12 : 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final o in widget.opciones) ...[
                        _Marcado(
                          id: o.spotlightId,
                          child: SidebarMenuItem(
                            icon: o.icon,
                            label: o.label,
                            isActive: o.isActive,
                            onTap: o.onTap,
                            conTexto: conTexto,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      const Spacer(),
                      Align(
                        alignment: conTexto ? Alignment.centerRight : Alignment.center,
                        child: IconButton(
                          tooltip: desplegado ? 'Plegar menú' : 'Desplegar menú',
                          icon: Icon(
                            desplegado
                                ? Icons.keyboard_double_arrow_left_rounded
                                : Icons.keyboard_double_arrow_right_rounded,
                            size: 20,
                            color: AppColors.inkSoft,
                          ),
                          onPressed: () => setState(() => _desplegado = !desplegado),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Envuelve [child] en un [SpotlightTarget] solo si hay [id].
class _Marcado extends StatelessWidget {
  const _Marcado({required this.id, required this.child});

  final String? id;
  final Widget child;

  @override
  Widget build(BuildContext context) => id == null ? child : SpotlightTarget(id: id!, child: child);
}

/// Opción del menú lateral. Activa: fondo blanco sólido redondeado, texto
/// oscuro e ícono magenta. Inactiva: transparente y en gris, con un fondo
/// ligero al pasar el mouse.
class SidebarMenuItem extends StatefulWidget {
  const SidebarMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.conTexto = true,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  /// Plegado: solo el ícono, con el texto como tooltip.
  final bool conTexto;

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final activo = widget.isActive;
    final fondo = activo
        ? Colors.white
        : _hover
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0);

    final item = Semantics(
      selected: activo,
      button: true,
      label: widget.conTexto ? null : widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 46,
            padding: EdgeInsets.symmetric(horizontal: widget.conTexto ? 14 : 0),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: activo ? 0.10 : 0),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: widget.conTexto ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 20, color: activo ? AppColors.magenta : AppColors.inkSoft),
                if (widget.conTexto) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: AppTypography.label.copyWith(
                        fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
                        color: activo ? AppColors.ink : AppColors.inkSoft,
                      ),
                      child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return widget.conTexto ? item : Tooltip(message: widget.label, child: item);
  }
}
