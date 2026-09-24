import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../backend/models/person.dart';
import '../../../backend/providers.dart';

/// Rol activo en la demo. Reemplaza al login para cambiar de vista rápido.
/// Se guarda para que sobreviva a una recarga.
class CurrentRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() {
    final saved = ref.read(liverhackStoreProvider).role;
    return UserRole.values.where((r) => r.name == saved).firstOrNull ?? UserRole.reclutador;
  }

  void select(UserRole role) {
    if (role == state) return;
    state = role;
    ref.read(liverhackStoreProvider).role = role.name;
  }
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
