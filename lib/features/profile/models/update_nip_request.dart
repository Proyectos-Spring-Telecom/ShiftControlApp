/// Modelo del body para PATCH /api/usuarios/mi-nip.
/// TODO: Implementar hash seguro antes de enviar si backend lo requiere.
class UpdateNipRequest {
  const UpdateNipRequest({required this.pinHash});

  final String pinHash;

  Map<String, dynamic> toJson() => {
        'pinHash': pinHash,
      };
}
