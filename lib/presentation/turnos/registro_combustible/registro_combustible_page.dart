import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'registro_combustible_colors.dart';
import '../captura_odometro/dashed_border_box.dart';

class RegistroCombustiblePage extends StatefulWidget {
  const RegistroCombustiblePage({super.key});

  @override
  State<RegistroCombustiblePage> createState() => _RegistroCombustiblePageState();
}

class _RegistroCombustiblePageState extends State<RegistroCombustiblePage> {
  final ImagePicker _picker = ImagePicker();
  File? _fotoBomba;
  File? _fotoTablero;

  Future<void> _tomarFotoBomba() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      setState(() => _fotoBomba = File(photo.path));
    }
  }

  Future<void> _tomarFotoTablero() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      setState(() => _fotoTablero = File(photo.path));
    }
  }

  @override
  Widget build(BuildContext context) {
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
    File? fotoBomba,
    File? fotoTablero,
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
                'Datos detectados (OCR)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: RegistroCombustibleColors.textPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: RegistroCombustibleColors.accentRed,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Reescanear'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOcrField(context, 'Litros cargados', '45.50', 'LTS'),
          const SizedBox(height: 12),
          _buildOcrField(context, 'Total pagado', r'$1,092.00', 'MXN'),
          const SizedBox(height: 12),
          _buildOcrField(context, 'Kilometraje actual', null, 'KM', hint: 'Ej: 154032'),
        ],
      ),
    );
  }

  Widget _buildOcrField(
    BuildContext context,
    String label,
    String? value,
    String suffix, {
    String? hint,
  }) {
    final isEditable = hint != null && value == null;
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
                child: isEditable
                    ? TextField(
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
                      )
                    : Text(
                        value ?? '',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: RegistroCombustibleColors.textPrimary(context),
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
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RegistroCombustibleColors.buttonSiguiente,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Guardar Registro',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
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
  final File? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DashedBorderBox(
      height: 140,
      child: Material(
        color: RegistroCombustibleColors.progressUnfilled(context),
        child: InkWell(
          onTap: onTap,
          child: image != null
              ? Image.file(
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
