import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../../data/datasources/remote/placas_validar_remote_datasource.dart';
import '../../../domain/entities/user_entity.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_alert_banner.dart';
import '../models/checklist_type.dart';
import 'inicio_turno_colors.dart';
import '../captura_odometro/captura_odometro_page.dart';
import '../captura_odometro/dashed_border_box.dart';
import '../escanear_vehiculo/escanear_vehiculo_page.dart';
import '../captura_odometro/captura_odometro_colors.dart';
import '../identificar_placa/identificar_placa_page.dart';
import '../mi_turno_provider.dart';
import '../placa_validada_provider.dart';
import '../checklist_progress_provider.dart';
import '../turno_apertura_provider.dart';
import '../turno_cierre_provider.dart';

class InicioTurnoPage extends ConsumerStatefulWidget {
  const InicioTurnoPage({
    super.key,
    this.onSiguienteTap,
    this.onEscanearVehiculoTap,
    this.checklistType = ChecklistType.apertura,
  });

  final VoidCallback? onSiguienteTap;
  final VoidCallback? onEscanearVehiculoTap;
  final ChecklistType checklistType;

  @override
  ConsumerState<InicioTurnoPage> createState() => _InicioTurnoPageState();
}

class _InicioTurnoPageState extends ConsumerState<InicioTurnoPage> {
  String? _vehiculoSeleccionado;
  Uint8List? _fotoResguardo;
  Uint8List? _evidenciaBytes;
  final ImagePicker _picker = ImagePicker();
  bool _validandoPlaca = false;
  bool _creandoTurno = false;
  PlacasValidarResult? _placaValidarResult;
  Position? _cachedPosition;
  String? _ubicacionDisplayName;
  bool _cargandoUbicacion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarLugarDesdeGps();
    });
  }

  Future<void> _cargarLugarDesdeGps() async {
    if (!mounted) return;
    setState(() => _cargandoUbicacion = true);

    final position = await _obtenerUbicacion();
    if (position == null) {
      if (mounted) {
        setState(() {
          _cargandoUbicacion = false;
          _ubicacionDisplayName = null;
        });
      }
      return;
    }
    _cachedPosition = position;

    try {
      final resultado = await ref.read(turnosServiceProvider).obtenerDireccion(
            lat: position.latitude,
            lon: position.longitude,
          );
      if (!mounted) return;
      setState(() {
        _ubicacionDisplayName = resultado.displayName;
        _cargandoUbicacion = false;
      });
    } catch (e) {
      debugPrint('Error obteniendo dirección: $e');
      if (!mounted) return;
      setState(() {
        _ubicacionDisplayName = null;
        _cargandoUbicacion = false;
      });
    }
  }

  Future<void> _tomarFotoResguardo() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      final bytes = await photo.readAsBytes();
      if (mounted) setState(() => _fotoResguardo = bytes);
    }
  }

  void _abrirEscanerVehiculo() {
    if (widget.onEscanearVehiculoTap != null) {
      widget.onEscanearVehiculoTap!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EscanearVehiculoPage(
            onVehiculoEscaneado: (vehiculoId) {
              setState(() => _vehiculoSeleccionado = vehiculoId);
              Navigator.of(context).pop();
            },
            onIngresarManualmente: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }

  void _abrirIdentificarPlaca() {
    // Siempre abrir identificación por placa (foto + API plate/read), no el escáner QR.
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => IdentificarPlacaPage(
          onPlacaIdentificada: (vehiculoId, {Uint8List? imageBytes}) {
            ref.read(placaValidadaProvider.notifier).state = null;
            setState(() {
              _vehiculoSeleccionado = vehiculoId;
              _placaValidarResult = null;
              _evidenciaBytes = imageBytes;
            });
            Navigator.of(context).pop();
            if (vehiculoId.isNotEmpty) _validarPlaca(vehiculoId);
          },
          onRegresar: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<Position?> _obtenerUbicacion() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Se necesita permiso de ubicación para abrir turno.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permisos de ubicación denegados permanentemente. Actívalos en Configuración.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener la ubicación: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  Future<void> _crearTurnoYContinuar() async {
    if (_evidenciaBytes == null || _evidenciaBytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay foto de evidencia. Identifica la placa primero.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final placaValidada = _placaValidarResult?.placa;
    if (placaValidada == null || placaValidada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay placa validada. Espera a que termine la validación.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _creandoTurno = true);

    var position = _cachedPosition;
    if (position == null) {
      position = await _obtenerUbicacion();
      if (position != null) _cachedPosition = position;
    }
    if (position == null) {
      if (mounted) setState(() => _creandoTurno = false);
      return;
    }

    try {
      final turnosService = ref.read(turnosServiceProvider);
      final response = await turnosService.crearTurno(
        placa: placaValidada,
        latitud: position.latitude,
        longitud: position.longitude,
        evidenciaBytes: _evidenciaBytes!,
      );

      if (!mounted) return;
      setState(() => _creandoTurno = false);

      ref.read(turnoAperturaProvider.notifier).state = TurnoAperturaState(
        idTurno: response.idTurno,
        idBitacoraApertura: response.idBitacoraApertura,
        placa: response.placa,
        numeroEconomico: response.numeroEconomico,
        anio: response.anio,
        modeloNombre: response.modeloNombre,
        marcaNombre: response.marcaNombre,
      );

      await ref.read(checklistProgressServiceProvider).guardarInicio(
            idTurno: response.idTurno,
            idBitacoraApertura: response.idBitacoraApertura,
            placa: response.placa,
            numeroEconomico: response.numeroEconomico,
            modeloNombre: response.modeloNombre,
            marcaNombre: response.marcaNombre,
            anio: response.anio,
          );

      debugPrint(
        'Turno creado: idTurno=${response.idTurno}, idBitacoraApertura=${response.idBitacoraApertura}',
      );

      if (widget.onSiguienteTap != null) {
        widget.onSiguienteTap!();
      } else {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CapturaOdometroPage(),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _creandoTurno = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _creandoTurno = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _creandoTurno = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear turno: $e'), backgroundColor: Colors.red),
      );
    }
  }

  int? _obtenerIdTurnoParaCierre() {
    final desdeApertura = ref.read(turnoAperturaProvider).idTurno;
    if (desdeApertura != null) return desdeApertura;
    return ref.read(miTurnoActivoProvider).valueOrNull?.idTurno;
  }

  Future<void> _cerrarTurnoYContinuar() async {
    if (_fotoResguardo == null || _fotoResguardo!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toma la fotografía de resguardo antes de continuar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final idTurno = _obtenerIdTurnoParaCierre();
    if (idTurno == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay turno activo. Verifica tu sesión.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _creandoTurno = true);

    var position = _cachedPosition;
    if (position == null) {
      position = await _obtenerUbicacion();
      if (position != null) _cachedPosition = position;
    }
    if (position == null) {
      if (mounted) setState(() => _creandoTurno = false);
      return;
    }

    try {
      final response = await ref.read(turnosServiceProvider).cerrarTurno(
            idTurno: idTurno,
            latitud: position.latitude,
            longitud: position.longitude,
            evidenciaCierreBytes: _fotoResguardo!,
          );

      final idBitacoraCierre = response.idBitacoraCierre;
      final duracion = response.duracion;
      if (idBitacoraCierre == null || duracion == null) {
        throw const NetworkException('No fue posible cerrar el turno', '500');
      }

      if (!mounted) return;
      setState(() => _creandoTurno = false);

      ref.read(turnoCierreProvider.notifier).state = TurnoCierreState(
        idTurno: idTurno,
        idBitacoraCierre: idBitacoraCierre,
        duracion: duracion,
      );

      await ref.read(checklistProgressServiceProvider).guardarCierreGeografico(
            idTurno: idTurno,
            idBitacoraCierre: idBitacoraCierre,
            duracion: duracion,
          );

      debugPrint(
        'Turno cerrado geográficamente: idTurno=$idTurno, '
        'idBitacoraCierre=$idBitacoraCierre, duracion=$duracion',
      );

      if (widget.onSiguienteTap != null) {
        widget.onSiguienteTap!();
      } else {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CapturaOdometroPage(
              checklistType: ChecklistType.cierre,
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _creandoTurno = false);
      final mensaje = switch (e.code) {
        '401' => 'Sesión expirada',
        '403' => 'Acceso denegado',
        _ => e.message,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _creandoTurno = false);
      final mensaje = switch (e.code) {
        '404' => 'Turno no encontrado',
        _ => e.message.isNotEmpty ? e.message : 'No fue posible cerrar el turno',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _creandoTurno = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible cerrar el turno'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Llama a GET /api/placas/validar con numeroPlaca.
  Future<void> _validarPlaca(String numeroPlaca) async {
    final token = await ref.read(authLocalDatasourceProvider).getStoredToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión expirada. Inicie sesión de nuevo.'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _validandoPlaca = true);
    try {
      final result = await ref.read(placasValidarRemoteDatasourceProvider).validar(
            token,
            numeroPlaca,
          );
      if (!mounted) return;
      ref.read(placaValidadaProvider.notifier).state = result;
      setState(() {
        _validandoPlaca = false;
        _placaValidarResult = result;
        if (result.registered && result.placa != null && result.placa!.isNotEmpty) {
          _vehiculoSeleccionado = result.placa;
        }
      });
      if (!result.registered) {
        showAppAlertBanner(
          context,
          type: AppAlertType.info,
          title: 'Placa no registrada',
          message: 'La placa $numeroPlaca no está registrada en el contexto actual.',
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _validandoPlaca = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } on NetworkException catch (e) {
      if (mounted) {
        setState(() => _validandoPlaca = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _validandoPlaca = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al validar la placa.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Nombre completo del usuario logueado. Usa [name] si viene lleno (evita repetir apellidos); si no, arma nombre + apellidos.
  static String _operadorDisplayName(UserEntity? user) {
    if (user == null) return 'Operador';
    if (user.name.trim().isNotEmpty) return user.name.trim();
    final parts = [
      user.apellidoPaterno,
      user.apellidoMaterno,
    ].where((s) => s != null && s.trim().isNotEmpty).cast<String>().toList();
    if (parts.isNotEmpty) return parts.join(' ');
    return user.email.trim().isNotEmpty ? user.email : 'Operador';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final operadorNombre = _operadorDisplayName(user);
    final isApertura = widget.checklistType == ChecklistType.apertura;
    final pageTitle = isApertura ? 'Inicio de Turno' : 'Cierre de Turno';

    // En Cierre de Turno, usar el vehículo ya capturado en Apertura (no volver a tomar foto).
    if (!isApertura) {
      final placaResult = ref.watch(placaValidadaProvider);
      if (placaResult != null && placaResult.registered && _vehiculoSeleccionado == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.checklistType == ChecklistType.cierre) {
            setState(() {
              _vehiculoSeleccionado = placaResult.placa;
              _placaValidarResult = placaResult;
            });
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: InicioTurnoColors.background(context),
      appBar: AppBar(
        backgroundColor: InicioTurnoColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: InicioTurnoColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            pageTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: InicioTurnoColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProgress(context),
                  const SizedBox(height: 20),
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildSelectores(context, operadorNombre),
                  if (!isApertura) ...[
                    const SizedBox(height: 24),
                    _buildFotoResguardo(context),
                  ],
                  const SizedBox(height: 20),
                  _buildInfoBox(context),
                ],
              ),
            ),
          ),
          _buildSiguienteButton(context),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final isApertura = widget.checklistType == ChecklistType.apertura;
    final stepLabel = isApertura ? 'Inicio de Turno' : 'Cierre de Turno';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Paso 1 de 8',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: InicioTurnoColors.textSecondary(context),
                  ),
            ),
            Text(
              stepLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: InicioTurnoColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 1 / 8,
            backgroundColor: InicioTurnoColors.progressUnfilled(context),
            valueColor: const AlwaysStoppedAnimation<Color>(InicioTurnoColors.progressFilled),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha: ${formatearFechaHoraActual()}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: InicioTurnoColors.textPrimary(context),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _cargandoUbicacion
              ? 'Lugar: Obteniendo ubicación...'
              : 'Lugar: ${_ubicacionDisplayName ?? 'No disponible'}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: InicioTurnoColors.textPrimary(context),
              ),
        ),
        const SizedBox(height: 16),
        Divider(color: InicioTurnoColors.divider(context), height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildFotoResguardo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: InicioTurnoColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foto de resguardo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: InicioTurnoColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          DashedBorderBox(
            height: 220,
            child: Material(
              color: InicioTurnoColors.progressUnfilled(context),
              child: InkWell(
                onTap: _tomarFotoResguardo,
                child: _fotoResguardo != null
                    ? Image.memory(
                        _fotoResguardo!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              color: InicioTurnoColors.placeholder(context),
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Foto Resguardo',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: InicioTurnoColors.placeholder(context),
                                  ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Asegúrate que la imagen sea clara y legible',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: InicioTurnoColors.textSecondary(context),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectores(BuildContext context, String operadorNombre) {
    final isApertura = widget.checklistType == ChecklistType.apertura;
    final placaRegistrada = _placaValidarResult?.registered == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: InicioTurnoColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectorLabel(icon: Icons.directions_car_outlined, label: 'Seleccionar Vehículo'),
          const SizedBox(height: 8),
          _VehiculoSelector(
            vehiculoSeleccionado: _vehiculoSeleccionado,
            onTap: isApertura ? _abrirIdentificarPlaca : () {},
            placaRegistrada: placaRegistrada,
            validandoPlaca: _validandoPlaca,
            placaSubtitle: _placaValidarResult == null
                ? null
                : _placaValidarResult!.registered
                    ? 'Placa registrada${(_placaValidarResult!.marca != null || _placaValidarResult!.modelo != null || _placaValidarResult!.anio != null) ? ': ${[ _placaValidarResult!.marca, _placaValidarResult!.modelo, _placaValidarResult!.anio?.toString() ].whereType<String>().where((e) => e.isNotEmpty).join(' ')}' : ''}'
                    : 'Placa no registrada',
            placaSubtitleRegistered: _placaValidarResult?.registered ?? false,
          ),
          const SizedBox(height: 20),
          _SelectorLabel(icon: Icons.person_outline, label: 'Operador'),
          const SizedBox(height: 8),
          _OperadorDisplay(operadorNombre: operadorNombre, placaRegistrada: placaRegistrada),
        ],
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InicioTurnoColors.infoBoxBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: InicioTurnoColors.infoIcon.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.info_outline, color: InicioTurnoColors.infoIcon, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.checklistType == ChecklistType.cierre
                  ? 'Asegúrese de verificar que la fotografía de resguardo sea clara y legible con el vehículo antes de continuar.'
                  : 'Asegúrese de verificar que la placa del vehículo coincida físicamente con la unidad antes de continuar.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: InicioTurnoColors.textSecondary(context),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiguienteButton(BuildContext context) {
    final isApertura = widget.checklistType == ChecklistType.apertura;
    final canContinue = isApertura
        ? (_placaValidarResult != null && _placaValidarResult!.registered)
        : (_fotoResguardo != null && _fotoResguardo!.isNotEmpty);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (canContinue && !_creandoTurno)
                ? () {
                    if (widget.checklistType == ChecklistType.apertura) {
                      _crearTurnoYContinuar();
                    } else {
                      _cerrarTurnoYContinuar();
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canContinue ? const Color(0xFF001C6A) : InicioTurnoColors.textSecondary(context),
              foregroundColor: Colors.white,
              disabledBackgroundColor: InicioTurnoColors.textSecondary(context),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _creandoTurno
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isApertura ? 'Creando turno...' : 'Cerrando turno...',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continuar',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SelectorLabel extends StatelessWidget {
  const _SelectorLabel({required this.icon, required this.label, this.iconColor});

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? InicioTurnoColors.accent;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: InicioTurnoColors.textPrimary(context),
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _VehiculoSelector extends StatelessWidget {
  const _VehiculoSelector({
    required this.vehiculoSeleccionado,
    required this.onTap,
    this.placaRegistrada = false,
    this.validandoPlaca = false,
    this.placaSubtitle,
    this.placaSubtitleRegistered = false,
  });

  final String? vehiculoSeleccionado;
  final VoidCallback onTap;
  final bool placaRegistrada;
  final bool validandoPlaca;
  final String? placaSubtitle;
  final bool placaSubtitleRegistered;

  @override
  Widget build(BuildContext context) {
    final leftIconColor = vehiculoSeleccionado != null
        ? InicioTurnoColors.accent
        : InicioTurnoColors.placeholder(context);
    final rightIconColor = vehiculoSeleccionado != null
        ? (placaRegistrada ? CapturaOdometroColors.ocrPillForeground(context) : InicioTurnoColors.accent)
        : InicioTurnoColors.placeholder(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: InicioTurnoColors.inputBackground(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt_outlined, color: leftIconColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    vehiculoSeleccionado ?? 'Tomar foto de la placa del vehículo',
                    style: TextStyle(
                      color: vehiculoSeleccionado != null
                          ? InicioTurnoColors.textPrimary(context)
                          : InicioTurnoColors.placeholder(context),
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(Icons.camera_alt_outlined, color: rightIconColor, size: 24),
              ],
            ),
            if (validandoPlaca) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: InicioTurnoColors.textSecondary(context))),
                  const SizedBox(width: 8),
                  Text(
                    'Validando placa...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: InicioTurnoColors.textSecondary(context)),
                  ),
                ],
              ),
            ] else if (placaSubtitle != null && placaSubtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Text(
                  placaSubtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: placaSubtitleRegistered ? CapturaOdometroColors.ocrPillForeground(context) : InicioTurnoColors.textSecondary(context),
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OperadorDisplay extends StatelessWidget {
  const _OperadorDisplay({required this.operadorNombre, this.placaRegistrada = false});

  final String operadorNombre;
  final bool placaRegistrada;

  @override
  Widget build(BuildContext context) {
    final checkColor = placaRegistrada ? CapturaOdometroColors.ocrPillForeground(context) : InicioTurnoColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: InicioTurnoColors.inputBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: InicioTurnoColors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              operadorNombre,
              style: TextStyle(
                color: InicioTurnoColors.textPrimary(context),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.check_circle, color: checkColor, size: 22),
        ],
      ),
    );
  }
}
