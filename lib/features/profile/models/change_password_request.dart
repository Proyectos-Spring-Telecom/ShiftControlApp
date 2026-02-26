/// Modelo del body para PATCH /api/usuarios/actualizar/contrasena.
class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.passwordActual,
    required this.passwordNueva,
    required this.passwordNuevaConfirmacion,
  });

  final String passwordActual;
  final String passwordNueva;
  final String passwordNuevaConfirmacion;

  Map<String, dynamic> toJson() => {
        'passwordActual': passwordActual,
        'passwordNueva': passwordNueva,
        'passwordNuevaConfirmacion': passwordNuevaConfirmacion,
      };
}
