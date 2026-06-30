/// Extrae el nombre de archivo del header Content-Disposition.
String fileNameFromContentDisposition(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'reporte-turno.pdf';
  }

  final utf8Match = RegExp(
    r"filename\*=UTF-8''([^;]+)",
    caseSensitive: false,
  ).firstMatch(value);
  if (utf8Match != null) {
    return Uri.decodeComponent(utf8Match.group(1)!.trim());
  }

  final quotedMatch = RegExp(
    r'filename="([^"]+)"',
    caseSensitive: false,
  ).firstMatch(value);
  if (quotedMatch != null) {
    return quotedMatch.group(1)!.trim();
  }

  final plainMatch = RegExp(
    r'filename=([^;\s]+)',
    caseSensitive: false,
  ).firstMatch(value);
  if (plainMatch != null) {
    return plainMatch.group(1)!.trim();
  }

  return 'reporte-turno.pdf';
}
