import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/informacion_general_response.dart';
import '../../data/models/mi_turno_activo_response.dart';
import '../../features/turnos/services/turnos_service.dart';
import '../controllers/auth_controller.dart';
import '../turnos/detalle_turno/detalle_turno_page.dart';

/// Provider del servicio de turnos.
final turnosServiceProvider = Provider<TurnosService>((ref) {
  return TurnosService(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageServiceProvider),
  );
});

/// Estado del turno activo: loading, data o error.
final miTurnoActivoProvider =
    StateNotifierProvider<MiTurnoActivoNotifier, AsyncValue<MiTurnoActivoResponse>>((ref) {
  return MiTurnoActivoNotifier(ref.watch(turnosServiceProvider));
});

class MiTurnoActivoNotifier extends StateNotifier<AsyncValue<MiTurnoActivoResponse>> {
  MiTurnoActivoNotifier(this._service) : super(const AsyncValue.loading());

  final TurnosService _service;

  /// Consulta el API. Llamar al entrar a la página.
  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final response = await _service.obtenerMiTurnoActivo();
      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Información general de bitácora para ResumenTurnoPage.
final informacionGeneralProvider =
    StateNotifierProvider.autoDispose<InformacionGeneralNotifier,
        AsyncValue<InformacionGeneralResponse>>((ref) {
  return InformacionGeneralNotifier(ref.watch(turnosServiceProvider));
});

class InformacionGeneralNotifier
    extends StateNotifier<AsyncValue<InformacionGeneralResponse>> {
  InformacionGeneralNotifier(this._service) : super(const AsyncValue.loading());

  final TurnosService _service;

  Future<void> fetch(int idBitacoraVehiculo) async {
    state = const AsyncValue.loading();
    try {
      final response = await _service.obtenerInformacionGeneral(
        idBitacoraVehiculo: idBitacoraVehiculo,
      );
      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reportMissingBitacora() {
    state = AsyncValue.error(
      const NetworkException(
        'No hay bitácora de apertura. Completa el flujo de apertura.',
        '400',
      ),
      StackTrace.current,
    );
  }
}

/// Provider del detalle de turno para Historial de Turnos.
final turnoDetalleProvider = StateNotifierProvider.autoDispose<
    TurnoDetalleNotifier, AsyncValue<TurnoDetalleData>>((ref) {
  return TurnoDetalleNotifier(ref.watch(turnosServiceProvider));
});

class TurnoDetalleNotifier
    extends StateNotifier<AsyncValue<TurnoDetalleData>> {
  TurnoDetalleNotifier(this._service) : super(const AsyncValue.loading());

  final TurnosService _service;

  Future<void> fetch(int idTurno) async {
    state = const AsyncValue.loading();
    try {
      final response = await _service.obtenerTurnoDetalle(id: idTurno);
      state = AsyncValue.data(
        TurnoDetalleData.fromTurnoDetalle(response.data),
      );
    } catch (e, st) {
      debugPrint('TurnoDetalleNotifier: error $e');
      state = AsyncValue.error(e, st);
    }
  }
}
