import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        if (!mounted) return;
        showAppAlertBanner(
          context,
          type: AppAlertType.info,
          title: 'Correo requerido',
          message:
              'No hay credenciales guardadas. Inicia sesión con correo y contraseña primero.',
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? LoginColors.background(context)
          : Colors.transparent,
      body: LoadingOverlay(
        isLoading: authState.status == AuthStatus.loading,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Hero: imagen de fondo. Degradado solo en oscuro; en claro, transición limpia.
            Positioned.fill(
              child: Image.asset(
                'assets/images/imagen_nueva.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: isDark
                      ? const Color(0xFF0A1628)
                      : const Color(0xFFD6E4F5),
                ),
              ),
            ),
            if (isDark)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          LoginColors.background(context)
                              .withValues(alpha: 0.35),
                          LoginColors.background(context)
                              .withValues(alpha: 0.88),
                          LoginColors.background(context),
                        ],
                        stops: const [0.28, 0.48, 0.68, 0.88],
                      ),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Image.asset(
                              'assets/images/logoHorizontal2.webp',
                              height: 43,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Hola, inicia sesión',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x66000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Acceso para operadores en campo',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.3,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x55000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _LoginFormCard(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildLoginModeSelector(context),
                                      const SizedBox(height: 22),
                                      if (_loginMode ==
                                          LoginMode.credentials) ...[
                                        _LoginField(
                                          controller: _emailController,
                                          label: 'Correo Electrónico',
                                          hint:
                                              'Ingresa tu correo electrónico',
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          autocorrect: false,
                                          prefixIcon: Icons.mail_outline,
                                          validator: Validators.email,
                                        ),
                                        const SizedBox(height: 16),
                                        _LoginField(
                                          controller: _passwordController,
                                          label: 'Contraseña',
                                          hint: 'Ingresa tu contraseña',
                                          obscureText: _obscurePassword,
                                          prefixIcon: Icons.lock_outline,
                                          validator: (v) => Validators.required(
                                            v,
                                            'La contraseña',
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: LoginColors.placeholder(
                                                context,
                                              ),
                                            ),
                                            onPressed: () => setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      const RecuperarContrasenaPage(),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              '¿Olvidaste tu contraseña?',
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        _LoginField(
                                          controller: _nipController,
                                          label: 'NIP',
                                          hint: 'Ingresa tu NIP de operador',
                                          keyboardType: TextInputType.number,
                                          obscureText: _obscureNip,
                                          prefixIcon: Icons.pin_outlined,
                                          validator: (v) =>
                                              Validators.required(v, 'El NIP'),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureNip
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: LoginColors.placeholder(
                                                context,
                                              ),
                                            ),
                                            onPressed: () => setState(
                                              () =>
                                                  _obscureNip = !_obscureNip,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (authState.errorMessage != null) ...[
                                        const SizedBox(height: 14),
                                        Text(
                                          authState.errorMessage!,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                      const SizedBox(height: 22),
                                      SizedBox(
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed: _submit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: LoginColors
                                                .primaryButtonBackground(
                                              context,
                                            ),
                                            foregroundColor: LoginColors
                                                .primaryButtonForeground(
                                              context,
                                            ),
                                            elevation: 0,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: Text(
                                            'Iniciar Sesión',
                                            style: theme
                                                .textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: LoginColors
                                                  .primaryButtonForeground(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 52,
                                        child: OutlinedButton.icon(
                                          onPressed: _onFaceAuthTap,
                                          icon: const Icon(
                                            Icons.face_outlined,
                                            size: 20,
                                          ),
                                          label: const Text(
                                            'Reconocimiento facial',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: LoginColors
                                                .secondaryButtonBackground(
                                              context,
                                            ),
                                            foregroundColor: LoginColors
                                                .secondaryButtonForeground(
                                              context,
                                            ),
                                            side: BorderSide(
                                              color: LoginColors
                                                  .secondaryButtonBorder(
                                                context,
                                              ),
                                              width: 1.2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text.rich(
                                  TextSpan(
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          LoginColors.onCardSecondary(context),
                                      height: 1.35,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Al iniciar aceptas nuestros ',
                                      ),
                                      TextSpan(
                                        text: 'Términos y Condiciones',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: LoginColors.onCardPrimary(
                                            context,
                                          ),
                                        ),
                                      ),
                                      const TextSpan(text: ' y '),
                                      TextSpan(
                                        text: 'Política de Privacidad.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: LoginColors.onCardPrimary(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginModeSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LoginColors.tabTrack(context),
        borderRadius: BorderRadius.circular(14),
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

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LoginColors.cardBackground(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LoginColors.cardBorder(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: child,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? LoginColors.tabSelected(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? LoginColors.tabSelectedForeground(context)
                  : LoginColors.tabUnselectedForeground(context),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 15,
            ),
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
    this.prefixIcon,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool autocorrect;
  final IconData? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: LoginColors.onCardPrimary(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: LoginColors.onCardPrimary(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: LoginColors.onCardPlaceholder(context)),
            filled: true,
            fillColor: LoginColors.inputBackground(context),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: LoginColors.onCardPlaceholder(context),
                    size: 22,
                  )
                : null,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: LoginColors.inputBorder(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: LoginColors.inputBorder(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: LoginColors.focusBorder(context),
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
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
