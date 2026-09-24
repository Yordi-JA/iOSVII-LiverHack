import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/candidatos/models.dart';
import '../../../../backend/candidatos/rules.dart';
import '../../../../backend/models/person.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../candidatos_controller.dart';
import 'ui_kit.dart';

/// Acción de negocio que destraba las etapas 1 y 2. Mientras la vacante
/// no llega a Búsqueda no hay candidatos que mostrar: en su lugar aparece
/// la tarjeta de quien debe actuar, o a quién se está esperando.
class StageGate extends StatelessWidget {
  const StageGate({super.key, required this.state, required this.role})
    : etapa = null,
      vacante = null,
      cierre = null;

  /// Versión de solo lectura para la vista histórica: muestra la tarjeta de
  /// la [etapa] con los datos de la [vacante] en ese momento y, en lugar de
  /// los botones de acción, el [cierre] (quién completó la etapa y cuándo).
  const StageGate.historico({
    super.key,
    required this.state,
    required this.role,
    required int this.etapa,
    required Vacante this.vacante,
    required Widget this.cierre,
  });

  final CandidatosState state;
  final UserRole role;
  final int? etapa;
  final Vacante? vacante;
  final Widget? cierre;

  /// Etapas que se resuelven con esta tarjeta en lugar de la lista:
  /// Requisición, Alineación y Búsqueda (aún no hay candidatos importados).
  static bool appliesTo(Vacante v) => v.etapaActual <= 3;

  @override
  Widget build(BuildContext context) {
    if (cierre case final cierre?) {
      return switch (etapa) {
        1 => _RequisicionCard(vacante: vacante!, sla: state.sla, cierre: cierre),
        2 => _AlineacionCard(vacante: vacante!, sla: state.sla, cierre: cierre),
        _ => _BusquedaHistorica(vacante: vacante!, cierre: cierre),
      };
    }
    final v = state.vacante;
    return switch (v.etapaActual) {
      3 when role == UserRole.reclutador => _BusquedaCard(vacante: v, enAts: state.enAts(v.id).length),
      3 => _WaitingCard(
        vacante: v,
        sla: state.sla,
        icon: Icons.travel_explore_rounded,
        title: 'Búsqueda en curso',
        body:
            '${v.reclutador} está buscando candidatos en el ATS (Aira). En cuanto los importe, '
            'la vacante pasa a Atracción y aparecen en la lista.',
      ),
      1 when role == UserRole.hrbp => _RequisicionCard(vacante: v, sla: state.sla),
      1 => _WaitingCard(
        vacante: v,
        sla: state.sla,
        icon: Icons.account_balance_wallet_outlined,
        title: 'Requisición en revisión',
        body:
            'Esperando que ${v.hrbp} (HRBP) valide la posición y apruebe el presupuesto. '
            'Después, ${v.hiringManager} alineará el perfil.',
      ),
      _ when role == UserRole.hiringManager => _AlineacionCard(vacante: v, sla: state.sla),
      _ => _WaitingCard(
        vacante: v,
        sla: state.sla,
        icon: Icons.handshake_outlined,
        title: 'Esperando la alineación de ${v.hiringManager}',
        body:
            'El Hiring manager debe aprobar el perfil buscado. El SLA de la búsqueda arranca en cuanto lo haga '
            'y los candidatos se habilitan a partir de esa etapa.',
      ),
    };
  }
}

/// Etapa 1 (HRBP): detalles financieros y aprobación del presupuesto.
class _RequisicionCard extends ConsumerWidget {
  const _RequisicionCard({required this.vacante, required this.sla, this.cierre});

  final Vacante vacante;
  final SlaConfig sla;

  /// En la vista histórica reemplaza al botón de aprobación.
  final Widget? cierre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = vacante;
    final slaTotal = [for (var i = 0; i < stages.length; i++) stageDays(v, i, sla)].reduce((a, b) => a + b);

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen ejecutivo: cifras clave (A) y directorio (B), sin cajas.
          LayoutBuilder(
            builder: (context, box) {
              final kpis = IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Cifra(etiqueta: 'Presupuesto máximo anual', valor: formatMoneyShort(v.presupuestoMax)),
                    const VerticalDivider(width: 48, thickness: 1, color: CColors.line),
                    _Cifra(etiqueta: 'SLA total estimado', valor: '$slaTotal', unidad: ' días'),
                    const VerticalDivider(width: 48, thickness: 1, color: CColors.line),
                    _Cifra(etiqueta: 'Complejidad', valor: v.complejidad, color: AppColors.purple),
                  ],
                ),
              );
              final directorio = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LineaDirectorio(icon: Icons.business, etiqueta: 'Área', valor: v.area),
                  _LineaDirectorio(icon: Icons.person_outline, etiqueta: 'Hiring manager', valor: v.hiringManager),
                  _LineaDirectorio(icon: Icons.person_outline, etiqueta: 'Reclutamiento', valor: v.reclutador),
                ],
              );
              return box.maxWidth >= 1040
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          kpis,
                          const VerticalDivider(width: 56, thickness: 1, color: CColors.line),
                          Expanded(child: Align(alignment: Alignment.centerLeft, child: directorio)),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(scrollDirection: Axis.horizontal, child: kpis),
                        const Divider(height: 32, color: CColors.line),
                        directorio,
                      ],
                    );
            },
          ),
          const SizedBox(height: 22),
          cierre ??
              GradientButton(
                label: 'Validar posición y aprobar presupuesto',
                icon: Icons.verified_rounded,
                onTap: () => ref.read(candidatosProvider.notifier).avanzarEtapaVacante(v.id, 2),
              ),
        ],
      ),
    );
  }
}

/// Etapa 2 (HM): perfil buscado, no negociables y la aprobación que arranca el SLA.
class _AlineacionCard extends ConsumerWidget {
  const _AlineacionCard({required this.vacante, required this.sla, this.cierre});

  final Vacante vacante;
  final SlaConfig sla;

  /// En la vista histórica reemplaza a los botones de aprobar y negociar.
  final Widget? cierre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = vacante;
    final allowed = stageDays(v, 1, sla);
    final vencida = etapaVencida(v, sla);
    final siguientes = [for (var i = 2; i < stages.length; i++) (stages[i], stageDays(v, i, sla))];
    final slaRestante = siguientes.fold(0, (sum, e) => sum + e.$2);

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelTitle(
            'Alineación del perfil',
            hint: cierre == null
                ? 'Revisa el perfil que buscará Reclutamiento. Al aprobarlo arranca oficialmente el SLA de la búsqueda.'
                : 'Perfil que el Hiring manager aprobó para la búsqueda.',
            trailing: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: cierre != null
                  ? const StatusPill(label: 'Completada', color: AppColors.flowDone, icon: Icons.check_circle_outline)
                  : StatusPill(
                      label: vencida
                          ? 'Día ${v.diasEnEtapa} de $allowed: está frenando la vacante'
                          : 'Día ${v.diasEnEtapa} de $allowed',
                      color: vencida ? AppColors.danger : AppColors.success,
                      icon: Icons.timer_outlined,
                    ),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, box) {
              final perfil = SoftBox(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Perfil buscado'),
                    Text(v.titulo, style: AppTypography.title.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${v.area} · Complejidad ${v.complejidad.toLowerCase()}', style: AppTypography.body),
                    const SizedBox(height: 4),
                    Text(
                      'Presupuesto acordado: hasta ${formatMoneyShort(v.presupuestoMax)} anuales',
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    const FieldLabel('No negociables'),
                    for (final n in v.perfilNoNegociables)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.flowDone),
                            const SizedBox(width: 8),
                            Expanded(child: Text(n, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ),
                  ],
                ),
              );
              final plan = SoftBox(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Al aprobar arranca el SLA'),
                    for (final (etapa, dias) in siguientes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(etapa, style: AppTypography.body)),
                            Text('$dias días', style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    const Divider(color: CColors.line, height: 18),
                    Row(
                      children: [
                        Expanded(child: Text('Total hasta la oferta', style: AppTypography.label.copyWith(fontWeight: FontWeight.w700))),
                        Text('$slaRestante días', style: AppTypography.label.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Búsqueda la lleva ${v.reclutador}.', style: AppTypography.caption),
                  ],
                ),
              );
              return box.maxWidth >= 720
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [Expanded(flex: 3, child: perfil), const SizedBox(width: 12), Expanded(flex: 2, child: plan)],
                      ),
                    )
                  : Column(children: [perfil, const SizedBox(height: 12), plan]);
            },
          ),
          const SizedBox(height: 24),
          ?cierre,
          if (cierre == null)
          LayoutBuilder(
            builder: (context, box) {
              final aprobar = GradientButton(
                label: 'Aprobar Alineación',
                icon: Icons.handshake_rounded,
                large: true,
                onTap: () => ref.read(candidatosProvider.notifier).avanzarEtapaVacante(v.id, 3),
              );
              final editar = OutlinedButton.icon(
                onPressed: () => _editarPerfil(context, ref, v),
                icon: const Icon(Icons.edit_note_rounded, size: 24),
                label: const Text('Editar Perfil / Negociar', textAlign: TextAlign.center),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  backgroundColor: Colors.white.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  side: const BorderSide(color: CColors.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  textStyle: AppTypography.headline.copyWith(fontWeight: FontWeight.w600),
                ),
              );
              return box.maxWidth >= 640
                  ? Row(
                      children: [
                        Expanded(flex: 3, child: aprobar),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: editar),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [aprobar, const SizedBox(height: 10), editar],
                    );
            },
          ),
        ],
      ),
    );
  }
}

/// Abre el formulario de negociación y guarda el resultado en la vacante.
Future<void> _editarPerfil(BuildContext context, WidgetRef ref, Vacante v) async {
  final result = await showDialog<({int presupuesto, List<String> noNegociables})>(
    context: context,
    builder: (_) => _EditarPerfilDialog(vacante: v),
  );
  if (result == null) return;
  ref
      .read(candidatosProvider.notifier)
      .editarPerfilVacante(v.id, presupuestoMax: result.presupuesto, noNegociables: result.noNegociables);
}

/// Formulario del HM para negociar el presupuesto y los no negociables.
class _EditarPerfilDialog extends StatefulWidget {
  const _EditarPerfilDialog({required this.vacante});

  final Vacante vacante;

  @override
  State<_EditarPerfilDialog> createState() => _EditarPerfilDialogState();
}

class _EditarPerfilDialogState extends State<_EditarPerfilDialog> {
  final _form = GlobalKey<FormState>();
  late final _presupuesto = TextEditingController(text: '${widget.vacante.presupuestoMax}');
  late final _noNegociables = TextEditingController(text: widget.vacante.perfilNoNegociables.join('\n'));

  @override
  void dispose() {
    _presupuesto.dispose();
    _noNegociables.dispose();
    super.dispose();
  }

  List<String> get _lineas => [
    for (final l in _noNegociables.text.split('\n'))
      if (l.trim().isNotEmpty) l.trim(),
  ];

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop((presupuesto: int.parse(_presupuesto.text), noNegociables: _lineas));
  }

  InputDecoration _decoration(String label, {String? helper, String? prefix}) => InputDecoration(
    labelText: label,
    helperText: helper,
    prefixText: prefix,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.7),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: CColors.line)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: CColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.magenta, width: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text('Editar perfil de ${widget.vacante.titulo}', style: AppTypography.title),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ajusta lo que negociaste con Reclutamiento. Los cambios se guardan en la vacante antes de aprobar la alineación.',
                style: AppTypography.body.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _presupuesto,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _decoration('Presupuesto máximo anual (MXN)', prefix: r'$ '),
                validator: (value) {
                  final n = int.tryParse(value ?? '');
                  if (n == null || n <= 0) return 'Escribe un monto mayor a 0.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noNegociables,
                minLines: 4,
                maxLines: 8,
                decoration: _decoration('No negociables', helper: 'Uno por línea'),
                validator: (_) => _lineas.isEmpty ? 'Agrega al menos un no negociable.' : null,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        GradientButton(label: 'Guardar cambios', icon: Icons.check_rounded, onTap: _guardar),
      ],
    );
  }
}

/// Etapa 3 (Reclutador): la vacante ya tiene perfil aprobado; se importan
/// los candidatos desde el ATS. Al llegar, la vacante pasa a Atracción.
class _BusquedaCard extends ConsumerStatefulWidget {
  const _BusquedaCard({required this.vacante, required this.enAts});

  final Vacante vacante;

  /// Candidatos disponibles en Aira para esta vacante.
  final int enAts;

  @override
  ConsumerState<_BusquedaCard> createState() => _BusquedaCardState();
}

class _BusquedaCardState extends ConsumerState<_BusquedaCard> {
  var _importando = false;

  Future<void> _importar() async {
    setState(() => _importando = true);
    await ref.read(candidatosProvider.notifier).importarDesdeAts(widget.vacante.id);
    // Si hubo candidatos, la vacante pasó a Atracción y esta tarjeta ya no está.
    if (mounted) setState(() => _importando = false);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vacante;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(
            'Búsqueda: importa candidatos',
            hint: 'El perfil ya está alineado con el Hiring manager. Trae desde el ATS los candidatos que lo cumplen.',
          ),
          const SizedBox(height: 18),
          SoftBox(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 40, color: AppColors.inkMuted.withValues(alpha: 0.8)),
                const SizedBox(height: 10),
                Text('Aún no hay candidatos en esta vacante.', style: AppTypography.headline, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  widget.enAts == 0
                      ? 'Aira no tiene perfiles para ${v.titulo} todavía.'
                      : '${widget.enAts} perfil${widget.enAts == 1 ? '' : 'es'} de Aira coinciden con ${v.titulo}.',
                  style: AppTypography.body.copyWith(color: AppColors.inkSoft),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _importando
                      ? Column(
                          key: const ValueKey('cargando'),
                          children: [
                            const SizedBox(width: 260, child: LinearProgressIndicator(color: AppColors.flowCurrent)),
                            const SizedBox(height: 10),
                            Text('Consultando Aira…', style: AppTypography.label),
                          ],
                        )
                      : GradientButton(
                          key: const ValueKey('boton'),
                          label: 'Importar candidatos desde ATS (Aira)',
                          icon: Icons.cloud_download_rounded,
                          onTap: _importar,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Etapa 3 en la vista histórica: la tabla todavía vacía porque los
/// candidatos seguían en el ATS.
class _BusquedaHistorica extends StatelessWidget {
  const _BusquedaHistorica({required this.vacante, required this.cierre});

  final Vacante vacante;
  final Widget cierre;

  @override
  Widget build(BuildContext context) {
    final head = AppTypography.caption.copyWith(color: AppColors.inkMuted, fontWeight: FontWeight.w600);
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelTitle('Búsqueda', hint: '${vacante.reclutador} buscaba candidatos en el ATS con el perfil aprobado.'),
          const SizedBox(height: 16),
          SoftBox(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              children: [
                Row(
                  children: [
                    for (final (h, flex) in [('Candidato', 30), ('Compatibilidad', 16), ('Compensación', 17), ('Estatus', 16)])
                      Expanded(flex: flex, child: Text(h, style: head)),
                  ],
                ),
                const Divider(color: CColors.line, height: 20),
                const SizedBox(height: 12),
                Icon(Icons.inbox_outlined, size: 36, color: AppColors.inkMuted.withValues(alpha: 0.8)),
                const SizedBox(height: 8),
                Text(
                  'Los candidatos aún estaban en el ATS (Aira) en esta etapa.',
                  style: AppTypography.body.copyWith(color: AppColors.inkSoft),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          cierre,
        ],
      ),
    );
  }
}

/// Estado de espera para los roles que no actúan en esta etapa.
class _WaitingCard extends StatelessWidget {
  const _WaitingCard({
    required this.vacante,
    required this.sla,
    required this.icon,
    required this.title,
    required this.body,
  });

  final Vacante vacante;
  final SlaConfig sla;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final v = vacante;
    final vencida = etapaVencida(v, sla);
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.flowCurrent.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.flowCurrent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headline.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(body, style: AppTypography.body.copyWith(color: AppColors.inkSoft)),
                const SizedBox(height: 12),
                StatusPill(
                  label: '${v.etapaNombre}: día ${v.diasEnEtapa} de ${stageDays(v, v.etapaActual - 1, sla)}',
                  color: vencida ? AppColors.danger : AppColors.success,
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cifra clave del resumen ejecutivo: etiqueta pequeña y número grande,
/// sin caja propia; opcionalmente con un tag al lado del número.
class _Cifra extends StatelessWidget {
  const _Cifra({required this.etiqueta, required this.valor, this.unidad, this.color});

  final String etiqueta;
  final String valor;
  final String? unidad;

  /// Color del valor (por defecto, la tinta del texto).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final grande = AppTypography.display.copyWith(
      fontSize: 40,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.4,
      height: 1,
      color: color ?? AppColors.ink,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(etiqueta.toUpperCase(), style: AppTypography.caption.copyWith(color: AppColors.inkMuted, fontWeight: FontWeight.w600, letterSpacing: 0.6, fontSize: 11)),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: valor),
              if (unidad != null)
                TextSpan(text: unidad, style: AppTypography.title.copyWith(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
            ],
          ),
          style: grande,
        ),
      ],
    );
  }
}

/// Renglón del directorio: ícono, etiqueta tenue y valor, sin caja.
class _LineaDirectorio extends StatelessWidget {
  const _LineaDirectorio({required this.icon, required this.etiqueta, required this.valor});

  final IconData icon;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.inkSoft),
          const SizedBox(width: 10),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$etiqueta  ', style: AppTypography.caption.copyWith(color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
                  TextSpan(text: valor, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
