// test/services/storage_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:termo/models/host.dart';
import 'package:termo/services/storage_service.dart';

void main() {
  group('StorageService', () {
    late StorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
    });

    test('should save and load hosts', () async {
      final host = Host(
        id: '1',
        name: 'Test Server',
        hostname: '192.168.1.1',
        username: 'user',
      );

      await storageService.saveHost(host);
      final hosts = await storageService.getHosts();

      expect(hosts.length, 1);
      expect(hosts.first.name, 'Test Server');
    });

    test('should delete host', () async {
      final host = Host(
        id: '1',
        name: 'Test Server',
        hostname: '192.168.1.1',
        username: 'user',
      );

      await storageService.saveHost(host);
      await storageService.deleteHost('1');
      final hosts = await storageService.getHosts();

      expect(hosts.length, 0);
    });
  });
}
