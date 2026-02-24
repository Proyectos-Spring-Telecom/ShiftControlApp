import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/route_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../auth/profile/profile_page.dart';
import '../../settings/appearance_page.dart';
import '../../turnos/control_turnos_page.dart';
import '../../turnos/historial_turnos/historial_turnos_page.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    this.onControlTurnosTap,
    this.onHistorialTap,
    this.onProfileTap,
  });

  /// Si se proporciona, se usa en lugar de navegar por ruta (ej. desde MainShell).
  final VoidCallback? onControlTurnosTap;
  final VoidCallback? onHistorialTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name.substring(0, 1).toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Usuario',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (user?.email != null)
                  Text(
                    user!.email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Control de Turnos'),
            onTap: () {
              if (onControlTurnosTap != null) {
                onControlTurnosTap!();
              } else {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ControlTurnosPage(
                      onBack: () => Navigator.of(context).pop(),
                      onOpenDrawer: null,
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial'),
            onTap: () {
              if (onHistorialTap != null) {
                onHistorialTap!();
              } else {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HistorialTurnosPage(),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil'),
            onTap: () {
              if (onProfileTap != null) {
                onProfileTap!();
              } else {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfilePage(),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Apariencia'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AppearancePage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  RouteConstants.login,
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
