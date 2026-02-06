// lib/widgets/input_mode_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/host.dart';
import '../providers/terminal_provider.dart';

class InputModePanel extends StatefulWidget {
  final Host host;

  const InputModePanel({super.key, required this.host});

  @override
  State<InputModePanel> createState() => _InputModePanelState();
}

class _InputModePanelState extends State<InputModePanel> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendCommand() {
    final command = _controller.text;
    if (command.isEmpty) return;

    context.read<TerminalProvider>().sendCommand(command);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _navigateHistory(bool up) {
    final provider = context.read<TerminalProvider>();
    final command = up ? provider.getPreviousCommand() : provider.getNextCommand();
    if (command != null) {
      _controller.text = command;
      _controller.selection = TextSelection.collapsed(offset: command.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TerminalProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // History navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    onPressed: () => _navigateHistory(true),
                    tooltip: 'Previous command',
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 20),
                    onPressed: () => _navigateHistory(false),
                    tooltip: 'Next command',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'History: ${provider.commandHistory.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Quick command buttons
            if (widget.host.quickCommands.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: widget.host.quickCommands.length,
                  itemBuilder: (context, index) {
                    final cmd = widget.host.quickCommands[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(cmd),
                        onPressed: () => provider.sendCommand(cmd),
                      ),
                    );
                  },
                ),
              ),
            // Input field
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Enter command...',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendCommand(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _sendCommand,
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
