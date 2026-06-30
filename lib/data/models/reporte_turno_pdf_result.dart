import 'dart:typed_data';

/// PDF binario de GET /api/reportes/turno/{id}.
class ReporteTurnoPdfResult {
  const ReporteTurnoPdfResult({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}
