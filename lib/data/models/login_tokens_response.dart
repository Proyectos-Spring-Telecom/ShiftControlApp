/// Respuesta de POST /api/login (solo tokens).
class LoginTokensResponse {
  const LoginTokensResponse({
    required this.token,
    this.refreshToken,
    this.expiresIn,
  });

  final String token;
  final String? refreshToken;
  final int? expiresIn;

  factory LoginTokensResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final accessToken = (data['token'] as String?) ??
        (data['accessToken'] as String?) ??
        '';

    return LoginTokensResponse(
      token: accessToken,
      refreshToken: data['refreshToken'] as String?,
      expiresIn: (data['expiresIn'] as num?)?.toInt(),
    );
  }
}
