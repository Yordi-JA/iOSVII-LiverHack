import 'package:flutter/material.dart';

class NavDestination {
  const NavDestination(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}

const navDestinations = [
  NavDestination('/', 'Dashboard', Icons.space_dashboard_outlined),
  NavDestination('/procesos', 'Procesos', Icons.linear_scale_rounded),
  NavDestination('/candidatos', 'Candidatos', Icons.people_alt_outlined),
  NavDestination('/comparativa', 'Comparativa', Icons.view_column_outlined),
  NavDestination('/entrevistas', 'Entrevistas', Icons.forum_outlined),
  NavDestination('/directorio', 'Directorio', Icons.badge_outlined),
  NavDestination('/alertas', 'Alertas', Icons.notifications_none_rounded),
];
