import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/route_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../turnos/control_turnos_colors.dart';
import '../../widgets/loading_overlay.dart';
import 'cambiar_contrasena_page.dart';
import 'crear_nip_page.dart';
import 'profile_colors.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _apellidoController = TextEditingController();
    _telefonoController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.read(authControllerProvider).user;
    if (user != null && _nombreController.text.isEmpty) {
      final parts = user.name.trim().split(RegExp(r'\s+'));
      _nombreController.text = parts.isNotEmpty ? parts.first : '';
      _apellidoController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final displayName = user?.name ?? 'Usuario';

    return LoadingOverlay(
      isLoading: authState.status == AuthStatus.loading,
      child: Scaffold(
        backgroundColor: ProfileColors.background(context),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: ProfileColors.cardBackground(context),
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName.substring(0, 1).toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: ProfileColors.textPrimary(context),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: ProfileColors.textPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                  decoration: BoxDecoration(
                    color: ControlTurnosColors.statusPillBackground(context),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: ControlTurnosColors.statusPillForeground(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Activo',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: ControlTurnosColors.statusPillForeground(context),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Datos Personales',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: ProfileColors.textPrimary(context),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Te damos la bienvenida a Spring Telecom:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ProfileColors.textSecondary(context),
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(context, controller: _nombreController, hint: 'Nombre'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput(context, controller: _apellidoController, hint: 'Apellido'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInput(context, controller: _telefonoController, hint: 'Teléfono', keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildInput(context, controller: _emailController, hint: 'Correo', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const CrearNipPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProfileColors.buttonPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Crear NIP'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const CambiarContrasenaPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProfileColors.accentWine,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cambiar Contraseña'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          RouteConstants.login,
                          (_) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProfileColors.accentWine,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cerrar Sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: ProfileColors.inputBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProfileColors.inputBorder(context), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: ProfileColors.textPrimary(context), fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: ProfileColors.textSecondary(context), fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          isDense: true,
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}
