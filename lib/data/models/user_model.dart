import '../../domain/entities/user_entity.dart';

/// Modelo de usuario para capa de datos.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.roleName,
    super.apellidoPaterno,
    super.apellidoMaterno,
    super.telefono,
    super.userName,
    super.fotoPerfil,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id']?.toString()) ?? '',
      email: (json['email'] as String?) ?? (json['userName'] as String?) ?? '',
      name: (json['name'] as String?) ?? (json['nombre'] as String?) ?? '',
      roleName: json['roleName'] as String?,
      apellidoPaterno: json['apellidoPaterno'] as String?,
      apellidoMaterno: json['apellidoMaterno'] as String?,
      telefono: json['telefono'] as String?,
      userName: json['userName'] as String?,
      fotoPerfil: json['fotoPerfil'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        if (roleName != null) 'roleName': roleName,
        if (apellidoPaterno != null) 'apellidoPaterno': apellidoPaterno,
        if (apellidoMaterno != null) 'apellidoMaterno': apellidoMaterno,
        if (telefono != null) 'telefono': telefono,
        if (userName != null) 'userName': userName,
        if (fotoPerfil != null) 'fotoPerfil': fotoPerfil,
      };

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      roleName: entity.roleName,
      apellidoPaterno: entity.apellidoPaterno,
      apellidoMaterno: entity.apellidoMaterno,
      telefono: entity.telefono,
      userName: entity.userName,
      fotoPerfil: entity.fotoPerfil,
    );
  }
}
