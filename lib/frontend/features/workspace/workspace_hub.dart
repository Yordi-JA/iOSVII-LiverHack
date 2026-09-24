import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../backend/candidatos/models.dart';
import '../../../backend/candidatos/rules.dart';
import '../../../backend/models/person.dart';
import '../../core/utils/formatters.dart';
import '../candidatos/widgets/ui_kit.dart' show correoSimulado;
import 'workspace_style.dart';

/// Barra de comunicación del candidato: Chat, Meet, Drive y Gmail.
/// Gmail (con templates) solo lo usa Reclutamiento.
class WorkspaceActionBar extends StatelessWidget {
  const WorkspaceActionBar({super.key, required this.candidato, required this.vacante, required this.role});

  final Candidato candidato;
  final Vacante vacante;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: GColors.outline),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text('Comunicación', style: gText(size: 13, weight: FontWeight.w500, color: GColors.textSoft)),
          ),
          _HubButton(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            color: GColors.chatGreen,
            onTap: () => _openSheet(context, _ChatSheet(candidato: candidato, vacante: vacante)),
          ),
          _HubButton(
            icon: Icons.videocam_outlined,
            label: 'Meet',
            color: GColors.meetGreen,
            onTap: () => _openSheet(context, _MeetSheet(candidato: candidato, vacante: vacante)),
          ),
          _HubButton(
            icon: Icons.add_to_drive_outlined,
            label: 'Drive',
            color: GColors.blue,
            onTap: () => _openSheet(context, _DriveSheet(candidato: candidato, vacante: vacante)),
          ),
          if (isAt(role))
            _HubButton(
              icon: Icons.mail_outline,
              label: 'Gmail',
              color: GColors.red,
              onTap: () => showDialog<void>(
                context: context,
                barrierColor: Colors.black.withValues(alpha: 0.12),
                builder: (_) => GmailComposeDialog(candidato: candidato, vacante: vacante),
              ),
            ),
        ],
      ),
    );
  }
}

class _HubButton extends StatelessWidget {
  const _HubButton({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Abrir $label',
      child: Material(
        color: color.withValues(alpha: 0.08),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(label, style: gText(size: 14, weight: FontWeight.w500, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openSheet(BuildContext context, Widget sheet) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.white,
  constraints: const BoxConstraints(maxWidth: 720),
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
  builder: (_) => sheet,
);

/// Estructura común de las hojas: asa, encabezado con ícono y contenido.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.icon,
    required this.color,
    required this.app,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String app;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: GColors.outline, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app, style: gText(size: 12, weight: FontWeight.w500, color: GColors.textSoft)),
                        Text(title, style: gText(size: 20), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  ?trailing,
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: GColors.textSoft),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: GColors.outline),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.name, {this.color = GColors.blue, this.size = 32});

  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: color,
    child: Text(initialsOf(name), style: gText(size: size * 0.38, weight: FontWeight.w500, color: Colors.white)),
  );
}

// ---------------------------------------------------------------------------
// Chat

class _ChatSheet extends StatefulWidget {
  const _ChatSheet({required this.candidato, required this.vacante});

  final Candidato candidato;
  final Vacante vacante;

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _input = TextEditingController();
  late final List<({bool mine, String author, String text, String time})> _messages = [
    (
      mine: true,
      author: widget.vacante.reclutador,
      text:
          'Hola ${widget.candidato.firstName}, gracias por tu interés en ${widget.vacante.titulo}. '
          '¿Tienes disponibilidad esta semana para una llamada?',
      time: '9:12',
    ),
    (mine: false, author: widget.candidato.nombre, text: '¡Hola! Sí, el jueves por la tarde me queda perfecto.', time: '9:40'),
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add((mine: true, author: 'Tú', text: text, time: 'Ahora'));
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.candidato;
    return _SheetFrame(
      icon: Icons.chat_bubble_outline,
      color: GColors.chatGreen,
      app: 'Chat',
      title: c.nombre,
      trailing: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text('Mensaje directo', style: gText(size: 12, color: GColors.textSoft)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              children: [
                Center(child: Text('Hoy', style: gText(size: 12, weight: FontWeight.w500, color: GColors.textSoft))),
                const SizedBox(height: 12),
                for (final m in _messages)
                  Align(
                    alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 440),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: m.mine ? GColors.surfaceBlue : const Color(0xFFF1F3F4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${m.author} · ${m.time}',
                            style: gText(size: 12, weight: FontWeight.w500, color: GColors.textSoft),
                          ),
                          const SizedBox(height: 2),
                          Text(m.text, style: gText(size: 14)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Container(
              padding: const EdgeInsets.only(left: 20, right: 4),
              decoration: BoxDecoration(color: const Color(0xFFF1F3F4), borderRadius: BorderRadius.circular(28)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onSubmitted: (_) => _send(),
                      style: gText(),
                      decoration: InputDecoration(
                        hintText: 'Mensaje a ${c.firstName}',
                        hintStyle: gText(color: GColors.textSoft),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Enviar mensaje',
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded, color: GColors.chatGreen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meet

class _MeetSheet extends StatelessWidget {
  const _MeetSheet({required this.candidato, required this.vacante});

  final Candidato candidato;
  final Vacante vacante;

  /// Código de reunión estable por candidato (formato xxx-xxxx-xxx).
  String get _code {
    const letters = 'abcdefghijkmnopqrstuvwxyz';
    var seed = candidato.id * 7919 + vacante.id.hashCode.abs();
    final chars = [
      for (var i = 0; i < 10; i++) letters[(seed = (seed * 31 + 17) % 1000003) % letters.length],
    ].join();
    return '${chars.substring(0, 3)}-${chars.substring(3, 7)}-${chars.substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    final code = _code;
    final participantes = [
      (candidato.nombre, 'Candidato', GColors.meetGreen),
      (vacante.hiringManager, 'Hiring manager', GColors.blue),
      (vacante.reclutador, 'Reclutamiento', GColors.red),
    ];

    void done(String message, IconData icon) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop();
      if (messenger != null) showWorkspaceSnackBarOn(messenger, message, icon: icon);
    }

    return _SheetFrame(
      icon: Icons.videocam_outlined,
      color: GColors.meetGreen,
      app: 'Meet',
      title: 'Entrevista con ${candidato.nombre}',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: GColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.link, color: GColors.textSoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Código de la reunión', style: gText(size: 12, color: GColors.textSoft)),
                        Text(code, style: gText(size: 18, weight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      done('Código de la reunión copiado.', Icons.content_copy);
                    },
                    icon: const Icon(Icons.content_copy, size: 18),
                    label: const Text('Copiar'),
                    style: TextButton.styleFrom(foregroundColor: GColors.blue, textStyle: gText(weight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Participantes', style: gText(size: 14, weight: FontWeight.w500)),
            const SizedBox(height: 8),
            for (final (nombre, rol, color) in participantes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _Avatar(nombre, color: color),
                title: Text(nombre, style: gText()),
                subtitle: Text(rol, style: gText(size: 12, color: GColors.textSoft)),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => done('Reunión iniciada. Código $code.', Icons.videocam_outlined),
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Iniciar reunión instantánea'),
                  style: FilledButton.styleFrom(
                    backgroundColor: GColors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    shape: const StadiumBorder(),
                    textStyle: gText(weight: FontWeight.w500),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => done(
                    'Invitación enviada a ${candidato.firstName}, ${vacante.hiringManager} y ${vacante.reclutador}.',
                    Icons.event_outlined,
                  ),
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Programar en Calendar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GColors.blue,
                    side: const BorderSide(color: GColors.outline),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    shape: const StadiumBorder(),
                    textStyle: gText(weight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drive

typedef _DriveFile = ({String name, IconData icon, Color color, String owner, String modified});

class _DriveSheet extends StatefulWidget {
  const _DriveSheet({required this.candidato, required this.vacante});

  final Candidato candidato;
  final Vacante vacante;

  @override
  State<_DriveSheet> createState() => _DriveSheetState();
}

class _DriveSheetState extends State<_DriveSheet> {
  late final List<_DriveFile> _files = [
    (
      name: widget.candidato.cvFileName.isEmpty ? 'CV.pdf' : widget.candidato.cvFileName,
      icon: Icons.picture_as_pdf,
      color: GColors.red,
      owner: widget.candidato.nombre,
      modified: 'hace 5 días',
    ),
    (
      name: 'Resumen AssessFirst – ${widget.candidato.nombre}',
      icon: Icons.description,
      color: GColors.blue,
      owner: widget.vacante.reclutador,
      modified: 'hace 3 días',
    ),
    (
      name: 'Notas de entrevista – ${widget.vacante.titulo}',
      icon: Icons.description,
      color: GColors.blue,
      owner: widget.vacante.hiringManager,
      modified: 'ayer',
    ),
    (
      name: 'Comparativa de compensación',
      icon: Icons.table_chart,
      color: GColors.green,
      owner: widget.vacante.hrbp,
      modified: 'ayer',
    ),
  ];

  /// Archivos ya compartidos con el HM (se confirma en la misma fila).
  final _compartidos = <String>{};

  void _nuevo() {
    setState(() {
      _files.insert(0, (
        name: 'Evaluación técnica – ${widget.candidato.nombre}',
        icon: Icons.description,
        color: GColors.blue,
        owner: 'Tú',
        modified: 'ahora',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.candidato;
    return _SheetFrame(
      icon: Icons.add_to_drive_outlined,
      color: GColors.blue,
      app: 'Drive',
      title: 'Carpeta de ${c.nombre}',
      trailing: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: FloatingActionButton.extended(
          heroTag: null,
          elevation: 1,
          highlightElevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: GColors.text,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: _nuevo,
          icon: const Icon(Icons.add, color: GColors.blue),
          label: Text('Nuevo', style: gText(weight: FontWeight.w500)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
            child: Text(
              'Mi unidad  ›  Candidatos  ›  ${widget.vacante.titulo}  ›  ${c.nombre}',
              style: gText(size: 13, color: GColors.textSoft),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: _files.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: GColors.outline, indent: 60),
              itemBuilder: (context, i) {
                final f = _files[i];
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Icon(f.icon, color: f.color, size: 28),
                  title: Text(f.name, style: gText(weight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                  subtitle: Text('${f.owner} · Modificado ${f.modified}', style: gText(size: 12, color: GColors.textSoft)),
                  trailing: _compartidos.contains(f.name)
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: GColors.green, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Compartido con ${widget.vacante.hiringManager}',
                              style: gText(size: 12, color: GColors.textSoft),
                            ),
                          ],
                        )
                      : IconButton(
                          tooltip: 'Compartir con ${widget.vacante.hiringManager}',
                          icon: const Icon(Icons.person_add_alt_1_outlined, color: GColors.textSoft),
                          onPressed: () => setState(() => _compartidos.add(f.name)),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gmail

typedef _Template = ({String nombre, String asunto, String cuerpo});

List<_Template> _templates(Candidato c, Vacante v) => [
  (
    nombre: 'Solicitud de portafolio',
    asunto: 'Solicitud de portafolio – ${v.titulo}',
    cuerpo:
        'Hola ${c.firstName}:\n\n'
        'Gracias por tu interés en la posición de ${v.titulo}. Para continuar con tu proceso, '
        '¿podrías compartirnos tu portafolio o ejemplos recientes de tu trabajo?\n\n'
        'Puedes responder a este correo con un enlace o un archivo adjunto.\n\n'
        'Saludos,\n${v.reclutador}\nAtracción de Talento',
  ),
  (
    nombre: 'Agendar llamada técnica',
    asunto: 'Llamada técnica – ${v.titulo}',
    cuerpo:
        'Hola ${c.firstName}:\n\n'
        'Nos gustaría agendar una llamada técnica de 45 minutos con ${v.hiringManager} para conocer más '
        'sobre tu experiencia. ¿Qué horario te acomoda esta semana?\n\n'
        'Te enviaremos la invitación de Meet en cuanto confirmes.\n\n'
        'Saludos,\n${v.reclutador}\nAtracción de Talento',
  ),
  (
    nombre: 'Seguimiento del proceso',
    asunto: 'Actualización de tu proceso – ${v.titulo}',
    cuerpo:
        'Hola ${c.firstName}:\n\n'
        'Te escribimos para contarte que tu perfil sigue en revisión con el equipo de ${v.area}. '
        'Te daremos noticias en los próximos días.\n\n'
        'Saludos,\n${v.reclutador}\nAtracción de Talento',
  ),
];

/// Ventana "Mensaje nuevo" de Gmail, anclada abajo a la derecha.
class GmailComposeDialog extends StatefulWidget {
  const GmailComposeDialog({super.key, required this.candidato, required this.vacante});

  final Candidato candidato;
  final Vacante vacante;

  @override
  State<GmailComposeDialog> createState() => _GmailComposeDialogState();
}

class _GmailComposeDialogState extends State<GmailComposeDialog> {
  final _asunto = TextEditingController();
  final _cuerpo = TextEditingController();
  String? _template;

  @override
  void dispose() {
    _asunto.dispose();
    _cuerpo.dispose();
    super.dispose();
  }

  void _cargar(String? nombre) {
    final t = _templates(widget.candidato, widget.vacante).where((t) => t.nombre == nombre).firstOrNull;
    if (t == null) return;
    setState(() {
      _template = nombre;
      _asunto.text = t.asunto;
      _cuerpo.text = t.cuerpo;
    });
  }

  void _enviar() {
    final para = correoSimulado(widget.candidato.nombre);
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.of(context).pop();
    if (messenger != null) showWorkspaceSnackBarOn(messenger, 'Mensaje enviado a $para.', icon: Icons.send_outlined);
  }

  @override
  Widget build(BuildContext context) {
    final para = correoSimulado(widget.candidato.nombre);
    Widget field(String label, Widget child) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: GColors.outline))),
      child: Row(
        children: [
          Text(label, style: gText(color: GColors.textSoft)),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );

    return Dialog(
      alignment: Alignment.bottomRight,
      insetPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 540,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFFF2F6FC),
              padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
              child: Row(
                children: [
                  Expanded(child: Text('Mensaje nuevo', style: gText(weight: FontWeight.w500))),
                  IconButton(
                    tooltip: 'Minimizar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.minimize, size: 18, color: GColors.textSoft),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18, color: GColors.textSoft),
                  ),
                ],
              ),
            ),
            field(
              'Para',
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: _Avatar(widget.candidato.nombre, color: GColors.red, size: 22),
                    label: Text(para, style: gText(size: 13)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: GColors.outline),
                    shape: const StadiumBorder(),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
            field(
              'Asunto',
              TextField(
                controller: _asunto,
                style: gText(),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _cuerpo,
                minLines: 10,
                maxLines: 14,
                style: gText(),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 12, 14),
              child: Row(
                children: [
                  FilledButton(
                    onPressed: _enviar,
                    style: FilledButton.styleFrom(
                      backgroundColor: GColors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: const StadiumBorder(),
                      textStyle: gText(weight: FontWeight.w500),
                    ),
                    child: const Text('Enviar'),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.description_outlined, size: 18, color: GColors.textSoft),
                  const SizedBox(width: 6),
                  // Ocupa el espacio libre y recorta el nombre del template si no cabe.
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _template,
                        isExpanded: true,
                        hint: Text(
                          'Cargar template',
                          style: gText(size: 13, color: GColors.textSoft),
                          overflow: TextOverflow.ellipsis,
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: GColors.textSoft),
                        style: gText(size: 13),
                        borderRadius: BorderRadius.circular(8),
                        items: [
                          for (final t in _templates(widget.candidato, widget.vacante))
                            DropdownMenuItem(
                              value: t.nombre,
                              child: Text(t.nombre, style: gText(size: 13), overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: _cargar,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Descartar borrador',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.delete_outline, color: GColors.textSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
