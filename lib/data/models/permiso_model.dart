/// Modelo de permiso (login response).
class PermisoModel {
  const PermisoModel({
    this.id,
    this.nombre,
    this.codigo,
  });

  final int? id;
  final String? nombre;
  final String? codigo;

  factory PermisoModel.fromJson(Map<String, dynamic> json) {
    return PermisoModel(
      id: json['id'] is int ? json['id'] as int : null,
      nombre: json['nombre'] as String?,
      codigo: json['codigo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (nombre != null) 'nombre': nombre,
        if (codigo != null) 'codigo': codigo,
      };
}
