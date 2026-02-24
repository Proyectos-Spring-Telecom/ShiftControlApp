import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/profile/profile_colors.dart';
import '../controllers/theme_controller.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModePreferenceProvider);
    final notifier = ref.read(themeModePreferenceProvider.notifier);

    return Scaffold(
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
          'Apariencia',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: ProfileColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona el tema',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ProfileColors.textPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personaliza la apariencia de la aplicación según tus preferencias.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ProfileColors.textSecondary(context),
                  ),
            ),
            const SizedBox(height: 24),
            ...ThemeModePreference.values.map((preference) {
              final isSelected = current == preference;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ThemeOptionCard(
                  preference: preference,
                  isSelected: isSelected,
                  onTap: () => notifier.setThemeMode(preference),
                ),
              );
            }),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ProfileColors.cardBackground(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ProfileColors.inputBorder(context),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ProfileColors.textSecondary(context),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '«Según el dispositivo» usa el modo claro u oscuro del sistema automáticamente.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ProfileColors.textSecondary(context),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.preference,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeModePreference preference;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (preference) {
      case ThemeModePreference.light:
        return Icons.light_mode;
      case ThemeModePreference.dark:
        return Icons.dark_mode;
      case ThemeModePreference.system:
        return Icons.brightness_auto;
    }
  }

  String get _description {
    switch (preference) {
      case ThemeModePreference.light:
        return 'Interfaz con colores claros';
      case ThemeModePreference.dark:
        return 'Interfaz con colores oscuros';
      case ThemeModePreference.system:
        return 'Se adapta a la configuración del sistema';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ProfileColors.cardBackground(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? ProfileColors.buttonPrimary
                  : ProfileColors.inputBorder(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ProfileColors.buttonPrimary.withValues(alpha: 0.15)
                      : ProfileColors.inputBackground(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _icon,
                  color: isSelected
                      ? ProfileColors.buttonPrimary
                      : ProfileColors.textSecondary(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preference.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ProfileColors.textPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ProfileColors.textSecondary(context),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? ProfileColors.buttonPrimary
                        : ProfileColors.textSecondary(context),
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
                            color: ProfileColors.buttonPrimary,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
