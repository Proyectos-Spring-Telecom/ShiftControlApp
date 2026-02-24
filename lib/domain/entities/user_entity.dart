/// Entidad de usuario en la capa de dominio.
class UserEntity {
  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
  });

  final String id;
  final String email;
  final String name;
}
