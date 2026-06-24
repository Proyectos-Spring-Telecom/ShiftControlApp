/// Modelo del rol del usuario (login / GET /api/login/me).
class RolModel {
  const RolModel({
    this.id,
    required this.nombre,
    this.descripcion,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.estatus,
  });

  final int? id;
  final String nombre;
  final String? descripcion;
  final String? fechaCreacion;
  final String? fechaActualizacion;
  final int? estatus;

  factory RolModel.fromJson(Map<String, dynamic> json) {
    return RolModel(
      id: (json['id'] as num?)?.toInt(),
      nombre: (json['nombre'] as String?) ?? '',
      descripcion: json['descripcion'] as String?,
      fechaCreacion: json['fechaCreacion'] as String?,
      fechaActualizacion: json['fechaActualizacion'] as String?,
      estatus: (json['estatus'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (fechaCreacion != null) 'fechaCreacion': fechaCreacion,
        if (fechaActualizacion != null) 'fechaActualizacion': fechaActualizacion,
        if (estatus != null) 'estatus': estatus,
      };
}
