import 'package:flutter/foundation.dart';
import '../models/host.dart';
import '../services/ssh_service.dart';

class TerminalProvider extends ChangeNotifier {
  final SSHService _sshService = SSHService();
  Host? _currentHost;
  bool _isConnecting = false;
  bool _isInputModeEnabled = false;
  List<String> _commandHistory = [];
  int _historyIndex = -1;

  Host? get currentHost => _currentHost;
  bool get isConnected => _sshService.isConnected;
  bool get isConnecting => _isConnecting;
  bool get isInputModeEnabled => _isInputModeEnabled;
  List<String> get commandHistory => _commandHistory;
  SSHService get sshService => _sshService;

  void toggleInputMode() {
    _isInputModeEnabled = !_isInputModeEnabled;
    notifyListeners();
  }

  Future<void> connect(Host host, {String? password, String? privateKey}) async {
    _isConnecting = true;
    _currentHost = host;
    notifyListeners();

    try {
      await _sshService.connect(
        host: host,
        password: password,
        privateKey: privateKey,
      );
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  void sendCommand(String command) {
    _sshService.write('$command\n');
    if (command.isNotEmpty && (commandHistory.isEmpty || commandHistory.last != command)) {
      _commandHistory.add(command);
    }
    _historyIndex = _commandHistory.length;
    notifyListeners();
  }

  String? getPreviousCommand() {
    if (_commandHistory.isEmpty) return null;
    if (_historyIndex > 0) _historyIndex--;
    return _commandHistory[_historyIndex];
  }

  String? getNextCommand() {
    if (_historyIndex < _commandHistory.length - 1) {
      _historyIndex++;
      return _commandHistory[_historyIndex];
    }
    _historyIndex = _commandHistory.length;
    return '';
  }

  Future<void> disconnect() async {
    await _sshService.disconnect();
    _currentHost = null;
    notifyListeners();
  }
}
