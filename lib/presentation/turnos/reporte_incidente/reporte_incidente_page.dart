import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../checklist_progress_provider.dart';
import '../mi_turno_provider.dart';
import '../turno_apertura_provider.dart';
import '../captura_odometro/dashed_border_box.dart';
import 'models/tipo_incidencia.dart';
import 'reporte_incidente_colors.dart';
import 'reporte_incidente_provider.dart';

class ReporteIncidentePage extends ConsumerStatefulWidget {
  const ReporteIncidentePage({super.key});

  @override
  ConsumerState<ReporteIncidentePage> createState() => _ReporteIncidentePageState();
}

class _ReporteIncidentePageState extends ConsumerState<ReporteIncidentePage> {
  static const int _maxFotoBytes = 10 * 1024 * 1024;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descripcionController = TextEditingController();
  int? _idTipoIncidenciaSeleccionado = tipoIncidenciaAccidente.id;
  String? _tipoIncidenciaSeleccionada = tipoIncidenciaAccidente.nombre;
  final List<Uint8List> _fotos = [];
  bool _enviando = false;

  bool get _puedeEnviar =>
      !_enviando &&
      _idTipoIncidenciaSeleccionado != null &&
      _descripcionController.text.trim().isNotEmpty &&
      _fotos.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sincronizarSeleccionEnProvider();
      ref.read(miTurnoActivoProvider.notifier).fetch();
    });
  }

  void _seleccionarTipo(TipoIncidencia tipo) {
    setState(() {
      _idTipoIncidenciaSeleccionado = tipo.id;
      _tipoIncidenciaSeleccionada = tipo.nombre;
    });
    _sincronizarSeleccionEnProvider();
  }

  void _sincronizarSeleccionEnProvider() {
    ref.read(reporteIncidenteSeleccionProvider.notifier).state =
        ReporteIncidenteSeleccionState(
      idTipoIncidencia: _idTipoIncidenciaSeleccionado,
      tipoIncidencia: _tipoIncidenciaSeleccionada,
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _agregarFoto() async {
    if (_fotos.length >= 3 || _enviando) return;
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      final bytes = await photo.readAsBytes();
      if (bytes.length > _maxFotoBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La imagen no debe superar 10 MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (mounted) setState(() => _fotos.add(bytes));
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Se necesita permiso de ubicación para reportar la incidencia.',
                ),
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
          SnackBar(
            content: Text('No se pudo obtener la ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _enviarReporte() async {
    if (!_puedeEnviar) return;

    final descripcion = _descripcionController.text.trim();
    if (descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa la descripción del incidente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_fotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe adjuntar la imagen fotoEvidencia1.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (final foto in _fotos) {
      if (foto.length > _maxFotoBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cada imagen no debe superar 10 MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final idTurno = _obtenerIdTurno();
    if (idTurno == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay turno activo. Inicia un turno para continuar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    final position = await _obtenerUbicacion();
    if (position == null) {
      if (mounted) setState(() => _enviando = false);
      return;
    }

    final idCatTipoIncidente = _idTipoIncidenciaSeleccionado ?? 1;

    try {
      final response = await ref.read(turnosServiceProvider).registrarIncidencia(
            idTurno: idTurno,
            descripcion: descripcion,
            latitud: position.latitude,
            longitud: position.longitude,
            idCatTipoIncidente: idCatTipoIncidente,
            fotoEvidencia1Bytes: _fotos[0],
            fotoEvidencia2Bytes: _fotos.length > 1 ? _fotos[1] : null,
            fotoEvidencia3Bytes: _fotos.length > 2 ? _fotos[2] : null,
          );

      if (!mounted) return;
      setState(() => _enviando = false);

      if (response.id != null) {
        ref.read(reporteIncidenteRegistradaProvider.notifier).state = response.id;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ?? 'Incidencia registrada correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No fue posible registrar la incidencia: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _eliminarFoto(int index) {
    setState(() => _fotos.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReporteIncidenteColors.background(context),
      appBar: AppBar(
        backgroundColor: ReporteIncidenteColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ReporteIncidenteColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          'Reportar Incidente',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: ReporteIncidenteColors.textPrimary(context),
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
                  _buildUbicacionCard(context),
                  const SizedBox(height: 24),
                  _buildSectionLabel(context, 'Tipo de incidente'),
                  const SizedBox(height: 12),
                  _buildTipoIncidenteGrid(context),
                  const SizedBox(height: 24),
                  _buildSectionLabel(context, 'Descripción del incidente'),
                  const SizedBox(height: 12),
                  _buildDescripcionInput(context),
                  const SizedBox(height: 24),
                  _buildEvidenciaHeader(context),
                  const SizedBox(height: 12),
                  _buildEvidenciaFotos(context),
                ],
              ),
            ),
          ),
          _buildEnviarButton(context),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: ReporteIncidenteColors.sectionHeading(context),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
    );
  }

  Widget _buildUbicacionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReporteIncidenteColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ReporteIncidenteColors.iconBlue(context).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.my_location,
              color: ReporteIncidenteColors.iconBlue(context),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubicación Actual',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ReporteIncidenteColors.textSecondary(context),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Av. San Cristobal 123, Cuernavaca, Mor.',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ReporteIncidenteColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: ReporteIncidenteColors.divider(context),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Hora',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ReporteIncidenteColors.textSecondary(context),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '14:32',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ReporteIncidenteColors.textPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipoIncidenteGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TipoIncidenteCard(
                icon: iconoTipoIncidencia(tipoIncidenciaAccidente.id),
                label: tipoIncidenciaAccidente.nombre,
                isSelected: _idTipoIncidenciaSeleccionado == tipoIncidenciaAccidente.id,
                onTap: () => _seleccionarTipo(tipoIncidenciaAccidente),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TipoIncidenteCard(
                icon: iconoTipoIncidencia(tipoIncidenciaFallaMecanica.id),
                label: tipoIncidenciaFallaMecanica.nombre,
                isSelected:
                    _idTipoIncidenciaSeleccionado == tipoIncidenciaFallaMecanica.id,
                onTap: () => _seleccionarTipo(tipoIncidenciaFallaMecanica),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TipoIncidenteCard(
                icon: iconoTipoIncidencia(tipoIncidenciaDanoExterior.id),
                label: tipoIncidenciaDanoExterior.nombre,
                isSelected:
                    _idTipoIncidenciaSeleccionado == tipoIncidenciaDanoExterior.id,
                onTap: () => _seleccionarTipo(tipoIncidenciaDanoExterior),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TipoIncidenteCard(
                icon: iconoTipoIncidencia(tipoIncidenciaOtro.id),
                label: tipoIncidenciaOtro.nombre,
                isSelected: _idTipoIncidenciaSeleccionado == tipoIncidenciaOtro.id,
                onTap: () => _seleccionarTipo(tipoIncidenciaOtro),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescripcionInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReporteIncidenteColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _descripcionController,
            enabled: !_enviando,
            maxLines: 4,
            maxLength: 500,
            style: TextStyle(color: ReporteIncidenteColors.textPrimary(context), fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Describa brevemente qué sucedió...',
              hintStyle: TextStyle(color: ReporteIncidenteColors.textSecondary(context), fontSize: 15),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              counterText: '',
              filled: true,
              fillColor: ReporteIncidenteColors.cardBackground(context),
            ),
            onChanged: (_) => setState(() {}),
          ),
          Text(
            '${_descripcionController.text.length}/500',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ReporteIncidenteColors.textSecondary(context),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenciaHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionLabel(context, 'Evidencia fotográfica'),
        Text(
          'Mínimo 2 fotos',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ReporteIncidenteColors.textSecondary(context),
              ),
        ),
      ],
    );
  }

  Widget _buildEvidenciaFotos(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < _fotos.length; i++) ...[
          Expanded(child: _buildFotoItem(context, i)),
          if (i < 2) const SizedBox(width: 12),
        ],
        for (int i = _fotos.length; i < 3; i++) ...[
          Expanded(child: _buildFotoVacia(context)),
          if (i < 2) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildFotoItem(BuildContext context, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _fotos[index],
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _eliminarFoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFotoVacia(BuildContext context) {
    return GestureDetector(
      onTap: _agregarFoto,
      child: DashedBorderBox(
        height: 100,
        child: Container(
          color: ReporteIncidenteColors.cardBackground(context),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: ReporteIncidenteColors.textSecondary(context),
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                'Vacío',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ReporteIncidenteColors.textSecondary(context),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnviarButton(BuildContext context) {
    final puedeEnviar = _puedeEnviar;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: puedeEnviar ? _enviarReporte : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ReporteIncidenteColors.buttonPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  ReporteIncidenteColors.buttonPrimary.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _enviando
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
                      Text(
                        'Enviar Reporte',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.send, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _TipoIncidenteCard extends StatelessWidget {
  const _TipoIncidenteCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? ReporteIncidenteColors.selectedBackground(context)
              : ReporteIncidenteColors.cardBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: ReporteIncidenteColors.selectedBorder, width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? ReporteIncidenteColors.pillForeground
                      : ReporteIncidenteColors.textSecondary(context),
                  size: 32,
                ),
                if (showBadge && isSelected)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ReporteIncidenteColors.pillBackground(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: ReporteIncidenteColors.pillForeground,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.priority_high,
                            color: ReporteIncidenteColors.pillForeground,
                            size: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? ReporteIncidenteColors.textPrimary(context)
                        : ReporteIncidenteColors.textSecondary(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
