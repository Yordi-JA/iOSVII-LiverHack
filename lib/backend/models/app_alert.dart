import 'package:flutter/material.dart';

import '../../frontend/core/theme/app_colors.dart';

enum AlertType {
  sla(Icons.warning_amber_rounded),
  feedback(Icons.schedule_rounded),
  compensacion(Icons.payments_outlined),
  agenda(Icons.event_outlined);

  const AlertType(this.icon);

  final IconData icon;
}

enum AlertSeverity {
  alta(AppColors.danger),
  media(AppColors.warning),
  info(AppColors.info);

  const AlertSeverity(this.color);

  final Color color;
}

class AppAlert {
  const AppAlert({
    required this.id,
    required this.tipo,
    required this.severidad,
    required this.mensaje,
    required this.accion,
    this.leida = false,
  });

  final String id;
  final AlertType tipo;
  final AlertSeverity severidad;
  final String mensaje;

  /// Texto corto de la acción sugerida o ya tomada.
  final String accion;
  final bool leida;

  factory AppAlert.fromMap(String id, Map<String, dynamic> map) => AppAlert(
        id: id,
        tipo: AlertType.values.byName(map['tipo'] ?? 'sla'),
        severidad: AlertSeverity.values.byName(map['severidad'] ?? 'info'),
        mensaje: map['mensaje'] ?? '',
        accion: map['accion'] ?? '',
        leida: map['leida'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'tipo': tipo.name,
        'severidad': severidad.name,
        'mensaje': mensaje,
        'accion': accion,
        'leida': leida,
      };
}
