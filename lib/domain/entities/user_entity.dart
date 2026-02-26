/// Entidad de usuario en la capa de dominio.
class UserEntity {
  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.roleName,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.telefono,
    this.userName,
    this.fotoPerfil,
  });

  final String id;
  final String email;
  final String name;
  final String? roleName;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? telefono;
  final String? userName;
  final String? fotoPerfil;
}
