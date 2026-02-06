// lib/widgets/input_mode_panel.dart
// Placeholder - will be fully implemented in Task 12
import 'package:flutter/material.dart';
import '../models/host.dart';

class InputModePanel extends StatelessWidget {
  final Host host;

  const InputModePanel({super.key, required this.host});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Theme.of(context).colorScheme.surface,
      child: const Text('Input Mode Panel - Coming Soon'),
    );
  }
}
