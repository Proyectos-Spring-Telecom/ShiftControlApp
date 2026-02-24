import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../captura_odometro/dashed_border_box.dart';
import 'reporte_incidente_colors.dart';

enum TipoIncidente { accidente, fallaMecanica, danoExterior, otro }

class ReporteIncidentePage extends StatefulWidget {
  const ReporteIncidentePage({super.key});

  @override
  State<ReporteIncidentePage> createState() => _ReporteIncidentePageState();
}

class _ReporteIncidentePageState extends State<ReporteIncidentePage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descripcionController = TextEditingController();
  TipoIncidente _tipoSeleccionado = TipoIncidente.accidente;
  final List<File> _fotos = [];

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _agregarFoto() async {
    if (_fotos.length >= 3) return;
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      setState(() => _fotos.add(File(photo.path)));
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: ReporteIncidenteColors.pillBackground(context),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: ReporteIncidenteColors.pillForeground,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Prioridad Alta',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ReporteIncidenteColors.pillForeground,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                icon: Icons.car_crash_outlined,
                label: 'Accidente',
                isSelected: _tipoSeleccionado == TipoIncidente.accidente,
                onTap: () => setState(() => _tipoSeleccionado = TipoIncidente.accidente),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TipoIncidenteCard(
                icon: Icons.build_outlined,
                label: 'Falla Mecánica',
                isSelected: _tipoSeleccionado == TipoIncidente.fallaMecanica,
                onTap: () => setState(() => _tipoSeleccionado = TipoIncidente.fallaMecanica),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TipoIncidenteCard(
                icon: Icons.image_outlined,
                label: 'Daño Exterior',
                isSelected: _tipoSeleccionado == TipoIncidente.danoExterior,
                onTap: () => setState(() => _tipoSeleccionado = TipoIncidente.danoExterior),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TipoIncidenteCard(
                icon: Icons.more_horiz,
                label: 'Otro',
                isSelected: _tipoSeleccionado == TipoIncidente.otro,
                onTap: () => setState(() => _tipoSeleccionado = TipoIncidente.otro),
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
          child: Image.file(
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: ReporteIncidenteColors.buttonPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
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
