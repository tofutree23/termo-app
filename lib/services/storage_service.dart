// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/host.dart';

class StorageService {
  static const _hostsKey = 'hosts';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<List<Host>> getHosts() async {
    final prefs = await SharedPreferences.getInstance();
    final hostsJson = prefs.getString(_hostsKey);
    if (hostsJson == null) return [];

    final List<dynamic> hostsList = jsonDecode(hostsJson);
    return hostsList.map((json) => Host.fromJson(json)).toList();
  }

  Future<void> saveHost(Host host) async {
    final hosts = await getHosts();
    final index = hosts.indexWhere((h) => h.id == host.id);

    if (index >= 0) {
      hosts[index] = host;
    } else {
      hosts.add(host);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _hostsKey,
      jsonEncode(hosts.map((h) => h.toJson()).toList()),
    );
  }

  Future<void> deleteHost(String id) async {
    final hosts = await getHosts();
    hosts.removeWhere((h) => h.id == id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _hostsKey,
      jsonEncode(hosts.map((h) => h.toJson()).toList()),
    );
  }

  // 비밀번호는 암호화 저장
  Future<void> savePassword(String hostId, String password) async {
    await _secureStorage.write(key: 'password_$hostId', value: password);
  }

  Future<String?> getPassword(String hostId) async {
    return await _secureStorage.read(key: 'password_$hostId');
  }

  Future<void> deletePassword(String hostId) async {
    await _secureStorage.delete(key: 'password_$hostId');
  }

  // SSH 키 저장
  Future<void> savePrivateKey(String hostId, String privateKey) async {
    await _secureStorage.write(key: 'privateKey_$hostId', value: privateKey);
  }

  Future<String?> getPrivateKey(String hostId) async {
    return await _secureStorage.read(key: 'privateKey_$hostId');
  }
}
