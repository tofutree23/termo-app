// lib/providers/hosts_provider.dart
import 'package:flutter/foundation.dart';
import '../models/host.dart';
import '../services/storage_service.dart';

class HostsProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Host> _hosts = [];
  bool _isLoading = true;

  List<Host> get hosts => _hosts;
  bool get isLoading => _isLoading;

  Future<void> loadHosts() async {
    _isLoading = true;
    notifyListeners();

    _hosts = await _storageService.getHosts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addHost(Host host) async {
    await _storageService.saveHost(host);
    await loadHosts();
  }

  Future<void> updateHost(Host host) async {
    await _storageService.saveHost(host);
    await loadHosts();
  }

  Future<void> deleteHost(String id) async {
    await _storageService.deleteHost(id);
    await loadHosts();
  }

  Future<void> savePassword(String hostId, String password) async {
    await _storageService.savePassword(hostId, password);
  }

  Future<String?> getPassword(String hostId) async {
    return await _storageService.getPassword(hostId);
  }
}
