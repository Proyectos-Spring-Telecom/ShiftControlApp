import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/services/auth_service.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_alert_banner.dart';
import '../../widgets/loading_overlay.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/utils/validators.dart';
import '../face_auth/face_auth_flow_page.dart';
import 'login_colors.dart';
import 'recuperar_contrasena_page.dart';

enum LoginMode { credentials, nip }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nipController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureNip = true;
  LoginMode _loginMode = LoginMode.credentials;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loginMode == LoginMode.credentials) {
      if (!_formKey.currentState!.validate()) return;
    } else {
      if (!_formKey.currentState!.validate()) return;
      final email = await ref.read(authServiceProvider).getLastLoginEmail();
      final emailTrim = email?.trim() ?? '';
      if (emailTrim.isEmpty) {
        showAppAlertBanner(
          context,
          type: AppAlertType.info,
          title: 'Correo requerido',
          message: 'No hay credenciales guardadas. Inicia sesión con correo y contraseña primero.',
        );
        return;
      }
    }

    bool success;
    if (_loginMode == LoginMode.credentials) {
      success = await ref.read(authControllerProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } else {
      final email = await ref.read(authServiceProvider).getLastLoginEmail();
      final emailTrim = email?.trim() ?? '';
      success = await ref.read(authControllerProvider.notifier).loginWithNip(
            emailTrim,
            _nipController.text.trim(),
          );
    }

    if (!mounted) return;
    if (success) {
      final user = ref.read(authControllerProvider).user;
      final rolNombre = user?.roleName ?? user?.name ?? 'Usuario';
      showAppAlertBanner(
        context,
        type: AppAlertType.success,
        title: 'Éxito',
        message: 'Bienvenido, $rolNombre',
      );
      Navigator.of(context).pushReplacementNamed(RouteConstants.home);
    } else {
      final errorMsg = ref.read(authControllerProvider).errorMessage;
      final is401 = errorMsg != null && errorMsg.contains('autorizado');
      showAppAlertBanner(
        context,
        type: is401 ? AppAlertType.info : AppAlertType.error,
        title: is401 ? 'No autorizado' : 'Error al iniciar sesión',
        message: errorMsg ?? 'No se pudo iniciar sesión. Revisa tus datos.',
      );
    }
  }

  void _switchMode(LoginMode mode) {
    if (_loginMode != mode) {
      setState(() => _loginMode = mode);
      if (mode == LoginMode.credentials) {
        ref.read(authServiceProvider).getLastLoginEmail().then((email) {
          if (mounted && email != null && email.isNotEmpty) {
            setState(() {
              _emailController.text = email;
              _passwordController.clear();
            });
          } else {
            _formKey.currentState?.reset();
          }
        });
      }
    }
  }

  void _onFaceAuthTap() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FaceAuthFlowPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: LoginColors.background(context),
      body: LoadingOverlay(
        isLoading: authState.status == AuthStatus.loading,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 48),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            'assets/images/spring_logo.png',
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 60),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Hola, inicia sesión',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: LoginColors.textPrimary(context),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLoginModeSelector(context),
                        const SizedBox(height: 28),
                        if (_loginMode == LoginMode.credentials) ...[
                          _LoginField(
                            controller: _emailController,
                            label: 'Correo Electrónico:',
                            hint: 'Ingresa tu correo electrónico',
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 20),
                          _LoginField(
                            controller: _passwordController,
                            label: 'Contraseña:',
                            hint: 'Ingresa tu contraseña',
                            obscureText: _obscurePassword,
                            validator: (v) => Validators.required(v, 'La contraseña'),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: LoginColors.placeholder(context),
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const RecuperarContrasenaPage(),
                                  ),
                                );
                              },
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: LoginColors.button,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        ] else ...[
                          _LoginField(
                            controller: _nipController,
                            label: 'NIP:',
                            hint: 'Ingresa tu NIP de operador',
                            keyboardType: TextInputType.number,
                            obscureText: _obscureNip,
                            validator: (v) => Validators.required(v, 'El NIP'),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNip ? Icons.visibility_off : Icons.visibility,
                                color: LoginColors.placeholder(context),
                              ),
                              onPressed: () =>
                                  setState(() => _obscureNip = !_obscureNip),
                            ),
                          ),
                        ],
                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            authState.errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _onFaceAuthTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LoginColors.button,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Iniciar con FaceAuth'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LoginColors.buttonOutlineBackground(context),
                              foregroundColor: LoginColors.buttonOutlineForeground(context),
                              surfaceTintColor: Colors.transparent,
                              elevation: 0,
                              side: BorderSide(
                                color: LoginColors.buttonOutlineForeground(context),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Iniciar Sesión'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Text(
                  'Al iniciar aceptas nuestros Términos y Condiciones y Política de Privacidad.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LoginColors.textPrimary(context).withValues(alpha: 0.85),
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginModeSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LoginColors.inputBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _LoginModeTab(
              label: 'Credenciales',
              isSelected: _loginMode == LoginMode.credentials,
              onTap: () => _switchMode(LoginMode.credentials),
            ),
          ),
          Expanded(
            child: _LoginModeTab(
              label: 'NIP',
              isSelected: _loginMode == LoginMode.nip,
              onTap: () => _switchMode(LoginMode.nip),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginModeTab extends StatelessWidget {
  const _LoginModeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? LoginColors.button : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : LoginColors.placeholder(context),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.autocorrect = true,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool autocorrect;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: LoginColors.textPrimary(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: LoginColors.textPrimary(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: LoginColors.placeholder(context)),
            filled: true,
            fillColor: LoginColors.inputBackground(context),
            suffixIcon: suffixIcon,
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
              borderSide: BorderSide(color: LoginColors.focusBorder(context), width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autocorrect: autocorrect,
        ),
      ],
    );
  }
}
