import 'package:flutter/material.dart';

import '../../features/workspace/workspace_style.dart';
import '../../features/tutorial/spotlight.dart';
import '../widgets/liquid_background.dart';
import '../widgets/toast_host.dart';
import 'top_bar.dart';

/// Estructura común: fondo líquido y barra superior. La navegación vive
/// dentro de cada módulo (vacantes y pestañas de Candidatos).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        // El tutorial cubre toda la app, incluida la barra superior.
        child: SpotlightHost(
          child: WorkspaceSnackHost(
            child: ToastHost(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TopBar(),
                      const SizedBox(height: 20),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
