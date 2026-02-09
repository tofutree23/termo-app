// lib/screens/terminal_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../models/host.dart';
import '../providers/terminal_provider.dart';
import '../providers/hosts_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/input_mode_panel.dart';

class TerminalScreen extends StatefulWidget {
  final Host host;

  const TerminalScreen({super.key, required this.host});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late Terminal _terminal;
  late TerminalController _terminalController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);
    _terminalController = TerminalController();
    _connect();
  }

  Future<void> _connect() async {
    final terminalProvider = context.read<TerminalProvider>();
    final hostsProvider = context.read<HostsProvider>();

    String? password;
    if (widget.host.authType == AuthType.password) {
      password = await hostsProvider.getPassword(widget.host.id);
      if (password == null && mounted) {
        password = await _showPasswordDialog();
        if (password == null) {
          Navigator.pop(context);
          return;
        }
      }
    }

    try {
      await terminalProvider.connect(widget.host, password: password);

      terminalProvider.sshService.stdout?.cast<List<int>>().transform(utf8.decoder).listen((data) {
        _terminal.write(data);
      });

      terminalProvider.sshService.stderr?.cast<List<int>>().transform(utf8.decoder).listen((data) {
        _terminal.write(data);
      });

      _terminal.onOutput = (data) {
        terminalProvider.sshService.write(data);
      };
    } catch (e, stackTrace) {
      debugPrint('SSH connection error: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _error = '$e');
    }
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Password'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    context.read<TerminalProvider>().disconnect();
    _terminalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final terminalProvider = context.watch<TerminalProvider>();
    final theme = settingsProvider.currentTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.host.name),
        actions: [
          IconButton(
            icon: Icon(
              terminalProvider.isInputModeEnabled
                  ? Icons.keyboard_hide
                  : Icons.keyboard,
            ),
            onPressed: () => terminalProvider.toggleInputMode(),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    SelectableText(
                      'Connection failed:\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _connect();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : terminalProvider.isConnecting
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: TerminalView(
                        _terminal,
                        controller: _terminalController,
                        keyboardType: TextInputType.text,
                        deleteDetection: true,
                        textStyle: TerminalStyle(
                          fontSize: settingsProvider.fontSize,
                        ),
                        theme: TerminalTheme(
                          cursor: theme.cursor,
                          selection: theme.selection,
                          foreground: theme.foreground,
                          background: theme.background,
                          black: theme.black,
                          white: theme.white,
                          red: theme.red,
                          green: theme.green,
                          yellow: theme.yellow,
                          blue: theme.blue,
                          magenta: theme.magenta,
                          cyan: theme.cyan,
                          brightBlack: theme.black,
                          brightWhite: theme.white,
                          brightRed: theme.red,
                          brightGreen: theme.green,
                          brightYellow: theme.yellow,
                          brightBlue: theme.blue,
                          brightMagenta: theme.magenta,
                          brightCyan: theme.cyan,
                          searchHitBackground: theme.selection,
                          searchHitBackgroundCurrent: theme.cursor,
                          searchHitForeground: theme.background,
                        ),
                      ),
                    ),
                    if (terminalProvider.isInputModeEnabled)
                      InputModePanel(host: widget.host),
                  ],
                ),
    );
  }
}
