/// Resultado de POST /api/embed/validate-pose.
class FaceAffiliationValidatePoseResult {
  const FaceAffiliationValidatePoseResult({
    required this.valid,
    this.message,
  });

  final bool valid;
  final String? message;
}
