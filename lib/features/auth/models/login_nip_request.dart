/// Modelo del body para POST /api/login/operador/accesso/nip.
class LoginNipRequest {
  const LoginNipRequest({
    required this.userName,
    required this.codigo,
  });

  final String userName;
  final String codigo;

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'codigo': codigo,
      };
}
