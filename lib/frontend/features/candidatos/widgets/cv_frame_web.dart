import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

final _registered = <String>{};

/// Iframe que deja al navegador renderizar el PDF del asset [assetPath].
Widget cvFrame(String assetPath, double zoom) {
  final percent = (zoom * 100).round();
  final viewType = 'cv-frame:$assetPath:$percent';
  if (_registered.add(viewType)) {
    final url = ui_web.assetManager.getAssetUrl(assetPath);
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int _) => web.HTMLIFrameElement()
        ..src = '$url#toolbar=0&zoom=$percent'
        ..title = 'Currículum'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }
  return HtmlElementView(viewType: viewType);
}

const cvFrameSupported = true;
