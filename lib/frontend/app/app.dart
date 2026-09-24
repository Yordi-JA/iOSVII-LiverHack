import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class PuertaLiverpoolApp extends StatelessWidget {
  const PuertaLiverpoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Puerta Liverpool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
