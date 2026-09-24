enum UserRole {
  reclutador('AT'),
  hiringManager('HM'),
  hrbp('HRBP'),
  entrevistador('Entrevistador');

  const UserRole(this.label);

  final String label;
}

/// Persona del directorio (actores clave del proceso).
class Person {
  const Person({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.puesto,
    required this.vacantesAsignadas,
  });

  final String id;
  final String nombre;
  final UserRole rol;
  final String puesto;
  final int vacantesAsignadas;

  factory Person.fromMap(String id, Map<String, dynamic> map) => Person(
        id: id,
        nombre: map['nombre'] ?? '',
        rol: UserRole.values.byName(map['rol'] ?? 'entrevistador'),
        puesto: map['puesto'] ?? '',
        vacantesAsignadas: (map['vacantes_asignadas'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'rol': rol.name,
        'puesto': puesto,
        'vacantes_asignadas': vacantesAsignadas,
      };
}
