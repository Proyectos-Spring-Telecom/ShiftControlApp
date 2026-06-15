import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../widgets/app_alert_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../checklist_progress_provider.dart';
import '../mi_turno_provider.dart';
import '../turno_apertura_provider.dart';
import 'registro_combustible_colors.dart';
import 'registro_combustible_provider.dart';
import '../captura_odometro/dashed_border_box.dart';

class RegistroCombustiblePage extends ConsumerStatefulWidget {
  const RegistroCombustiblePage({super.key});

  @override
  ConsumerState<RegistroCombustiblePage> createState() =>
      _RegistroCombustiblePageState();
}

class _RegistroCombustiblePageState extends ConsumerState<RegistroCombustiblePage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _fotoBomba;
  Uint8List? _fotoTablero;
  Position? _cachedPosition;
  bool _guardando = false;

  late final TextEditingController _litrosController;
  late final TextEditingController _totalController;
  late final TextEditingController _kilometrajeController;

  bool get _puedeGuardar {
    if (_guardando) return false;
    if (_obtenerIdTurno() == null) return false;
    if (_cachedPosition == null) return false;
    if (_fotoTablero == null || _fotoTablero!.isEmpty) return false;
    if (_fotoBomba == null || _fotoBomba!.isEmpty) return false;

    final litrosCargados = _parseDecimal(_litrosController.text);
    if (litrosCargados == null || litrosCargados < 0.001) return false;

    final totalPagado = _parseDecimal(_totalController.text);
    if (totalPagado == null || totalPagado < 0) return false;

    final kilometraje = _parseDecimal(_kilometrajeController.text);
    if (kilometraje == null || kilometraje <= 0) return false;

    return true;
  }

  @override
  void initState() {
    super.initState();
    _litrosController = TextEditingController();
    _totalController = TextEditingController();
    _kilometrajeController = TextEditingController();
    _litrosController.addListener(_onFormChanged);
    _totalController.addListener(_onFormChanged);
    _kilometrajeController.addListener(_onFormChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miTurnoActivoProvider.notifier).fetch();
      _inicializarUbicacion();
    });
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _inicializarUbicacion() async {
    final position = await _obtenerUbicacion();
    if (position != null && mounted) {
      setState(() => _cachedPosition = position);
    }
  }

  @override
  void dispose() {
    _litrosController.removeListener(_onFormChanged);
    _totalController.removeListener(_onFormChanged);
    _kilometrajeController.removeListener(_onFormChanged);
    _litrosController.dispose();
    _totalController.dispose();
    _kilometrajeController.dispose();
    super.dispose();
  }

  Future<void> _tomarFotoBomba() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      final bytes = await photo.readAsBytes();
      if (mounted) setState(() => _fotoBomba = bytes);
    }
  }

  Future<void> _tomarFotoTablero() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      final bytes = await photo.readAsBytes();
      if (mounted) setState(() => _fotoTablero = bytes);
    }
  }

  int? _obtenerIdTurno() {
    final miTurno = ref.read(miTurnoActivoProvider).valueOrNull;
    if (miTurno?.idTurno != null) return miTurno!.idTurno;

    final desdeApertura = ref.read(turnoAperturaProvider).idTurno;
    if (desdeApertura != null) return desdeApertura;

    return ref.read(checklistProgressServiceProvider).leerProgreso()?.idTurno;
  }

  Future<Position?> _obtenerUbicacion() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            showAppAlertError(context, message: 'Se necesita permiso de ubicación para registrar combustible.');
          }
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showAppAlertError(context, message: 'Permisos de ubicación denegados permanentemente. Actívalos en Configuración.');
        }
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      if (mounted) {
        showAppAlertError(context, message: 'No se pudo obtener la ubicación: $e');
      }
      return null;
    }
  }

  double? _parseDecimal(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  Future<void> _guardarRegistro() async {
    if (_fotoTablero == null || _fotoTablero!.isEmpty) {
      showAppAlertError(context, message: 'Debe adjuntar la imagen fotoTableroAntes.');
      return;
    }

    if (_fotoBomba == null || _fotoBomba!.isEmpty) {
      showAppAlertError(context, message: 'Debe adjuntar la imagen fotoBomba.');
      return;
    }

    final litrosCargados = _parseDecimal(_litrosController.text);
    if (litrosCargados == null || litrosCargados < 0.001) {
      showAppAlertError(context, message: 'Los litros cargados deben ser al menos 0.001.');
      return;
    }

    final totalPagado = _parseDecimal(_totalController.text);
    if (totalPagado == null || totalPagado < 0) {
      showAppAlertError(context, message: 'El total pagado debe ser mayor o igual a 0.');
      return;
    }

    final kilometraje = _parseDecimal(_kilometrajeController.text);
    if (kilometraje == null) {
      showAppAlertError(context, message: 'Ingresa el kilometraje actual antes de guardar.');
      return;
    }

    final idTurno = _obtenerIdTurno();
    if (idTurno == null) {
      showAppAlertError(context, message: 'No hay turno activo. Inicia un turno para continuar.');
      return;
    }

    setState(() => _guardando = true);

    final position = await _obtenerUbicacion();
    if (position == null) {
      if (mounted) setState(() => _guardando = false);
      return;
    }

    try {
      final response = await ref.read(turnosServiceProvider).registrarIncidenciaGasolina(
            idTurno: idTurno,
            latitud: position.latitude,
            longitud: position.longitude,
            kilometraje: kilometraje,
            litrosCargados: litrosCargados,
            totalPagado: totalPagado,
            fotoTableroAntesBytes: _fotoTablero!,
            fotoBombaBytes: _fotoBomba!,
          );

      if (!mounted) return;
      setState(() => _guardando = false);

      if (response.id != null) {
        ref.read(registroCombustibleProvider.notifier).state = response.id;
      }

      showAppAlertSuccess(context, message: response.message ?? 'Incidencia de gasolina registrada correctamente');
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      showAppAlertError(context, message: e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      showAppAlertError(context, message: e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      showAppAlertError(context, message: 'No fue posible registrar la incidencia: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(miTurnoActivoProvider);
    ref.watch(turnoAperturaProvider);
    return Scaffold(
      backgroundColor: RegistroCombustibleColors.background(context),
      appBar: AppBar(
        backgroundColor: RegistroCombustibleColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: RegistroCombustibleColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Registro de Combustible',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: RegistroCombustibleColors.textPrimary(context),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoBox(context),
                  const SizedBox(height: 20),
                  _buildEvidenciaCarga(context, _fotoBomba, _fotoTablero, _tomarFotoBomba, _tomarFotoTablero),
                  const SizedBox(height: 24),
                  _buildDatosOcr(context),
                  const SizedBox(height: 20),
                  _buildWarningBox(context),
                ],
              ),
            ),
          ),
          _buildGuardarButton(context),
        ],
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RegistroCombustibleColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RegistroCombustibleColors.infoIcon(context).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_gas_station,
              color: RegistroCombustibleColors.infoIcon(context),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Registre la evidencia fotográfica de la carga de combustible realizada.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: RegistroCombustibleColors.textSecondary(context),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenciaCarga(
    BuildContext context,
    Uint8List? fotoBomba,
    Uint8List? fotoTablero,
    VoidCallback onTapBomba,
    VoidCallback onTapTablero,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RegistroCombustibleColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: RegistroCombustibleColors.textPrimary(context), size: 22),
              const SizedBox(width: 8),
              Text(
                'Evidencia de Carga',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: RegistroCombustibleColors.textPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FotoCard(
                  icon: Icons.local_gas_station_outlined,
                  label: 'Foto Bomba',
                  image: fotoBomba,
                  onTap: onTapBomba,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FotoCard(
                  icon: Icons.speed_outlined,
                  label: 'Foto Tablero',
                  image: fotoTablero,
                  onTap: onTapTablero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Tome una foto clara de la pantalla de la bomba y del tablero del vehículo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: RegistroCombustibleColors.textSecondary(context),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatosOcr(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RegistroCombustibleColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: RegistroCombustibleColors.textPrimary(context), size: 22),
              const SizedBox(width: 8),
              Text(
                'Datos detectados',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: RegistroCombustibleColors.textPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOcrField(
            context,
            'Litros cargados',
            _litrosController,
            'LTS',
            hint: 'Ej: 45.50',
          ),
          const SizedBox(height: 12),
          _buildOcrField(
            context,
            'Total pagado',
            _totalController,
            'MXN',
            hint: 'Ej: 1092.00',
          ),
          const SizedBox(height: 12),
          _buildOcrField(
            context,
            'Kilometraje actual',
            _kilometrajeController,
            'KM',
            hint: 'Ej: 154032',
          ),
        ],
      ),
    );
  }

  Widget _buildOcrField(
    BuildContext context,
    String label,
    TextEditingController controller,
    String suffix, {
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: RegistroCombustibleColors.textPrimary(context),
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: RegistroCombustibleColors.inputBackground(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !_guardando,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: RegistroCombustibleColors.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: RegistroCombustibleColors.textSecondary(context)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                    filled: true,
                    fillColor: RegistroCombustibleColors.inputBackground(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                suffix,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: RegistroCombustibleColors.textSecondary(context),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RegistroCombustibleColors.warningBoxBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RegistroCombustibleColors.warningIconAndText.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: RegistroCombustibleColors.warningIconAndText,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Verifique que los datos coincidan con la evidencia de carga antes de continuar.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: RegistroCombustibleColors.warningIconAndText,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardarButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _puedeGuardar ? _guardarRegistro : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: RegistroCombustibleColors.buttonSiguiente,
              foregroundColor: Colors.white,
              disabledBackgroundColor: RegistroCombustibleColors.textSecondary(context),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _guardando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Guardar Registro',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _FotoCard extends StatelessWidget {
  const _FotoCard({
    required this.icon,
    required this.label,
    this.image,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Uint8List? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DashedBorderBox(
      child: Material(
        color: RegistroCombustibleColors.progressUnfilled(context),
        child: InkWell(
          onTap: onTap,
          child: image != null
              ? Image.memory(
                  image!,
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
                        icon,
                        color: RegistroCombustibleColors.photoIconLabel(context),
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: RegistroCombustibleColors.photoIconLabel(context),
                            ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
