// lib/screens/host_edit_screen.dart
// Placeholder - will be fully implemented in Task 10
import 'package:flutter/material.dart';
import '../models/host.dart';

class HostEditScreen extends StatelessWidget {
  final Host? host;

  const HostEditScreen({super.key, this.host});

  @override
  Widget build(BuildContext context) {
    final isEditing = host != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Host' : 'New Host'),
      ),
      body: Center(
        child: Text(isEditing ? 'Edit Host Screen - Coming Soon' : 'New Host Screen - Coming Soon'),
      ),
    );
  }
}
