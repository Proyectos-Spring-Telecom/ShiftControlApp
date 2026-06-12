import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/read_file_bytes_stub.dart'
    if (dart.library.io) '../../../../core/utils/read_file_bytes_io.dart' as file_reader;
import '../../captura_odometro/dashed_border_box.dart';
import '../../mi_turno_provider.dart';
import '../../models/checklist_type.dart';
import '../../turno_apertura_provider.dart';
import '../models/damage_point_model.dart';
import '../registro_danos_colors.dart';

/// Bottom sheet para registrar el detalle de un daño.
class DamageDetailSheet extends ConsumerStatefulWidget {
  const DamageDetailSheet({
    super.key,
    required this.point,
    required this.checklistType,
    required this.onSave,
  });

  final DamagePoint point;
  final ChecklistType checklistType;
  final void Function(DamageDetail detail) onSave;

  @override
  ConsumerState<DamageDetailSheet> createState() => _DamageDetailSheetState();
}

class _DamageDetailSheetState extends ConsumerState<DamageDetailSheet> {
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _parteAfectadaController;
  DamageType? _selectedType;
  DamageSeverity? _selectedSeverity;
  Uint8List? _photoBytes;
  String? _photoPathForSave;
  bool _guardando = false;

  static const Map<DamageType, IconData> _damageTypeIcons = {
    DamageType.rayon: Icons.gesture,
    DamageType.golpe: Icons.sports_mma_outlined,
    DamageType.abolladura: Icons.photo_library_outlined,
    DamageType.grieta: Icons.broken_image_outlined,
    DamageType.rotura: Icons.warning_amber_outlined,
    DamageType.raspon: Icons.texture_outlined,
    DamageType.corrosionOxido: Icons.water_drop_outlined,
    DamageType.pinturaDanada: Icons.format_paint_outlined,
    DamageType.faltante: Icons.remove_circle_outline,
    DamageType.estrellado: Icons.broken_image_outlined,
  };

  @override
  void initState() {
    super.initState();
    _parteAfectadaController = TextEditingController(
      text: widget.point.damageDetail?.affectedPart ?? _getDefaultPart(),
    );
    _parteAfectadaController.addListener(() => setState(() {}));

    if (widget.point.damageDetail != null) {
      _selectedType = widget.point.damageDetail!.damageType;
      _selectedSeverity = widget.point.damageDetail!.severity;
      final path = widget.point.damageDetail!.photoPath;
      if (path != null) {
        _photoPathForSave = path;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final bytes = await file_reader.readFileBytes(path);
          if (mounted && bytes != null) setState(() => _photoBytes = bytes);
        });
      }
    }
  }

  String _getDefaultPart() {
    return 'Carrocería de ${widget.point.zoneName}';
  }

  bool get _canGuardar {
    return widget.point.view.idCatVistaVehiculo > 0 &&
        _parteAfectadaController.text.trim().isNotEmpty &&
        _selectedType != null &&
        _selectedSeverity != null &&
        _photoBytes != null &&
        _photoBytes!.isNotEmpty;
  }

  @override
  void dispose() {
    _parteAfectadaController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      final bytes = await photo.readAsBytes();
      if (mounted) {
        setState(() {
          _photoBytes = bytes;
          _photoPathForSave = photo.path;
        });
      }
    }
  }

  String _evidenciaFilename() {
    final path = _photoPathForSave;
    if (path != null && path.isNotEmpty) {
      final segments = path.split(RegExp(r'[/\\]'));
      if (segments.isNotEmpty && segments.last.isNotEmpty) {
        return segments.last;
      }
    }
    return 'evidencia.jpg';
  }

  Future<void> _save() async {
    if (!_canGuardar || _guardando) return;

    final tipo = _selectedType!;
    final severidad = _selectedSeverity!;
    final parte = _parteAfectadaController.text.trim();
    final fotoBytes = _photoBytes!;

    if (widget.checklistType == ChecklistType.apertura) {
      final idBitacora = ref.read(turnoAperturaProvider).idBitacoraApertura;
      if (idBitacora == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay bitácora de apertura. Completa el paso anterior.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _guardando = true);

      try {
        await ref.read(turnosServiceProvider).registrarInspeccionVehiculoEx(
              idBitacoraVehiculo: idBitacora,
              idCatVistaVehiculo: widget.point.view.idCatVistaVehiculo,
              partesVehiculoEx: parte,
              idCatTipoDano: tipo.idCatTipoDano,
              idCatGradoSeveridad: severidad.idCatGradoSeveridad,
              evidenciaFotograficaBytes: fotoBytes,
              filename: _evidenciaFilename(),
            );

        if (!mounted) return;
        setState(() => _guardando = false);
        _guardarLocal(tipo, severidad, parte);
      } on AuthException catch (e) {
        if (!mounted) return;
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      } on NetworkException catch (e) {
        if (!mounted) return;
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar daño: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _guardarLocal(tipo, severidad, parte);
  }

  void _guardarLocal(DamageType tipo, DamageSeverity severidad, String parte) {
    final detail = DamageDetail(
      affectedPart: parte,
      damageType: tipo,
      severity: severidad,
      photoPath: _photoPathForSave,
    );
    widget.onSave(detail);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RegistroDanosColors.sheetBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: RegistroDanosColors.sheetHandle(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildParteAfectada(context),
                  const SizedBox(height: 24),
                  _buildTipoDano(context),
                  const SizedBox(height: 24),
                  _buildSeveridad(context),
                  const SizedBox(height: 24),
                  _buildFotoSection(context),
                  const SizedBox(height: 32),
                  _buildGuardarButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.point.zoneName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: RegistroDanosColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: RegistroDanosColors.textSecondary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildParteAfectada(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parte afectada',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: RegistroDanosColors.sectionHeading(context),
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: RegistroDanosColors.cardBackground(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _parteAfectadaController,
                  style: TextStyle(
                    color: RegistroDanosColors.textPrimary(context),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    filled: true,
                    fillColor: RegistroDanosColors.cardBackground(context),
                  ),
                ),
              ),
              Icon(Icons.edit, color: RegistroDanosColors.textSecondary(context), size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipoDano(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de daño',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: RegistroDanosColors.sectionHeading(context),
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 12),
        ...DamageType.values.expand((type) sync* {
          yield _DamageTypeOption(
            type: type,
            label: type.nombre,
            icon: _damageTypeIcons[type] ?? Icons.help_outline,
            isSelected: _selectedType == type,
            onTap: () => setState(() => _selectedType = type),
          );
          if (type != DamageType.values.last) {
            yield const SizedBox(height: 8);
          }
        }),
      ],
    );
  }

  Widget _buildSeveridad(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Severidad',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: RegistroDanosColors.sectionHeading(context),
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SeverityOption(
                severity: DamageSeverity.baja,
                label: DamageSeverity.baja.nombre,
                isSelected: _selectedSeverity == DamageSeverity.baja,
                onTap: () => setState(() => _selectedSeverity = DamageSeverity.baja),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SeverityOption(
                severity: DamageSeverity.media,
                label: DamageSeverity.media.nombre,
                isSelected: _selectedSeverity == DamageSeverity.media,
                onTap: () => setState(() => _selectedSeverity = DamageSeverity.media),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SeverityOption(
                severity: DamageSeverity.alta,
                label: DamageSeverity.alta.nombre,
                isSelected: _selectedSeverity == DamageSeverity.alta,
                onTap: () => setState(() => _selectedSeverity = DamageSeverity.alta),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SeverityOption(
                severity: DamageSeverity.critico,
                label: DamageSeverity.critico.nombre,
                isSelected: _selectedSeverity == DamageSeverity.critico,
                onTap: () => setState(() => _selectedSeverity = DamageSeverity.critico),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFotoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _takePhoto,
          child: _photoBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _photoBytes!,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : DashedBorderBox(
                  height: 100,
                  child: Container(
                    color: RegistroDanosColors.cardBackground(context),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: RegistroDanosColors.textSecondary(context),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tomar fotografía',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: RegistroDanosColors.textSecondary(context),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildGuardarButton(BuildContext context) {
    final enabled = _canGuardar && !_guardando;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? _save : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: RegistroDanosColors.buttonPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: RegistroDanosColors.textSecondary(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _guardando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Guardar Punto',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DamageTypeOption extends StatelessWidget {
  const _DamageTypeOption({
    required this.type,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final DamageType type;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: RegistroDanosColors.inputBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: RegistroDanosColors.pointDamaged, width: 1)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? RegistroDanosColors.pointDamaged
                      : RegistroDanosColors.textSecondary(context),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: RegistroDanosColors.pointDamaged,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: RegistroDanosColors.textPrimary(context),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Icon(icon, color: RegistroDanosColors.textSecondary(context), size: 22),
          ],
        ),
      ),
    );
  }
}

class _SeverityOption extends StatelessWidget {
  const _SeverityOption({
    required this.severity,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final DamageSeverity severity;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _color {
    switch (severity) {
      case DamageSeverity.baja:
        return RegistroDanosColors.severityBaja;
      case DamageSeverity.media:
        return RegistroDanosColors.severityMedia;
      case DamageSeverity.alta:
        return RegistroDanosColors.severityAlta;
      case DamageSeverity.critico:
        return const Color(0xFF4A0E1F);
    }
  }

  Color _bgColor(BuildContext context) {
    switch (severity) {
      case DamageSeverity.baja:
        return RegistroDanosColors.severityBajaBg(context);
      case DamageSeverity.media:
        return RegistroDanosColors.severityMedia.withValues(alpha: 0.2);
      case DamageSeverity.alta:
        return RegistroDanosColors.severityAlta.withValues(alpha: 0.2);
      case DamageSeverity.critico:
        return const Color(0xFF4A0E1F).withValues(alpha: 0.2);
    }
  }

  int get _activeDots {
    switch (severity) {
      case DamageSeverity.baja:
        return 1;
      case DamageSeverity.media:
        return 2;
      case DamageSeverity.alta:
        return 3;
      case DamageSeverity.critico:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _bgColor(context) : RegistroDanosColors.inputBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: _color, width: 1) : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final active = isSelected && index < _activeDots;
                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? _color
                          : RegistroDanosColors.textSecondary(context).withValues(alpha: 0.3),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _color : RegistroDanosColors.textSecondary(context),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
