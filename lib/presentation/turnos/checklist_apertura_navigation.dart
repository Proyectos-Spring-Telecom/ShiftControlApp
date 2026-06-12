import 'package:flutter/material.dart';

import '../../features/turnos/services/checklist_progress_service.dart';
import 'captura_odometro/captura_odometro_page.dart';
import 'documentacion/documentacion_page.dart';
import 'inicio_turno/inicio_turno_page.dart';
import 'indicadores_testigo/indicadores_testigo_page.dart';
import 'luces_vehiculo/luces_vehiculo_page.dart';
import 'niveles_fluido/niveles_fluido_page.dart';
import 'accesorios/accesorios_page.dart';
import 'registro_danos/registro_danos_page.dart';
import 'resumen_turno/resumen_turno_page.dart';

/// Números de paso del checklist de apertura (orden canónico en MainShell).
abstract final class ChecklistAperturaPasos {
  ChecklistAperturaPasos._();

  static const int inicio = 1;
  static const int capturaOdometro = 2;
  static const int registroDanos = 3;
  static const int indicadoresTestigo = 4;
  static const int nivelesFluido = 5;
  static const int lucesVehiculo = 6;
  static const int accesorios = 7;
  static const int documentacion = 8;
  static const int resumen = 9;

  static String? routeForPaso(int paso) {
    return switch (paso) {
      inicio => '/inicio-turno',
      capturaOdometro => '/captura-odometro',
      registroDanos => '/registro-danos',
      indicadoresTestigo => '/indicadores-testigo',
      nivelesFluido => '/niveles-fluido',
      lucesVehiculo => '/luces-vehiculo',
      accesorios => '/accesorios',
      documentacion => '/documentacion',
      resumen => '/resumen-turno',
      _ => null,
    };
  }
}

/// Rutas del checklist de cierre (orden canónico en MainShell).
abstract final class ChecklistCierrePasos {
  ChecklistCierrePasos._();

  static const int inicio = 1;
  static const int capturaOdometro = 2;
  static const int registroDanos = 3;
  static const int indicadoresTestigo = 4;
  static const int nivelesFluido = 5;
  static const int lucesVehiculo = 6;
  static const int accesorios = 7;
  static const int documentacion = 8;
  static const int resumen = 9;

  static String? routeForPaso(int paso) {
    return switch (paso) {
      inicio => '/cierre-turno',
      capturaOdometro => '/cierre-captura-odometro',
      registroDanos => '/cierre-registro-danos',
      indicadoresTestigo => '/cierre-indicadores-testigo',
      nivelesFluido => '/cierre-niveles-fluido',
      lucesVehiculo => '/cierre-luces-vehiculo',
      accesorios => '/cierre-accesorios',
      documentacion => '/cierre-documentacion',
      resumen => '/cierre-resumen-turno',
      _ => null,
    };
  }
}

/// Navegación standalone al retomar (sin MainShell).
void navegarChecklistAperturaStandalone(
  BuildContext context,
  int paso,
  ChecklistProgress progreso,
) {
  void irAPaso(int destino) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => _paginaChecklistStandalone(ctx, destino, progreso, irAPaso),
      ),
    );
  }

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (ctx) => _paginaChecklistStandalone(ctx, paso, progreso, irAPaso),
    ),
  );
}

Widget _paginaChecklistStandalone(
  BuildContext context,
  int paso,
  ChecklistProgress progreso,
  void Function(int) irAPaso,
) {
  return switch (paso) {
    ChecklistAperturaPasos.inicio => InicioTurnoPage(
        onSiguienteTap: () => irAPaso(ChecklistAperturaPasos.capturaOdometro),
      ),
    ChecklistAperturaPasos.capturaOdometro => CapturaOdometroPage(
        placa: progreso.placa,
        marca: progreso.marcaNombre,
        modelo: progreso.modeloNombre,
        anio: progreso.anio,
        economico: progreso.numeroEconomico,
        onSiguienteTap: () => irAPaso(ChecklistAperturaPasos.registroDanos),
      ),
    ChecklistAperturaPasos.registroDanos => RegistroDanosPage(
        onContinuar: () => irAPaso(ChecklistAperturaPasos.indicadoresTestigo),
      ),
    ChecklistAperturaPasos.indicadoresTestigo => IndicadoresTestigoPage(
        onContinuar: () => irAPaso(ChecklistAperturaPasos.nivelesFluido),
      ),
    ChecklistAperturaPasos.nivelesFluido => NivelesFluidoPage(
        onContinuar: () => irAPaso(ChecklistAperturaPasos.lucesVehiculo),
      ),
    ChecklistAperturaPasos.lucesVehiculo => LucesVehiculoPage(
        onContinuar: () => irAPaso(ChecklistAperturaPasos.accesorios),
      ),
    ChecklistAperturaPasos.accesorios => AccesoriosPage(
        onContinuar: () => irAPaso(ChecklistAperturaPasos.documentacion),
      ),
    ChecklistAperturaPasos.documentacion => DocumentacionPage(
        onContinuar: () => irAPaso(ChecklistAperturaPasos.resumen),
      ),
    ChecklistAperturaPasos.resumen => const ResumenTurnoPage(),
    _ => const InicioTurnoPage(),
  };
}
