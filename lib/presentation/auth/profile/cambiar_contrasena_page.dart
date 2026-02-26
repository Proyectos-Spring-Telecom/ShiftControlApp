import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../features/profile/models/change_password_request.dart';
import '../../../features/profile/services/profile_service.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_alert_banner.dart';
import '../../widgets/loading_overlay.dart';
import 'profile_colors.dart';

class CambiarContrasenaPage extends ConsumerStatefulWidget {
  const CambiarContrasenaPage({super.key});

  @override
  ConsumerState<CambiarContrasenaPage> createState() => _CambiarContrasenaPageState();
}

class _CambiarContrasenaPageState extends ConsumerState<CambiarContrasenaPage> {
  final _formKey = GlobalKey<FormState>();
  final _contrasenaActualController = TextEditingController();
  final _nuevaContrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();

  bool _obscureActual = true;
  bool _obscureNueva = true;
  bool _obscureConfirmar = true;
  bool _isLoading = false;

  String? _errorActual;
  String? _errorNueva;
  String? _errorConfirmar;

  @override
  void dispose() {
    _contrasenaActualController.dispose();
    _nuevaContrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  bool _tieneMayuscula(String value) => value.contains(RegExp(r'[A-Z]'));
  bool _tieneMinuscula(String value) => value.contains(RegExp(r'[a-z]'));
  bool _tieneNumero(String value) => value.contains(RegExp(r'[0-9]'));
  bool _tieneCaracterEspecial(String value) => value.contains(RegExp(r'[#?!@$%^&*\-_+=(){}[\]|\\:;"<>,./]'));
  bool _tieneLongitudValida(String value) => value.length > 6 && value.length < 16;

  int _calcularNivelSeguridad(String value) {
    if (value.isEmpty) return 0;

    int nivel = 0;
    if (_tieneMayuscula(value)) nivel++;
    if (_tieneMinuscula(value)) nivel++;
    if (_tieneNumero(value)) nivel++;
    if (_tieneCaracterEspecial(value)) nivel++;
    if (_tieneLongitudValida(value)) nivel++;

    return nivel;
  }

  String? _validarNuevaContrasena(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (!_tieneLongitudValida(value)) {
      return 'La contraseña debe tener entre 7 y 15 caracteres';
    }
    if (!_tieneMayuscula(value)) {
      return 'Debe tener al menos una mayúscula';
    }
    if (!_tieneMinuscula(value)) {
      return 'Debe tener al menos una minúscula';
    }
    if (!_tieneNumero(value)) {
      return 'Debe tener al menos un número';
    }
    if (!_tieneCaracterEspecial(value)) {
      return 'Debe tener al menos un carácter especial (#?!&)';
    }
    return null;
  }

  void _validarCampos() {
    setState(() {
      if (_contrasenaActualController.text.isEmpty) {
        _errorActual = 'Ingresa tu contraseña actual';
      } else {
        _errorActual = null;
      }

      _errorNueva = _validarNuevaContrasena(_nuevaContrasenaController.text);

      if (_confirmarContrasenaController.text.isEmpty) {
        _errorConfirmar = 'Confirma tu nueva contraseña';
      } else if (_confirmarContrasenaController.text != _nuevaContrasenaController.text) {
        _errorConfirmar = 'Las contraseñas no coinciden';
      } else {
        _errorConfirmar = null;
      }
    });
  }

  Future<void> _guardarContrasena() async {
    _validarCampos();

    if (_errorActual != null || _errorNueva != null || _errorConfirmar != null) {
      showAppAlertBanner(
        context,
        type: AppAlertType.info,
        title: 'Revisa los datos',
        message: 'Completa correctamente todos los campos antes de continuar.',
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final request = ChangePasswordRequest(
      passwordActual: _contrasenaActualController.text,
      passwordNueva: _nuevaContrasenaController.text,
      passwordNuevaConfirmacion: _confirmarContrasenaController.text,
    );

    try {
      final profileService = ref.read(profileServiceProvider);
      final response = await profileService.changePassword(request);

      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = response['message'] is String
          ? response['message'] as String
          : 'Tu contraseña se actualizó correctamente.';
      showAppAlertBanner(
        context,
        type: AppAlertType.success,
        title: 'Contraseña actualizada',
        message: message,
        onDismissed: () => Navigator.of(context).pop(),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.code == '401') {
        showAppAlertBanner(
          context,
          type: AppAlertType.info,
          title: 'Sesión expirada',
          message: e.message,
          onDismissed: () => Navigator.of(context).pop(),
        );
      } else {
        showAppAlertBanner(
          context,
          type: AppAlertType.error,
          title: 'Error',
          message: e.message,
        );
      }
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAppAlertBanner(
        context,
        type: AppAlertType.error,
        title: 'Error',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAppAlertBanner(
        context,
        type: AppAlertType.error,
        title: 'Error',
        message: 'No se pudo actualizar la contraseña. Intenta de nuevo.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: ProfileColors.background(context),
        appBar: AppBar(
        backgroundColor: ProfileColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ProfileColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          'Cambio de contraseña',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: ProfileColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sigue las indicaciones para realizar el cambio de contraseña.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ProfileColors.textSecondary(context),
                    ),
              ),
              const SizedBox(height: 24),
              _buildContrasenaSection(context),
              const SizedBox(height: 24),
              _buildSemaforoSeguridad(context),
              const SizedBox(height: 24),
              _buildRequisitos(context),
              const SizedBox(height: 32),
              _buildGuardarButton(context),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildContrasenaSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingresa los datos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ProfileColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 20),
        _buildPasswordInput(
          context,
          controller: _contrasenaActualController,
          hint: 'Contraseña actual',
          obscure: _obscureActual,
          onToggleObscure: () => setState(() => _obscureActual = !_obscureActual),
          error: _errorActual,
        ),
        const SizedBox(height: 16),
        _buildPasswordInput(
          context,
          controller: _nuevaContrasenaController,
          hint: 'Nueva contraseña',
          obscure: _obscureNueva,
          onToggleObscure: () => setState(() => _obscureNueva = !_obscureNueva),
          error: _errorNueva,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _buildPasswordInput(
          context,
          controller: _confirmarContrasenaController,
          hint: 'Confirmar contraseña',
          obscure: _obscureConfirmar,
          onToggleObscure: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
          error: _errorConfirmar,
        ),
      ],
    );
  }

  Widget _buildPasswordInput(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleObscure,
    String? error,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: ProfileColors.inputBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? ProfileColors.accentWine : ProfileColors.inputBorder(context),
              width: hasError ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: TextStyle(
                    color: ProfileColors.textPrimary(context),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: ProfileColors.textSecondary(context),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  onChanged: (value) {
                    if (_errorNueva != null || _errorConfirmar != null || _errorActual != null) {
                      _validarCampos();
                    }
                    onChanged?.call(value);
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: ProfileColors.textSecondary(context),
                  size: 22,
                ),
                onPressed: onToggleObscure,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: ProfileColors.accentWine,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ProfileColors.accentWine,
                      ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSemaforoSeguridad(BuildContext context) {
    final nivel = _calcularNivelSeguridad(_nuevaContrasenaController.text);
    final password = _nuevaContrasenaController.text;

    String nivelTexto;
    Color nivelColor;

    if (password.isEmpty) {
      nivelTexto = 'Ingresa una contraseña';
      nivelColor = ProfileColors.textSecondary(context);
    } else if (nivel <= 2) {
      nivelTexto = 'Seguridad baja';
      nivelColor = const Color(0xFFE53935);
    } else if (nivel <= 4) {
      nivelTexto = 'Seguridad media';
      nivelColor = const Color(0xFFFFA726);
    } else {
      nivelTexto = 'Seguridad alta';
      nivelColor = const Color(0xFF43A047);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfileColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nivel de seguridad',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ProfileColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSemaforoIndicador(
                  context,
                  color: const Color(0xFFE53935),
                  isActive: password.isNotEmpty && nivel >= 1,
                  label: 'Baja',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSemaforoIndicador(
                  context,
                  color: const Color(0xFFFFA726),
                  isActive: nivel >= 3,
                  label: 'Media',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSemaforoIndicador(
                  context,
                  color: const Color(0xFF43A047),
                  isActive: nivel >= 5,
                  label: 'Alta',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                password.isEmpty
                    ? Icons.security_outlined
                    : nivel <= 2
                        ? Icons.warning_amber_rounded
                        : nivel <= 4
                            ? Icons.shield_outlined
                            : Icons.verified_user_outlined,
                color: nivelColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                nivelTexto,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: nivelColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemaforoIndicador(
    BuildContext context, {
    required Color color,
    required bool isActive,
    required String label,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? color : color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive ? color : ProfileColors.textSecondary(context),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  Widget _buildRequisitos(BuildContext context) {
    final password = _nuevaContrasenaController.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfileColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos de la contraseña',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ProfileColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildRequisitoItem(
            context,
            texto: 'Entre 7 y 15 caracteres',
            cumplido: _tieneLongitudValida(password),
            mostrarEstado: password.isNotEmpty,
          ),
          _buildRequisitoItem(
            context,
            texto: 'Al menos una mayúscula (A-Z)',
            cumplido: _tieneMayuscula(password),
            mostrarEstado: password.isNotEmpty,
          ),
          _buildRequisitoItem(
            context,
            texto: 'Al menos una minúscula (a-z)',
            cumplido: _tieneMinuscula(password),
            mostrarEstado: password.isNotEmpty,
          ),
          _buildRequisitoItem(
            context,
            texto: 'Al menos un número (0-9)',
            cumplido: _tieneNumero(password),
            mostrarEstado: password.isNotEmpty,
          ),
          _buildRequisitoItem(
            context,
            texto: 'Al menos un carácter especial (#?!&)',
            cumplido: _tieneCaracterEspecial(password),
            mostrarEstado: password.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _buildRequisitoItem(
    BuildContext context, {
    required String texto,
    required bool cumplido,
    required bool mostrarEstado,
  }) {
    final Color iconColor;
    final IconData iconData;

    if (!mostrarEstado) {
      iconColor = ProfileColors.textSecondary(context);
      iconData = Icons.circle_outlined;
    } else if (cumplido) {
      iconColor = const Color(0xFF43A047);
      iconData = Icons.check_circle;
    } else {
      iconColor = const Color(0xFFE53935);
      iconData = Icons.cancel;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: mostrarEstado && cumplido
                        ? const Color(0xFF43A047)
                        : ProfileColors.textSecondary(context),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardarButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _guardarContrasena,
        style: ElevatedButton.styleFrom(
          backgroundColor: ProfileColors.accentWine,
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
              'Guardar contraseña',
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
