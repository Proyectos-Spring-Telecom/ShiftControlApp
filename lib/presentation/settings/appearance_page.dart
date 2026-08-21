import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/profile/profile_colors.dart';
import '../controllers/theme_controller.dart';

/// BottomSheet de apariencia (Claro / Oscuro / Sistema).
/// Reutiliza [themeModePreferenceProvider]; no crea un sistema de temas paralelo.
Future<void> showAppearanceBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _AppearanceBottomSheet(),
  );
}

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
        child: _AppearanceOptions(
          current: current,
          onSelect: (preference) => notifier.setThemeMode(preference),
        ),
      ),
    );
  }
}

class _AppearanceBottomSheet extends ConsumerWidget {
  const _AppearanceBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModePreferenceProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: ProfileColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ProfileColors.inputBorder(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Apariencia',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: ProfileColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Elige cómo se ve la aplicación. El cambio se aplica de inmediato.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ProfileColors.textSecondary(context),
                ),
          ),
          const SizedBox(height: 20),
          _AppearanceOptions(
            current: current,
            onSelect: (preference) async {
              await ref
                  .read(themeModePreferenceProvider.notifier)
                  .setThemeMode(preference);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AppearanceOptions extends StatelessWidget {
  const _AppearanceOptions({
    required this.current,
    required this.onSelect,
  });

  final ThemeModePreference current;
  final ValueChanged<ThemeModePreference> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...ThemeModePreference.values.map((preference) {
          final isSelected = current == preference;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ThemeOptionCard(
              preference: preference,
              isSelected: isSelected,
              onTap: () => onSelect(preference),
            ),
          );
        }),
        const SizedBox(height: 4),
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
