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
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isLiveMode => context.read<TerminalProvider>().isLiveInputMode;

  void _onTextChanged() {
    if (!_isLiveMode || _isSending) return;

    final value = _controller.value;

    // Only send when IME composing is done (Korean composition complete)
    if (value.composing.isCollapsed && value.text.isNotEmpty) {
      _isSending = true;
      context.read<TerminalProvider>().writeRaw(value.text);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.clear();
          _isSending = false;
        }
      });
    }
  }

  void _sendCommand() {
    final command = _controller.text;
    if (command.isEmpty) return;

    context.read<TerminalProvider>().sendCommand(command);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _sendSpecial(String seq) {
    context.read<TerminalProvider>().writeRaw(seq);
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
    final isLive = provider.isLiveInputMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Extra keys row
            _buildExtraKeysRow(isLive),
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
                  // Live mode toggle
                  _buildModeToggle(isLive),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: isLive
                            ? '한글 조합 완성 후 즉시 전송...'
                            : '명령어 입력...',
                        isDense: true,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (text) {
                        if (isLive) {
                          // Send any remaining text + carriage return
                          if (text.isNotEmpty) {
                            provider.writeRaw(text);
                          }
                          _sendSpecial('\r');
                          _controller.clear();
                          _focusNode.requestFocus();
                        } else {
                          _sendCommand();
                        }
                      },
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  if (!isLive) ...[
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.send),
                      onPressed: _sendCommand,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle(bool isLive) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        context.read<TerminalProvider>().toggleLiveInputMode();
        _controller.clear();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isLive ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLive ? Icons.flash_on : Icons.terminal,
              size: 16,
              color: isLive ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            Text(
              isLive ? '실시간' : '명령',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isLive ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraKeysRow(bool isLive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _extraKey('Esc', () => _sendSpecial('\x1b')),
          _extraKey('Tab', () => _sendSpecial('\t')),
          _extraKey('C-c', () => _sendSpecial('\x03')),
          _extraKey('C-d', () => _sendSpecial('\x04')),
          const Spacer(),
          _extraKey('\u25C0', () {
            if (isLive) {
              _sendSpecial('\x1b[D');
            }
          }),
          _extraKey('\u25B6', () {
            if (isLive) {
              _sendSpecial('\x1b[C');
            }
          }),
          _extraKey('\u25B2', () {
            if (isLive) {
              _sendSpecial('\x1b[A');
            } else {
              _navigateHistory(true);
            }
          }),
          _extraKey('\u25BC', () {
            if (isLive) {
              _sendSpecial('\x1b[B');
            } else {
              _navigateHistory(false);
            }
          }),
        ],
      ),
    );
  }

  Widget _extraKey(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
