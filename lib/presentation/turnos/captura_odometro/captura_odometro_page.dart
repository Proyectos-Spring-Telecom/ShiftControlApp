import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../widgets/app_alert_banner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../checklist_apertura_navigation.dart';
import '../checklist_progress_provider.dart';
import '../mi_turno_provider.dart';
import '../models/checklist_type.dart';
import '../turno_apertura_provider.dart';
import '../turno_bitacora_helper.dart';
import 'captura_odometro_colors.dart';
import 'dashed_border_box.dart';
import '../registro_combustible/registro_combustible_colors.dart';
import '../registro_combustible/registro_combustible_page.dart';

class CapturaOdometroPage extends ConsumerStatefulWidget {
  const CapturaOdometroPage({
    super.key,
    this.onSiguienteTap,
    this.checklistType = ChecklistType.apertura,
    this.placa,
    this.marca,
    this.modelo,
    this.anio,
    this.economico,
  });

  final VoidCallback? onSiguienteTap;
  final ChecklistType checklistType;
  /// Datos del vehículo desde [turnoAperturaProvider], hidratado desde SharedPreferences.
  final String? placa;
  final String? marca;
  final String? modelo;
  final int? anio;
  final String? economico;

  @override
  ConsumerState<CapturaOdometroPage> createState() => _CapturaOdometroPageState();
}

class _CapturaOdometroPageState extends ConsumerState<CapturaOdometroPage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _fotoTablero;
  String _kilometraje = '';
  bool _guardandoTablero = false;

  bool get _kilometrajeEnteroValido {
    final valor = _kilometraje.trim();
    if (valor.isEmpty) return false;
    return int.tryParse(valor) != null;
  }

  bool get _puedeContinuar {
    if (_guardandoTablero) return false;
    return _fotoTablero != null &&
        _fotoTablero!.isNotEmpty &&
        _kilometrajeEnteroValido;
  }

  @override
  void initState() {
    super.initState();
    if (widget.checklistType == ChecklistType.apertura ||
        widget.checklistType == ChecklistType.cierre) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hidratarDatosVehiculoDesdePersistencia();
        ref
            .read(checklistProgressServiceProvider)
            .actualizarPaso(ChecklistAperturaPasos.capturaOdometro);
      });
    }
  }

  void _hidratarDatosVehiculoDesdePersistencia() {
    final actual = ref.read(turnoAperturaProvider);
    if (actual.placa != null && actual.placa!.isNotEmpty) return;

    final datos = ref.read(checklistProgressServiceProvider).leerDatosVehiculo();
    if (datos == null) return;

    final idTurno = actual.idTurno ??
        ref.read(checklistProgressServiceProvider).leerProgreso()?.idTurno;

    ref.read(turnoAperturaProvider.notifier).state = TurnoAperturaState(
      idTurno: idTurno,
      idBitacoraApertura: actual.idBitacoraApertura,
      placa: datos.placa,
      numeroEconomico: datos.numeroEconomico,
      modeloNombre: datos.modeloNombre,
      marcaNombre: datos.marcaNombre,
      anio: datos.anio,
    );
  }

  Future<void> _tomarFotoTablero() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      final bytes = await photo.readAsBytes();
      if (mounted) setState(() => _fotoTablero = bytes);
    }
  }

  Future<void> _continuar() async {
    if (_fotoTablero == null || _fotoTablero!.isEmpty) {
      showAppAlertError(context, message: 'Toma la foto del tablero antes de continuar.');
      return;
    }

    if (_kilometraje.trim().isEmpty || !_kilometrajeEnteroValido) {
      showAppAlertError(context, message: 'Ingrese el kilometraje antes de continuar.');
      return;
    }

    final idBitacora =
        idBitacoraVehiculoParaChecklist(ref, widget.checklistType);
    if (idBitacora == null) {
      showAppAlertError(context, message: mensajeBitacoraFaltante(widget.checklistType));
      return;
    }

    setState(() => _guardandoTablero = true);

    try {
      await ref.read(turnosServiceProvider).registrarTablero(
            idBitacoraVehiculo: idBitacora,
            kilometraje: _kilometraje.trim(),
            fotoTableroBytes: _fotoTablero!,
          );

      if (!mounted) return;
      setState(() => _guardandoTablero = false);
      _navegarSiguiente();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _guardandoTablero = false);
      showAppAlertError(context, message: e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _guardandoTablero = false);
      showAppAlertError(context, message: e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardandoTablero = false);
      showAppAlertError(context, message: 'Error al registrar tablero: $e');
    }
  }

  void _navegarSiguiente() {
    if (widget.onSiguienteTap != null) {
      widget.onSiguienteTap!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const RegistroCombustiblePage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApertura = widget.checklistType == ChecklistType.apertura;
    final pageTitle = isApertura ? 'Apertura de Turno' : 'Cierre de Turno';
    
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: CapturaOdometroColors.background(context),
      appBar: AppBar(
        backgroundColor: CapturaOdometroColors.background(context),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const SizedBox.shrink(),
        leadingWidth: AppConstants.appBarLeadingWidthWithoutBack,
        titleSpacing: 0,
        centerTitle: true,
        title: Text(
          pageTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: CapturaOdometroColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgress(context),
                  const SizedBox(height: 20),
                  Consumer(
                    builder: (context, ref, _) {
                      final turno = ref.watch(turnoAperturaProvider);
                      return _buildVehicleCard(context, turno);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildFotoTablero(context, _fotoTablero, _tomarFotoTablero),
                  const SizedBox(height: 24),
                  _buildKilometraje(context),
                ],
              ),
            ),
          ),
          _buildSiguienteButton(context),
        ],
      ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Paso 2 de 8',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CapturaOdometroColors.textSecondary(context),
                  ),
            ),
            Text(
              'Captura de Odómetro',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CapturaOdometroColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 2 / 4,
            backgroundColor: CapturaOdometroColors.progressUnfilled(context),
            valueColor: const AlwaysStoppedAnimation<Color>(CapturaOdometroColors.progressFilled),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard(
    BuildContext context,
    TurnoAperturaState turno,
  ) {
    final placa = turno.placa ?? '—';
    final marcaModelo = _formatMarcaModelo(turno.marcaNombre, turno.modeloNombre);
    final anio = turno.anio?.toString() ?? '—';
    final economico = turno.numeroEconomico != null && turno.numeroEconomico!.isNotEmpty
        ? '#${turno.numeroEconomico}'
        : '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CapturaOdometroColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildT804Pill(context, 'Placa: $placa'),
                    const SizedBox(height: 4),
                    Text(
                      marcaModelo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: CapturaOdometroColors.textPrimary(context),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Económico: $economico',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CapturaOdometroColors.textPrimary(context),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Año: $anio',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CapturaOdometroColors.textPrimary(context),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatMarcaModelo(String? marca, String? modelo) {
    final m = marca ?? '';
    final mod = modelo ?? '';
    if (m.isEmpty && mod.isEmpty) return '—';
    if (m.isEmpty) return mod;
    if (mod.isEmpty) return m;
    return '$m $mod';
  }

  Widget _buildT804Pill(BuildContext context, String placa) {
    return Container(
      padding: const EdgeInsets.only(left: 0, right: 14, top: 3, bottom: 3),
      decoration: BoxDecoration(
        color: CapturaOdometroColors.pillT804Background(context),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        placa,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: CapturaOdometroColors.pillT804Text(context),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildPill(BuildContext context, String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: CapturaOdometroColors.textPrimary(context),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFotoTablero(BuildContext context, Uint8List? foto, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CapturaOdometroColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Foto del tablero',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: CapturaOdometroColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          DashedBorderBox(
            child: Material(
              color: CapturaOdometroColors.progressUnfilled(context),
              child: InkWell(
                onTap: onTap,
                child: foto != null
                    ? Image.memory(
                        foto,
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
                              color: CapturaOdometroColors.photoIconLabel(context),
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Foto Tablero',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: CapturaOdometroColors.photoIconLabel(context),
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
              'Asegúrate que los números sean legibles',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CapturaOdometroColors.textSecondary(context),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKilometraje(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CapturaOdometroColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. Kilometraje detectado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: CapturaOdometroColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
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
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: !_guardandoTablero,
                    style: TextStyle(
                      color: RegistroCombustibleColors.textPrimary(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ingrese el kilometraje',
                      hintStyle: TextStyle(
                        color: RegistroCombustibleColors.textSecondary(context),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      isDense: true,
                      filled: true,
                      fillColor: RegistroCombustibleColors.inputBackground(context),
                    ),
                    onChanged: (value) => setState(() => _kilometraje = value),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'KM',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: RegistroCombustibleColors.textSecondary(context),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiguienteButton(BuildContext context) {
    final puedeContinuar = _puedeContinuar;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: puedeContinuar ? _continuar : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: puedeContinuar
                  ? const Color(0xFF001C6A)
                  : CapturaOdometroColors.textSecondary(context),
              foregroundColor: Colors.white,
              disabledBackgroundColor: CapturaOdometroColors.textSecondary(context),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _guardandoTablero
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
                        'Guardando...',
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
