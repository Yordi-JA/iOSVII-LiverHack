import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class PulsoApp extends StatelessWidget {
  const PulsoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pulso · Liverpool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
