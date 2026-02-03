// lib/services/ssh_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../models/host.dart';

class SSHService {
  SSHClient? _client;
  SSHSession? _session;

  bool get isConnected => _client != null;

  Future<void> connect({
    required Host host,
    String? password,
    String? privateKey,
  }) async {
    final socket = await SSHSocket.connect(host.hostname, host.port);

    _client = SSHClient(
      socket,
      username: host.username,
      onPasswordRequest: password != null ? () => password : null,
      identities: privateKey != null
          ? [SSHKeyPair.fromPem(privateKey)]
          : null,
    );

    _session = await _client!.shell(
      pty: SSHPtyConfig(
        width: 80,
        height: 24,
      ),
    );
  }

  Stream<Uint8List>? get stdout => _session?.stdout;
  Stream<Uint8List>? get stderr => _session?.stderr;

  void write(String data) {
    _session?.write(Uint8List.fromList(data.codeUnits));
  }

  void resize(int width, int height) {
    _session?.resizeTerminal(width, height);
  }

  Future<void> disconnect() async {
    _session?.close();
    _client?.close();
    _session = null;
    _client = null;
  }
}
