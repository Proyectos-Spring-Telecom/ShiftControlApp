/// Permiso activo del usuario en GET /api/login/me.
class PermisoPerfilModel {
  const PermisoPerfilModel({
    required this.idPermiso,
    this.id,
  });

  final int idPermiso;
  final int? id;

  factory PermisoPerfilModel.fromJson(Map<String, dynamic> json) {
    return PermisoPerfilModel(
      idPermiso: (json['idPermiso'] as num).toInt(),
      id: (json['id'] as num?)?.toInt(),
    );
  }
}
