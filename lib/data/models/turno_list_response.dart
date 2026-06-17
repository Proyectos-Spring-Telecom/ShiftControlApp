import '../../core/utils/duracion_parser.dart';

/// Item de GET /api/turnos/list.
class TurnoListItem {
  const TurnoListItem({
    required this.id,
    required this.placas,
    this.marca,
    this.modelo,
    this.duracion,
    this.fechaApertura,
    this.fechaCierre,
    this.estatusTurnoNombre,
  });

  final int id;
  final String placas;
  final String? marca;
  final String? modelo;
  final String? duracion;
  final DateTime? fechaApertura;
  final DateTime? fechaCierre;
  final String? estatusTurnoNombre;

  String get vehiculoDisplay {
    final parts = [marca, modelo].whereType<String>().where((s) => s.isNotEmpty);
    if (parts.isNotEmpty) return parts.join(' ');
    return placas;
  }

  int? get duracionSegundos => parseDuracionSegundos(duracion);

  factory TurnoListItem.fromJson(Map<String, dynamic> json) {
    final aperturaRaw = json['fechaApertura'] as String?;
    final cierreRaw = json['fechaCierre'] as String?;
    return TurnoListItem(
      id: (json['id'] as num).toInt(),
      placas: json['placas'] as String? ?? '',
      marca: json['marca'] as String?,
      modelo: json['modelo'] as String?,
      duracion: json['duracion'] as String?,
      fechaApertura:
          aperturaRaw != null ? DateTime.parse(aperturaRaw).toLocal() : null,
      fechaCierre:
          cierreRaw != null ? DateTime.parse(cierreRaw).toLocal() : null,
      estatusTurnoNombre: json['estatusTurnoNombre'] as String?,
    );
  }
}

class TurnoListResponse {
  const TurnoListResponse({required this.items});

  final List<TurnoListItem> items;

  factory TurnoListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) return const TurnoListResponse(items: []);
    return TurnoListResponse(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(TurnoListItem.fromJson)
          .toList(),
    );
  }
}
