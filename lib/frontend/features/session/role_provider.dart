import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../backend/models/person.dart';

/// Rol activo en la demo. Reemplaza al login para cambiar de vista rápido.
class CurrentRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => UserRole.reclutador;

  void select(UserRole role) => state = role;
}

final currentRoleProvider = NotifierProvider<CurrentRoleNotifier, UserRole>(CurrentRoleNotifier.new);

/// Nombre que se muestra en el saludo según el rol elegido.
String displayNameFor(UserRole role) => switch (role) {
      UserRole.reclutador => 'Mariana Ortega',
      UserRole.hiringManager => 'Aileen Vargas',
      UserRole.hrbp => 'Mayra Cuandon',
      UserRole.entrevistador => 'Sofia Rodriguez',
    };

/// Foto del usuario de la demo según el rol, o nulo para mostrar iniciales.
String? photoFor(UserRole role) => switch (role) {
      UserRole.reclutador => 'assets/fotos/mariana_ortega.jpg',
      UserRole.hiringManager => 'assets/fotos/aileen_vargas.jpg',
      _ => null,
    };
