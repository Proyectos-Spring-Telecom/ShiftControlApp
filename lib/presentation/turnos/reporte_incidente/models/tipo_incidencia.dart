import 'package:flutter/material.dart';

/// Tipo de incidencia con ID oficial del backend.
class TipoIncidencia {
  const TipoIncidencia({
    required this.id,
    required this.nombre,
  });

  final int id;
  final String nombre;
}

const TipoIncidencia tipoIncidenciaAccidente =
    TipoIncidencia(id: 1, nombre: 'Accidente');
const TipoIncidencia tipoIncidenciaFallaMecanica =
    TipoIncidencia(id: 2, nombre: 'Falla Mecánica');
const TipoIncidencia tipoIncidenciaDanoExterior =
    TipoIncidencia(id: 3, nombre: 'Daño Exterior');
const TipoIncidencia tipoIncidenciaOtro =
    TipoIncidencia(id: 4, nombre: 'Otro');

/// Catálogo oficial de tipos de incidencia (texto ↔ ID backend).
const List<TipoIncidencia> tiposIncidencia = [
  tipoIncidenciaAccidente,
  tipoIncidenciaFallaMecanica,
  tipoIncidenciaDanoExterior,
  tipoIncidenciaOtro,
];

TipoIncidencia? tipoIncidenciaPorId(int id) {
  for (final tipo in tiposIncidencia) {
    if (tipo.id == id) return tipo;
  }
  return null;
}

/// Iconos asociados a cada tipo (solo para la UI existente).
IconData iconoTipoIncidencia(int id) {
  return switch (id) {
    1 => Icons.car_crash_outlined,
    2 => Icons.build_outlined,
    3 => Icons.image_outlined,
    4 => Icons.more_horiz,
    _ => Icons.help_outline,
  };
}
