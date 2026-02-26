/// Modelo del rol del usuario (login response).
class RolModel {
  const RolModel({
    this.id,
    required this.nombre,
  });

  final int? id;
  final String nombre;

  factory RolModel.fromJson(Map<String, dynamic> json) {
    return RolModel(
      id: json['id'] is int ? json['id'] as int : null,
      nombre: (json['nombre'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nombre': nombre,
      };
}
