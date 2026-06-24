/// Respuesta de POST /api/rostros.
class FaceAffiliationResponse {
  const FaceAffiliationResponse({
    required this.success,
    this.id,
  });

  final bool success;
  final int? id;

  factory FaceAffiliationResponse.fromJson(Map<String, dynamic> json) {
    return FaceAffiliationResponse(
      success: json['success'] as bool? ?? false,
      id: (json['id'] as num?)?.toInt(),
    );
  }
}
