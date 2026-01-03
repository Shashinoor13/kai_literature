import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/theme/theme_model.dart';
import 'package:literature/features/theme/bloc/theme_bloc.dart';
import 'package:literature/features/theme/bloc/theme_event.dart';
import 'package:literature/features/theme/bloc/theme_state.dart';

/// Theme Settings Screen - Customize app appearance
class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Ensure theme is loaded
    final themeBloc = context.read<ThemeBloc>();
    if (themeBloc.state is ThemeInitial) {
      themeBloc.add(const LoadTheme());
    }
  }

  Future<void> _pickBackgroundImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null && mounted) {
      context.read<ThemeBloc>().add(SetBackgroundImage(pickedFile.path));
    }
  }

  Future<void> _removeBackgroundImage() async {
    context.read<ThemeBloc>().add(const SetBackgroundImage(null));
  }

  Future<void> _showColorPicker(
    BuildContext context,
    String title,
    Color currentColor,
    Function(Color) onColorChanged,
  ) async {
    Color selectedColor = currentColor;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: selectedColor,
            onColorChanged: (color) => selectedColor = color,
            pickersEnabled: const {
              ColorPickerType.wheel: true,
              ColorPickerType.accent: false,
            },
            enableShadesSelection: false,
            width: 44,
            height: 44,
            borderRadius: 8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(inherit: true, color: Theme.of(dialogContext).colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onColorChanged(selectedColor);
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Select',
              style: TextStyle(inherit: true, color: Theme.of(dialogContext).colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          // Handle error state
          if (state is ThemeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ThemeBloc>().add(const LoadTheme());
                    },
                    child: Text(
                      'Retry',
                      style: TextStyle(inherit: true, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                ],
              ),
            );
          }

          // Use default dark theme config as fallback for initial state
          final config = state is ThemeLoaded
              ? state.config
              : ThemeConfig.defaultDark();

          final isCustomMode = config.mode == AppThemeMode.custom;

          return ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              // Theme Mode Section
              const Text(
                'Theme Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              _buildThemeModeSelector(config.mode),
              const SizedBox(height: AppSizes.xl),

              // Custom Colors Section (only show in custom mode)
              if (isCustomMode) ...[
                const Text(
                  'Custom Colors',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                _buildColorOption(
                  'Primary Color',
                  config.primaryColor ?? Colors.white,
                  (color) {
                    context.read<ThemeBloc>().add(
                          UpdateCustomTheme(
                            primaryColor: color,
                            backgroundColor: config.backgroundColor,
                            textColor: config.textColor,
                          ),
                        );
                  },
                ),
                const SizedBox(height: AppSizes.sm),
                _buildColorOption(
                  'Background Color',
                  config.backgroundColor ?? Colors.black,
                  (color) {
                    context.read<ThemeBloc>().add(
                          UpdateCustomTheme(
                            primaryColor: config.primaryColor,
                            backgroundColor: color,
                            textColor: config.textColor,
                          ),
                        );
                  },
                ),
                const SizedBox(height: AppSizes.sm),
                _buildColorOption(
                  'Text Color',
                  config.textColor ?? Colors.white,
                  (color) {
                    context.read<ThemeBloc>().add(
                          UpdateCustomTheme(
                            primaryColor: config.primaryColor,
                            backgroundColor: config.backgroundColor,
                            textColor: color,
                          ),
                        );
                  },
                ),
                const SizedBox(height: AppSizes.xl),
              ],

              // Feed Background Section
              const Text(
                'Feed Background',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              _buildBackgroundImageSection(config.backgroundImagePath),
              const SizedBox(height: AppSizes.xl),

              // Reset Button
              OutlinedButton(
                onPressed: () {
                  context.read<ThemeBloc>().add(const ResetTheme());
                },
                child: Text(
                  'Reset to Default',
                  style: TextStyle(inherit: true, color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeModeSelector(AppThemeMode currentMode) {
    return Card(
      child: Column(
        children: [
          RadioListTile<AppThemeMode>(
            title: const Row(
              children: [
                HeroIcon(HeroIcons.sun, size: 20),
                SizedBox(width: AppSizes.sm),
                Text('Light Mode'),
              ],
            ),
            value: AppThemeMode.light,
            groupValue: currentMode,
            onChanged: (mode) {
              if (mode != null) {
                context.read<ThemeBloc>().add(ChangeThemeMode(mode));
              }
            },
          ),
          const Divider(height: 1),
          RadioListTile<AppThemeMode>(
            title: const Row(
              children: [
                HeroIcon(HeroIcons.moon, size: 20),
                SizedBox(width: AppSizes.sm),
                Text('Dark Mode'),
              ],
            ),
            value: AppThemeMode.dark,
            groupValue: currentMode,
            onChanged: (mode) {
              if (mode != null) {
                context.read<ThemeBloc>().add(ChangeThemeMode(mode));
              }
            },
          ),
          const Divider(height: 1),
          RadioListTile<AppThemeMode>(
            title: const Row(
              children: [
                HeroIcon(HeroIcons.paintBrush, size: 20),
                SizedBox(width: AppSizes.sm),
                Text('Custom'),
              ],
            ),
            value: AppThemeMode.custom,
            groupValue: currentMode,
            onChanged: (mode) {
              if (mode != null) {
                context.read<ThemeBloc>().add(ChangeThemeMode(mode));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(
    String label,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            const HeroIcon(HeroIcons.chevronRight, size: 20),
          ],
        ),
        onTap: () => _showColorPicker(context, label, currentColor, onColorChanged),
      ),
    );
  }

  Widget _buildBackgroundImageSection(String? imagePath) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagePath != null && imagePath.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: Image.file(
                  File(imagePath),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickBackgroundImage,
                      icon: const HeroIcon(HeroIcons.photo, size: 20),
                      label: Text(
                        'Change Image',
                        style: TextStyle(inherit: true, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _removeBackgroundImage,
                      icon: const HeroIcon(HeroIcons.trash, size: 20),
                      label: Text(
                        'Remove',
                        style: TextStyle(inherit: true, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'Set a custom background image for your feed',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: AppSizes.md),
              ElevatedButton.icon(
                onPressed: _pickBackgroundImage,
                icon: const HeroIcon(HeroIcons.photo, size: 20),
                label: Text(
                  'Select Background Image',
                  style: TextStyle(inherit: true, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
