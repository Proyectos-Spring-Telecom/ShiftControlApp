import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../models/checklist_type.dart';
import 'inicio_turno_colors.dart';
import '../captura_odometro/captura_odometro_page.dart';
import '../captura_odometro/dashed_border_box.dart';
import '../escanear_vehiculo/escanear_vehiculo_page.dart';
import '../identificar_placa/identificar_placa_page.dart';

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
    if (widget.onEscanearVehiculoTap != null) {
      widget.onEscanearVehiculoTap!();
    } else {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => IdentificarPlacaPage(
            onPlacaIdentificada: (vehiculoId) {
              setState(() => _vehiculoSeleccionado = vehiculoId);
              Navigator.of(context).pop();
            },
            onRegresar: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final operadorNombre = user?.email ?? 'Operador';
    final isApertura = widget.checklistType == ChecklistType.apertura;
    final pageTitle = isApertura ? 'Inicio de Turno' : 'Cierre de Turno';

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
                  const SizedBox(height: 28),
                  _buildAsignacionRequerida(context),
                  if (!isApertura) ...[
                    const SizedBox(height: 24),
                    _buildFotoResguardo(context),
                  ],
                  const SizedBox(height: 24),
                  _buildSelectores(context, operadorNombre),
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
              'Fecha: Vie 02 de Ene 2026',
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

  Widget _buildAsignacionRequerida(BuildContext context) {
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
            'Asignación Requerida',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: InicioTurnoColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escanea el vehículo para iniciar la apertura de turno.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: InicioTurnoColors.textPrimary(context),
                ),
          ),
        ],
      ),
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
            onTap: _abrirIdentificarPlaca,
          ),
          const SizedBox(height: 20),
          _SelectorLabel(icon: Icons.person_outline, label: 'Operador'),
          const SizedBox(height: 8),
          _OperadorDisplay(operadorNombre: operadorNombre),
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
              'Asegúrese de verificar que el número económico coincida físicamente con la unidad antes de continuar.',
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (widget.onSiguienteTap != null) {
                widget.onSiguienteTap!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CapturaOdometroPage(),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001C6A),
              foregroundColor: Colors.white,
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
  const _SelectorLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: InicioTurnoColors.accent, size: 20),
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
  });

  final String? vehiculoSeleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: InicioTurnoColors.inputBackground(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: vehiculoSeleccionado != null
                  ? InicioTurnoColors.accent
                  : InicioTurnoColors.placeholder(context),
              size: 22,
            ),
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
            Icon(
              Icons.camera_alt_outlined,
              color: InicioTurnoColors.placeholder(context),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _OperadorDisplay extends StatelessWidget {
  const _OperadorDisplay({required this.operadorNombre});

  final String operadorNombre;

  @override
  Widget build(BuildContext context) {
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
          Icon(Icons.check_circle, color: InicioTurnoColors.accent, size: 22),
        ],
      ),
    );
  }
}
