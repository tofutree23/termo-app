// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_theme.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(provider.currentTheme.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context),
          ),
          ListTile(
            title: const Text('Font Size'),
            subtitle: Text('${provider.fontSize.toInt()}'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: provider.fontSize,
                min: 8,
                max: 32,
                divisions: 24,
                label: provider.fontSize.toInt().toString(),
                onChanged: (v) => provider.setFontSize(v),
              ),
            ),
          ),
          const Divider(),
          const _SectionHeader(title: 'About'),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            title: Text('GitHub'),
            subtitle: Text('github.com/tofutree23/termo-app'),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final provider = context.read<SettingsProvider>();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...AppThemes.all.map(
              (theme) => ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.background,
                    border: Border.all(color: theme.foreground),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                title: Text(theme.name),
                trailing: provider.currentTheme.name == theme.name
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  provider.setTheme(theme);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
