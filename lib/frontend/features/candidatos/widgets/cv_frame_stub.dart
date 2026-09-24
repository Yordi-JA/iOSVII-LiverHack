import 'package:flutter/widgets.dart';

/// Fuera de la web no hay iframe: el visor usa la hoja de respaldo.
Widget cvFrame(String assetPath, double zoom) => const SizedBox.shrink();

const cvFrameSupported = false;
