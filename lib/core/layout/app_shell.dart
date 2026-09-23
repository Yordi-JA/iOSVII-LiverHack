import 'package:flutter/material.dart';

import '../widgets/liquid_background.dart';
import 'side_nav.dart';
import 'top_bar.dart';

/// Estructura común: fondo líquido, menú lateral de vidrio y barra superior.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SideNav(location: location),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TopBar(),
                      const SizedBox(height: 20),
                      Expanded(child: child),
                    ],
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
