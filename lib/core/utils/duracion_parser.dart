/// Convierte [duracion] del backend a segundos.
/// Acepta `int`/`num`, string numérico o formato `HH:mm:ss` / `HH:mm`.
int? parseDuracionSegundos(dynamic duracion) {
  if (duracion == null) return null;
  if (duracion is num) return duracion.toInt();

  if (duracion is String) {
    final trimmed = duracion.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length < 2) return null;
      final horas = int.tryParse(parts[0]) ?? 0;
      final minutos = int.tryParse(parts[1]) ?? 0;
      final segundos = parts.length >= 3 ? (int.tryParse(parts[2]) ?? 0) : 0;
      return horas * 3600 + minutos * 60 + segundos;
    }

    return int.tryParse(trimmed);
  }

  return null;
}
