// lib/screens/terminal_screen.dart
// Placeholder - will be fully implemented in Task 11
import 'package:flutter/material.dart';
import '../models/host.dart';

class TerminalScreen extends StatelessWidget {
  final Host host;

  const TerminalScreen({super.key, required this.host});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(host.name),
      ),
      body: Center(
        child: Text('Terminal Screen for ${host.name} - Coming Soon'),
      ),
    );
  }
}
