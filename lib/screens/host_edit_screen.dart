// lib/screens/host_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/host.dart';
import '../providers/hosts_provider.dart';

class HostEditScreen extends StatefulWidget {
  final Host? host;

  const HostEditScreen({super.key, this.host});

  @override
  State<HostEditScreen> createState() => _HostEditScreenState();
}

class _HostEditScreenState extends State<HostEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hostnameController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  AuthType _authType = AuthType.password;
  bool _savePassword = false;

  bool get isEditing => widget.host != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.host?.name ?? '');
    _hostnameController = TextEditingController(text: widget.host?.hostname ?? '');
    _portController = TextEditingController(text: (widget.host?.port ?? 22).toString());
    _usernameController = TextEditingController(text: widget.host?.username ?? '');
    _passwordController = TextEditingController();
    _authType = widget.host?.authType ?? AuthType.password;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostnameController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<HostsProvider>();
    final host = Host(
      id: widget.host?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      hostname: _hostnameController.text,
      port: int.tryParse(_portController.text) ?? 22,
      username: _usernameController.text,
      authType: _authType,
      quickCommands: widget.host?.quickCommands ?? [],
    );

    if (isEditing) {
      await provider.updateHost(host);
    } else {
      await provider.addHost(host);
    }

    if (_savePassword && _passwordController.text.isNotEmpty) {
      await provider.savePassword(host.id, _passwordController.text);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Host' : 'New Host'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'My Server',
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hostnameController,
              decoration: const InputDecoration(
                labelText: 'Hostname',
                hintText: '192.168.1.100 or example.com',
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '22',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'root',
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            SegmentedButton<AuthType>(
              segments: const [
                ButtonSegment(
                  value: AuthType.password,
                  label: Text('Password'),
                  icon: Icon(Icons.password),
                ),
                ButtonSegment(
                  value: AuthType.privateKey,
                  label: Text('SSH Key'),
                  icon: Icon(Icons.key),
                ),
              ],
              selected: {_authType},
              onSelectionChanged: (set) => setState(() => _authType = set.first),
            ),
            const SizedBox(height: 16),
            if (_authType == AuthType.password) ...[
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Leave empty to enter on connect',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Save password'),
                value: _savePassword,
                onChanged: (v) => setState(() => _savePassword = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
