import 'package:flutter/material.dart';

/// Las 6 etapas del flujo y acuerdo de servicios.
enum PipelineStage {
  requisicion('Requisición', 'Solicitud del HRBP', Icons.assignment_outlined),
  alineacion('Alineación', 'AT y HM', Icons.handshake_outlined),
  busqueda('Búsqueda', 'Atracción de talento', Icons.travel_explore_outlined),
  atraccion('Atracción', 'Filtro de reclutamiento', Icons.filter_alt_outlined),
  seleccion('Selección', 'Entrevistas con HM', Icons.how_to_reg_outlined),
  oferta('Oferta', 'HR y AT la comparten', Icons.workspace_premium_outlined);

  const PipelineStage(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;

  /// Número de etapa (1 a 6).
  int get number => index + 1;

  static PipelineStage fromNumber(int number) => values[(number - 1).clamp(0, values.length - 1)];
}
