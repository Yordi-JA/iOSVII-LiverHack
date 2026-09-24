import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de las herramientas de Workspace que simula el hub de comunicación.
abstract final class GColors {
  static const blue = Color(0xFF1A73E8);
  static const red = Color(0xFFEA4335);
  static const green = Color(0xFF34A853);
  static const yellow = Color(0xFFFBBC04);
  static const chatGreen = Color(0xFF00796B);
  static const meetGreen = Color(0xFF00832D);
  static const text = Color(0xFF1F1F1F);
  static const textSoft = Color(0xFF5F6368);
  static const outline = Color(0xFFDADCE0);
  static const surface = Color(0xFFF8FAFD);
  static const surfaceBlue = Color(0xFFE8F0FE);
  static const snackBar = Color(0xFF323232);
}

/// Tipografía sans-serif de Material (Roboto) para toda la UI de Workspace.
TextStyle gText({double size = 14, FontWeight weight = FontWeight.w400, Color color = GColors.text}) =>
    GoogleFonts.roboto(fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.1);

// ---------------------------------------------------------------------------
// SnackBars estilo notificación web de Google. El controlador publica el
// mensaje y [WorkspaceSnackHost] lo muestra con el ScaffoldMessenger.

class WorkspaceSnack {
  const WorkspaceSnack(this.id, this.message, {this.icon});

  final int id;
  final String message;
  final IconData? icon;
}

class WorkspaceSnackNotifier extends Notifier<WorkspaceSnack?> {
  var _next = 0;

  @override
  WorkspaceSnack? build() => null;

  void show(String message, {IconData? icon}) => state = WorkspaceSnack(_next++, message, icon: icon);
}

final workspaceSnackProvider = NotifierProvider<WorkspaceSnackNotifier, WorkspaceSnack?>(WorkspaceSnackNotifier.new);

/// Muestra un SnackBar oscuro, compacto y flotante, como las notificaciones
/// de las apps web de Google.
void showWorkspaceSnackBar(BuildContext context, String message, {IconData? icon}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger != null) showWorkspaceSnackBarOn(messenger, message, icon: icon);
}

/// Igual que [showWorkspaceSnackBar], con el messenger ya resuelto. Sirve
/// para avisar después de cerrar un diálogo u hoja, cuando su context ya no existe.
void showWorkspaceSnackBarOn(ScaffoldMessengerState messenger, String message, {IconData? icon}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: GColors.snackBar,
        elevation: 6,
        width: 560,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Row(
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 12)],
            Expanded(child: Text(message, style: gText(color: Colors.white))),
          ],
        ),
        action: SnackBarAction(label: 'Cerrar', textColor: const Color(0xFF8AB4F8), onPressed: () {}),
      ),
    );
}

class WorkspaceSnackHost extends ConsumerWidget {
  const WorkspaceSnackHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(workspaceSnackProvider, (_, snack) {
      if (snack != null) showWorkspaceSnackBar(context, snack.message, icon: snack.icon);
    });
    return child;
  }
}
