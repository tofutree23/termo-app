// test/models/host_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:termo/models/host.dart';

void main() {
  group('Host', () {
    test('should create host with required fields', () {
      final host = Host(
        id: '1',
        name: 'My Server',
        hostname: '192.168.1.100',
        username: 'ubuntu',
      );

      expect(host.id, '1');
      expect(host.name, 'My Server');
      expect(host.hostname, '192.168.1.100');
      expect(host.username, 'ubuntu');
      expect(host.port, 22); // default
    });

    test('should convert to/from JSON', () {
      final host = Host(
        id: '1',
        name: 'My Server',
        hostname: '192.168.1.100',
        username: 'ubuntu',
        port: 2222,
      );

      final json = host.toJson();
      final restored = Host.fromJson(json);

      expect(restored.id, host.id);
      expect(restored.name, host.name);
      expect(restored.port, 2222);
    });
  });
}
