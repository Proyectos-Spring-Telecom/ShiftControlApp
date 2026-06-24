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
    final refresh = data['refreshToken'] as String?;

    return LoginTokensResponse(
      token: accessToken.replaceAll(RegExp(r'\s+'), ''),
      refreshToken: refresh?.replaceAll(RegExp(r'\s+'), ''),
      expiresIn: (data['expiresIn'] as num?)?.toInt(),
    );
  }
}
