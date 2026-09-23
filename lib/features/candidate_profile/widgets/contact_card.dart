import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/candidate.dart';

/// Un canal de contacto: teléfono, correo, LinkedIn, GitHub, portafolio.
class ContactChannel {
  const ContactChannel(this.label, this.value, this.icon, this.uri, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Uri uri;
  final Color color;

  static List<ContactChannel> of(ContactInfo c) {
    Uri web(String v) => Uri.parse(v.startsWith('http') ? v : 'https://$v');
    return [
      if (c.telefono != null)
        ContactChannel('Teléfono', c.telefono!, Icons.phone_outlined, Uri(scheme: 'tel', path: c.telefono!.replaceAll(' ', '')), AppColors.success),
      if (c.email != null) ContactChannel('Correo', c.email!, Icons.mail_outline_rounded, Uri(scheme: 'mailto', path: c.email), AppColors.info),
      if (c.linkedin != null) ContactChannel('LinkedIn', c.linkedin!, Icons.work_outline_rounded, web(c.linkedin!), const Color(0xFF0A66C2)),
      if (c.github != null) ContactChannel('GitHub', c.github!, Icons.code_rounded, web(c.github!), AppColors.ink),
      if (c.portafolio != null) ContactChannel('Portafolio', c.portafolio!, Icons.palette_outlined, web(c.portafolio!), AppColors.orange),
    ];
  }
}

Future<void> openChannel(BuildContext context, ContactChannel ch) async {
  final opened = await launchUrl(ch.uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir ${ch.label}')));
  }
}

/// Botones redondos de acceso rápido para el encabezado del perfil.
class ContactQuickBar extends StatelessWidget {
  const ContactQuickBar({super.key, required this.contact});

  final ContactInfo contact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ch in ContactChannel.of(contact))
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: '${ch.label}: ${ch.value}',
              child: InkWell(
                onTap: () => openChannel(context, ch),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.75),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Icon(ch.icon, size: 18, color: ch.color),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Sección de contacto completa.
class ContactCard extends StatelessWidget {
  const ContactCard({super.key, required this.contact});

  final ContactInfo contact;

  @override
  Widget build(BuildContext context) {
    final channels = ContactChannel.of(contact);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contact_page_outlined, size: 18, color: AppColors.purple),
              const SizedBox(width: 8),
              Text('Contacto y enlaces', style: AppTypography.headline),
              const Spacer(),
              if (contact.ciudad != null) ...[
                const Icon(Icons.place_outlined, size: 16, color: AppColors.inkSoft),
                const SizedBox(width: 4),
                Text(contact.ciudad!, style: AppTypography.caption),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (channels.isEmpty)
            Text('Sin datos de contacto registrados.', style: AppTypography.body.copyWith(color: AppColors.inkSoft)),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final ch in channels) _ChannelTile(channel: ch)],
          ),
          const SizedBox(height: 12),
          Text('Datos simulados para la demo.', style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({required this.channel});

  final ContactChannel channel;

  @override
  Widget build(BuildContext context) {
    final ch = channel;
    return SizedBox(
      width: 360,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: ch.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(ch.icon, size: 20, color: ch.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ch.label, style: AppTypography.caption),
                  Text(ch.value, overflow: TextOverflow.ellipsis, style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copiar',
              icon: const Icon(Icons.copy_rounded, size: 16),
              color: AppColors.inkSoft,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: ch.value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ch.label} copiado')));
              },
            ),
            IconButton(
              tooltip: 'Abrir',
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              color: AppColors.purple,
              onPressed: () => openChannel(context, ch),
            ),
          ],
        ),
      ),
    );
  }
}
