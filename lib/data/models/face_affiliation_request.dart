/// Body de POST /api/rostros.
class FaceAffiliationRequest {
  const FaceAffiliationRequest({
    required this.nombre,
    required this.paterno,
    required this.materno,
    required this.telefono,
    required this.embeddingsList,
  });

  final String nombre;
  final String paterno;
  final String materno;
  final String telefono;
  final List<List<double>> embeddingsList;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'paterno': paterno,
        'materno': materno,
        'telefono': telefono,
        'embeddingsList': embeddingsList,
      };
}
