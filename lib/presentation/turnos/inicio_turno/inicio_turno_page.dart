import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../../data/datasources/remote/face_auth_remote_datasource.dart';
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
import '../placa_validada_provider.dart';

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
  final ImagePicker _picker = ImagePicker();
  bool _validandoPlaca = false;
  PlacasValidarResult? _placaValidarResult;

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
          onPlacaIdentificada: (vehiculoId) {
            ref.read(placaValidadaProvider.notifier).state = null;
            setState(() {
              _vehiculoSeleccionado = vehiculoId;
              _placaValidarResult = null;
            });
            Navigator.of(context).pop();
            if (vehiculoId.isNotEmpty) _validarPlaca(vehiculoId);
          },
          onRegresar: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Llama a GET /placas/validar con numeroPlaca; idCliente e idSolucion vienen de GET /auth/me.
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
      final meResult = await ref.read(faceAuthRemoteDatasourceProvider).me(token);
      final idCliente = int.tryParse(meResult.idCliente);
      final idSolucion = meResult.idSolucion is int ? meResult.idSolucion as int : int.tryParse(meResult.idSolucion?.toString() ?? '');
      if (!mounted) return;
      final result = await ref.read(placasValidarRemoteDatasourceProvider).validar(
            token,
            numeroPlaca,
            idCliente: idCliente,
            idSolucion: idSolucion,
          );
      if (!mounted) return;
      ref.read(placaValidadaProvider.notifier).state = result;
      setState(() {
        _validandoPlaca = false;
        _placaValidarResult = result;
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
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: InicioTurnoColors.textPrimary(context),
                ),
            children: const [
              TextSpan(
                text: 'Folio: ',
                style: TextStyle(color: InicioTurnoColors.accent, fontWeight: FontWeight.w600),
              ),
              TextSpan(text: 'Pendiente'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fecha: ${formatearFechaHoraActual()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: InicioTurnoColors.textPrimary(context),
                  ),
            ),
            Text(
              'Lugar: Tlaxcala',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: InicioTurnoColors.textPrimary(context),
                  ),
            ),
          ],
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
    // En Apertura: habilitar solo cuando la placa esté registrada y tengamos datos del vehículo.
    final canContinue = !isApertura ||
        (_placaValidarResult != null && _placaValidarResult!.registered);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: canContinue
                ? () {
                    if (widget.onSiguienteTap != null) {
                      widget.onSiguienteTap!();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CapturaOdometroPage(),
                        ),
                      );
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continuar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
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
