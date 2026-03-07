import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../captura_odometro/dashed_border_box.dart';
import '../inicio_turno/inicio_turno_colors.dart';

/// Pantalla para identificar el vehículo por fotografía de la placa.
/// Permite tomar foto o elegir imagen; temporalmente se puede ingresar la placa manualmente.
class IdentificarPlacaPage extends StatefulWidget {
  const IdentificarPlacaPage({
    super.key,
    this.onPlacaIdentificada,
    this.onRegresar,
  });

  final void Function(String vehiculoId)? onPlacaIdentificada;
  final VoidCallback? onRegresar;

  @override
  State<IdentificarPlacaPage> createState() => _IdentificarPlacaPageState();
}

class _IdentificarPlacaPageState extends State<IdentificarPlacaPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _placaController = TextEditingController();

  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void dispose() {
    _placaController.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      final bytes = await photo.readAsBytes();
      if (mounted) setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _elegirImagen() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null && mounted) {
      final bytes = await photo.readAsBytes();
      if (mounted) setState(() => _imageBytes = bytes);
    }
  }

  void _identificarVehiculo() {
    final placa = _placaController.text.trim();
    if (placa.isNotEmpty) {
      if (widget.onPlacaIdentificada != null) {
        widget.onPlacaIdentificada!(placa);
      } else {
        Navigator.of(context).pop(placa);
      }
      return;
    }
    if (_imageBytes != null) {
      setState(() => _isLoading = true);
      // TODO: integrar OCR o API para reconocer placa desde _imageBytes.
      // Por ahora devolvemos un valor temporal si hay imagen pero no placa manual.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isLoading = false);
          const valorTemporal = 'Placa (pendiente OCR)';
          if (widget.onPlacaIdentificada != null) {
            widget.onPlacaIdentificada!(valorTemporal);
          } else {
            Navigator.of(context).pop(valorTemporal);
          }
        }
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toma una foto de la placa o ingresa la placa manualmente.'),
      ),
    );
  }

  void _regresar() {
    if (widget.onRegresar != null) {
      widget.onRegresar!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InicioTurnoColors.background(context),
      appBar: AppBar(
        backgroundColor: InicioTurnoColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: InicioTurnoColors.textPrimary(context)),
          onPressed: _regresar,
        ),
        titleSpacing: 0,
        title: Text(
          'Identificar vehículo por placa',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: InicioTurnoColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Escanea la placa del vehículo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: InicioTurnoColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coloca la placa del vehículo dentro del marco.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: InicioTurnoColors.textSecondary(context),
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _tomarFoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 22),
                    label: const Text('Tomar foto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: InicioTurnoColors.buttonPrimary,
                      side: BorderSide(color: InicioTurnoColors.buttonPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _elegirImagen,
                    icon: const Icon(Icons.photo_library_outlined, size: 22),
                    label: const Text('Galería'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: InicioTurnoColors.buttonPrimary,
                      side: BorderSide(color: InicioTurnoColors.buttonPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DashedBorderBox(
              height: 200,
              child: _imageBytes != null
                  ? Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 48,
                            color: InicioTurnoColors.placeholder(context),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Vista previa de la placa',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: InicioTurnoColors.placeholder(context),
                                ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              'Placa (opcional, ingreso manual)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: InicioTurnoColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _placaController,
              decoration: InputDecoration(
                hintText: 'Ej. ABC-12-34',
                hintStyle: TextStyle(color: InicioTurnoColors.placeholder(context)),
                filled: true,
                fillColor: InicioTurnoColors.inputBackground(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: InicioTurnoColors.buttonPrimary),
                ),
              ),
              style: TextStyle(color: InicioTurnoColors.textPrimary(context)),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _identificarVehiculo(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _identificarVehiculo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: InicioTurnoColors.buttonPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Identificar vehículo'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _regresar,
              style: OutlinedButton.styleFrom(
                foregroundColor: InicioTurnoColors.textPrimary(context),
                side: BorderSide(color: InicioTurnoColors.textSecondary(context)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Regresar'),
            ),
          ],
        ),
      ),
    );
  }
}
