import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../backend/candidatos/models.dart';
import '../../../core/theme/app_colors.dart';
import '../candidatos_controller.dart';
import 'ui_kit.dart';
import 'cv_frame_stub.dart' if (dart.library.js_interop) 'cv_frame_web.dart';

/// Resultado cacheado de si existe el PDF de cada candidato en assets/cvs/.
final _exists = <String, Future<bool>>{};

Future<bool> _pdfExists(String assetPath) => _exists.putIfAbsent(assetPath, () async {
  if (!cvFrameSupported) return false;
  try {
    await rootBundle.load(assetPath);
    return true;
  } catch (_) {
    return false;
  }
});

/// Visor de CV estilo lector de PDF: barra oscura con zoom y la página.
class CvViewer extends ConsumerWidget {
  const CvViewer({super.key, required this.candidato, this.height = 560});

  final Candidato candidato;
  final double height;

  static const _bar = Color(0xFF323639);
  static const _barText = Color(0xFFE8EAED);
  static const _pageBg = Color(0xFF525659);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(candidatosProvider.select((s) => s.value?.zoomOf(candidato.id) ?? 1));
    final notifier = ref.read(candidatosProvider.notifier);
    final file = candidato.cvFileName.isEmpty ? 'cv.pdf' : candidato.cvFileName;
    final assetPath = 'assets/cvs/$file';
    final barStyle = GoogleFonts.montserrat(color: _barText, fontSize: 12.5);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Container(
              color: _bar,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              // En columnas angostas (comparativa) se omite el contador de páginas.
              child: LayoutBuilder(
                builder: (context, box) => Row(
                children: [
                  const Text('📄', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(file, style: barStyle, overflow: TextOverflow.ellipsis),
                  ),
                  if (box.maxWidth >= 300) ...[
                    Text('1 / 1', style: barStyle),
                    const SizedBox(width: 12),
                  ],
                  _ZoomButton(
                    icon: Icons.remove,
                    label: 'Alejar',
                    onTap: zoom > 0.6 ? () => notifier.zoom(candidato.id, -0.1) : null,
                  ),
                  SizedBox(
                    width: 44,
                    child: Text('${(zoom * 100).round()}%', style: barStyle, textAlign: TextAlign.center),
                  ),
                  _ZoomButton(
                    icon: Icons.add,
                    label: 'Acercar',
                    onTap: zoom < 1.6 ? () => notifier.zoom(candidato.id, 0.1) : null,
                  ),
                ],
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: _pageBg,
                child: FutureBuilder<bool>(
                  future: _pdfExists(assetPath),
                  builder: (context, snap) {
                    if (snap.data == true) return cvFrame(assetPath, zoom);
                    return _FallbackPage(candidato: candidato, zoom: zoom);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      color: CvViewer._barText,
      disabledColor: CvViewer._barText.withValues(alpha: 0.35),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      padding: EdgeInsets.zero,
    );
  }
}

/// Hoja blanca que simula el CV cuando el PDF no está disponible.
class _FallbackPage extends StatelessWidget {
  const _FallbackPage({required this.candidato, required this.zoom});

  final Candidato candidato;
  final double zoom;

  static const _width = 520.0;

  @override
  Widget build(BuildContext context) {
    final c = candidato;
    final body = GoogleFonts.sourceSerif4(fontSize: 12, height: 1.45, color: const Color(0xFF2B2B2B));
    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 3),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x33E10098))),
            ),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.magenta,
                letterSpacing: 0.6,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );

    final page = Container(
      width: _width,
      padding: const EdgeInsets.fromLTRB(36, 34, 36, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.nombre,
            style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF1C1B2E)),
          ),
          const SizedBox(height: 2),
          Text(
            c.puestoActual,
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.purple),
          ),
          const SizedBox(height: 4),
          Text('${correoSimulado(c.nombre)}  ·  Ciudad de México', style: body.copyWith(fontSize: 11, color: const Color(0xFF666666))),
          section('Perfil profesional', [Text(c.resumenProfesional, style: body)]),
          section('Experiencia', [
            Text('${c.puestoActual}, ${c.empresaActual}', style: body.copyWith(fontWeight: FontWeight.w700)),
            Text(
              c.anosExperiencia > 0
                  ? '${_years(c.anosExperiencia)} años de experiencia en el área'
                  : 'Primera experiencia profesional',
              style: body,
            ),
          ]),
          section('Educación', [Text(c.escolaridad, style: body)]),
          if (c.otrosEstudios.isNotEmpty)
            section('Certificaciones y otros estudios', [Text(c.otrosEstudios, style: body)]),
          section('Idiomas', [Text(c.idiomas.map((i) => '${i.idioma}: ${i.nivel}').join('  ·  '), style: body)]),
          if (c.assessFirst.fortalezas.isNotEmpty)
            section('Habilidades', [for (final f in c.assessFirst.fortalezas) Text('•  $f', style: body)]),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Center(
          child: SizedBox(
            width: _width * zoom,
            child: FittedBox(fit: BoxFit.fitWidth, alignment: Alignment.topCenter, child: page),
          ),
        ),
      ),
    );
  }

  static String _years(double y) => y == y.roundToDouble() ? y.toStringAsFixed(0) : y.toStringAsFixed(1);
}
