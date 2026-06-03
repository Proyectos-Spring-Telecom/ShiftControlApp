/// Utilidades para formatear fecha y hora en español (fecha/hora actual del dispositivo).

const _diasCortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _diasCompletos = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
const _meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

/// Fecha y hora actual del dispositivo (ej. "Vie 19 de Feb 2026, 15:42").
String formatearFechaHoraActual() {
  final now = DateTime.now();
  final d = now.day.toString().padLeft(2, '0');
  final h = now.hour.toString().padLeft(2, '0');
  final m = now.minute.toString().padLeft(2, '0');
  return '${_diasCortos[now.weekday - 1]} $d de ${_meses[now.month - 1]} ${now.year}, $h:$m';
}

/// Solo fecha actual (ej. "Viernes, 19 Feb 2026").
String formatearSoloFechaActual() {
  final now = DateTime.now();
  final d = now.day.toString().padLeft(2, '0');
  return '${_diasCompletos[now.weekday - 1]}, $d ${_meses[now.month - 1]} ${now.year}';
}

/// Solo hora actual en formato 12h con AM/PM (ej. "03:42 PM").
String formatearSoloHora12Actual() {
  final now = DateTime.now();
  final h = now.hour;
  final m = now.minute.toString().padLeft(2, '0');
  final am = h < 12;
  final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$h12:$m ${am ? 'AM' : 'PM'}';
}
