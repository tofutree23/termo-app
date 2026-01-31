# Termo Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** iOS용 미니멀 SSH 터미널 앱 구현 - 토글 입력 모드, 호스트 관리, 테마 지원

**Architecture:** Flutter 앱으로 dartssh2(SSH 연결)와 xterm.dart(터미널 렌더링) 사용. Provider로 상태 관리. 호스트 정보는 로컬 저장, 민감 정보는 암호화 저장.

**Tech Stack:** Flutter 3.x, Dart, dartssh2, xterm, provider, flutter_secure_storage

**Reference:**
- [dartssh2](https://pub.dev/packages/dartssh2) - SSH/SFTP 클라이언트
- [xterm.dart](https://pub.dev/packages/xterm) - 터미널 에뮬레이터

---

## Phase 1: 환경 설정

### Task 1: Flutter 설치 및 환경 구성

**Step 1: Flutter SDK 설치**

```bash
brew install --cask flutter
```

**Step 2: Flutter 설치 확인**

Run: `flutter --version`
Expected: Flutter 버전 정보 출력

**Step 3: Flutter doctor 실행**

Run: `flutter doctor`
Expected: iOS 개발 환경 체크 (Xcode 필요)

**Step 4: iOS 시뮬레이터 확인**

Run: `open -a Simulator`
Expected: iOS 시뮬레이터 실행

---

### Task 2: Flutter 프로젝트 초기화

**Files:**
- Create: `lib/main.dart`
- Create: `pubspec.yaml`
- Create: `ios/`, `android/`, `test/` 디렉토리들

**Step 1: Flutter 프로젝트 생성**

```bash
cd /Users/luke/claude-space/dev/termo-app
flutter create . --org com.tofutree --project-name termo
```

**Step 2: 프로젝트 구조 확인**

Run: `ls -la`
Expected: lib/, ios/, android/, pubspec.yaml 등 생성됨

**Step 3: 의존성 추가**

Modify: `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  dartssh2: ^2.9.0
  xterm: ^3.2.6
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

**Step 4: 의존성 설치**

Run: `flutter pub get`
Expected: 모든 패키지 다운로드 성공

**Step 5: 앱 실행 테스트**

Run: `flutter run`
Expected: iOS 시뮬레이터에 기본 Flutter 앱 실행

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: initialize Flutter project with dependencies"
```

---

## Phase 2: 데이터 모델 및 서비스

### Task 3: Host 모델 생성

**Files:**
- Create: `lib/models/host.dart`
- Create: `test/models/host_test.dart`

**Step 1: 테스트 파일 작성**

```dart
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
```

**Step 2: 테스트 실행 (실패 확인)**

Run: `flutter test test/models/host_test.dart`
Expected: FAIL - Host 클래스 없음

**Step 3: Host 모델 구현**

```dart
// lib/models/host.dart
enum AuthType { password, privateKey }

class Host {
  final String id;
  final String name;
  final String hostname;
  final int port;
  final String username;
  final AuthType authType;
  final List<String> quickCommands;

  Host({
    required this.id,
    required this.name,
    required this.hostname,
    required this.username,
    this.port = 22,
    this.authType = AuthType.password,
    this.quickCommands = const [],
  });

  Host copyWith({
    String? id,
    String? name,
    String? hostname,
    int? port,
    String? username,
    AuthType? authType,
    List<String>? quickCommands,
  }) {
    return Host(
      id: id ?? this.id,
      name: name ?? this.name,
      hostname: hostname ?? this.hostname,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      quickCommands: quickCommands ?? this.quickCommands,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hostname': hostname,
      'port': port,
      'username': username,
      'authType': authType.name,
      'quickCommands': quickCommands,
    };
  }

  factory Host.fromJson(Map<String, dynamic> json) {
    return Host(
      id: json['id'] as String,
      name: json['name'] as String,
      hostname: json['hostname'] as String,
      port: json['port'] as int? ?? 22,
      username: json['username'] as String,
      authType: AuthType.values.firstWhere(
        (e) => e.name == json['authType'],
        orElse: () => AuthType.password,
      ),
      quickCommands: List<String>.from(json['quickCommands'] ?? []),
    );
  }
}
```

**Step 4: 테스트 실행 (성공 확인)**

Run: `flutter test test/models/host_test.dart`
Expected: All tests passed

**Step 5: Commit**

```bash
git add lib/models/host.dart test/models/host_test.dart
git commit -m "feat: add Host model with JSON serialization"
```

---

### Task 4: Storage Service 구현

**Files:**
- Create: `lib/services/storage_service.dart`
- Create: `test/services/storage_service_test.dart`

**Step 1: 테스트 파일 작성**

```dart
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
```

**Step 2: 테스트 실행 (실패 확인)**

Run: `flutter test test/services/storage_service_test.dart`
Expected: FAIL - StorageService 없음

**Step 3: StorageService 구현**

```dart
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
```

**Step 4: 테스트 실행 (성공 확인)**

Run: `flutter test test/services/storage_service_test.dart`
Expected: All tests passed

**Step 5: Commit**

```bash
git add lib/services/storage_service.dart test/services/storage_service_test.dart
git commit -m "feat: add StorageService for host persistence"
```

---

### Task 5: SSH Service 구현

**Files:**
- Create: `lib/services/ssh_service.dart`

**Step 1: SSH Service 구현**

```dart
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
```

**Step 2: Commit**

```bash
git add lib/services/ssh_service.dart
git commit -m "feat: add SSHService for SSH connection management"
```

---

## Phase 3: 테마 시스템

### Task 6: 테마 모델 및 프리셋 구현

**Files:**
- Create: `lib/models/app_theme.dart`

**Step 1: 테마 모델 구현**

```dart
// lib/models/app_theme.dart
import 'package:flutter/material.dart';

class TerminalTheme {
  final String name;
  final Color background;
  final Color foreground;
  final Color cursor;
  final Color selection;
  final Color black;
  final Color red;
  final Color green;
  final Color yellow;
  final Color blue;
  final Color magenta;
  final Color cyan;
  final Color white;

  const TerminalTheme({
    required this.name,
    required this.background,
    required this.foreground,
    required this.cursor,
    required this.selection,
    required this.black,
    required this.red,
    required this.green,
    required this.yellow,
    required this.blue,
    required this.magenta,
    required this.cyan,
    required this.white,
  });
}

class AppThemes {
  static const termoDark = TerminalTheme(
    name: 'Termo Dark',
    background: Color(0xFF1A1A1A),
    foreground: Color(0xFFE0E0E0),
    cursor: Color(0xFFE0E0E0),
    selection: Color(0xFF404040),
    black: Color(0xFF000000),
    red: Color(0xFFFF5555),
    green: Color(0xFF50FA7B),
    yellow: Color(0xFFF1FA8C),
    blue: Color(0xFF6272A4),
    magenta: Color(0xFFFF79C6),
    cyan: Color(0xFF8BE9FD),
    white: Color(0xFFFFFFFF),
  );

  static const termoLight = TerminalTheme(
    name: 'Termo Light',
    background: Color(0xFFFAFAFA),
    foreground: Color(0xFF2E3440),
    cursor: Color(0xFF2E3440),
    selection: Color(0xFFD8DEE9),
    black: Color(0xFF3B4252),
    red: Color(0xFFBF616A),
    green: Color(0xFFA3BE8C),
    yellow: Color(0xFFEBCB8B),
    blue: Color(0xFF5E81AC),
    magenta: Color(0xFFB48EAD),
    cyan: Color(0xFF88C0D0),
    white: Color(0xFFECEFF4),
  );

  static const dracula = TerminalTheme(
    name: 'Dracula',
    background: Color(0xFF282A36),
    foreground: Color(0xFFF8F8F2),
    cursor: Color(0xFFF8F8F2),
    selection: Color(0xFF44475A),
    black: Color(0xFF21222C),
    red: Color(0xFFFF5555),
    green: Color(0xFF50FA7B),
    yellow: Color(0xFFF1FA8C),
    blue: Color(0xFF6272A4),
    magenta: Color(0xFFFF79C6),
    cyan: Color(0xFF8BE9FD),
    white: Color(0xFFF8F8F2),
  );

  static const List<TerminalTheme> all = [termoDark, termoLight, dracula];
}
```

**Step 2: Commit**

```bash
git add lib/models/app_theme.dart
git commit -m "feat: add terminal theme system with 3 presets"
```

---

## Phase 4: Provider 상태 관리

### Task 7: Providers 구현

**Files:**
- Create: `lib/providers/hosts_provider.dart`
- Create: `lib/providers/terminal_provider.dart`
- Create: `lib/providers/settings_provider.dart`

**Step 1: HostsProvider 구현**

```dart
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
```

**Step 2: TerminalProvider 구현**

```dart
// lib/providers/terminal_provider.dart
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
```

**Step 3: SettingsProvider 구현**

```dart
// lib/providers/settings_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme.dart';

class SettingsProvider extends ChangeNotifier {
  TerminalTheme _currentTheme = AppThemes.termoDark;
  double _fontSize = 14.0;

  TerminalTheme get currentTheme => _currentTheme;
  double get fontSize => _fontSize;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme') ?? 'Termo Dark';
    final fontSize = prefs.getDouble('fontSize') ?? 14.0;

    _currentTheme = AppThemes.all.firstWhere(
      (t) => t.name == themeName,
      orElse: () => AppThemes.termoDark,
    );
    _fontSize = fontSize;
    notifyListeners();
  }

  Future<void> setTheme(TerminalTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme.name);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(8.0, 32.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    notifyListeners();
  }
}
```

**Step 4: Commit**

```bash
git add lib/providers/
git commit -m "feat: add state management providers"
```

---

## Phase 5: UI 구현

### Task 8: Main App 및 라우팅

**Files:**
- Modify: `lib/main.dart`

**Step 1: main.dart 구현**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/hosts_provider.dart';
import 'providers/terminal_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TermoApp());
}

class TermoApp extends StatelessWidget {
  const TermoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HostsProvider()..loadHosts()),
        ChangeNotifierProvider(create: (_) => TerminalProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
      ],
      child: MaterialApp(
        title: 'Termo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6272A4),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "feat: setup main app with providers"
```

---

### Task 9: Home Screen (호스트 목록)

**Files:**
- Create: `lib/screens/home_screen.dart`

**Step 1: HomeScreen 구현**

```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/host.dart';
import '../providers/hosts_provider.dart';
import 'terminal_screen.dart';
import 'host_edit_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<HostsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hosts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.computer,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hosts yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first server'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.hosts.length,
            itemBuilder: (context, index) {
              final host = provider.hosts[index];
              return _HostCard(host: host);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HostEditScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  final Host host;

  const _HostCard({required this.host});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.computer, size: 40),
        title: Text(host.name),
        subtitle: Text('${host.username}@${host.hostname}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HostEditScreen(host: host),
                ),
              );
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Host'),
                  content: Text('Delete "${host.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                context.read<HostsProvider>().deleteHost(host.id);
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TerminalScreen(host: host),
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/screens/home_screen.dart
git commit -m "feat: add HomeScreen with host list"
```

---

### Task 10: Host Edit Screen

**Files:**
- Create: `lib/screens/host_edit_screen.dart`

**Step 1: HostEditScreen 구현**

```dart
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
```

**Step 2: Commit**

```bash
git add lib/screens/host_edit_screen.dart
git commit -m "feat: add HostEditScreen for adding/editing hosts"
```

---

### Task 11: Terminal Screen 기본 구조

**Files:**
- Create: `lib/screens/terminal_screen.dart`

**Step 1: TerminalScreen 기본 구현**

```dart
// lib/screens/terminal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

      terminalProvider.sshService.stdout?.listen((data) {
        _terminal.write(String.fromCharCodes(data));
      });

      terminalProvider.sshService.stderr?.listen((data) {
        _terminal.write(String.fromCharCodes(data));
      });

      _terminal.onOutput = (data) {
        terminalProvider.sshService.write(data);
      };
    } catch (e) {
      setState(() => _error = e.toString());
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Connection failed: $_error'),
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
            )
          : terminalProvider.isConnecting
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: TerminalView(
                        _terminal,
                        controller: _terminalController,
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
```

**Step 2: Commit**

```bash
git add lib/screens/terminal_screen.dart
git commit -m "feat: add TerminalScreen with xterm integration"
```

---

### Task 12: Input Mode Panel 위젯

**Files:**
- Create: `lib/widgets/input_mode_panel.dart`

**Step 1: InputModePanel 구현**

```dart
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
```

**Step 2: Commit**

```bash
git add lib/widgets/input_mode_panel.dart
git commit -m "feat: add InputModePanel with history and quick commands"
```

---

### Task 13: Settings Screen

**Files:**
- Create: `lib/screens/settings_screen.dart`

**Step 1: SettingsScreen 구현**

```dart
// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_theme.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(provider.currentTheme.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context),
          ),
          ListTile(
            title: const Text('Font Size'),
            subtitle: Text('${provider.fontSize.toInt()}'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: provider.fontSize,
                min: 8,
                max: 32,
                divisions: 24,
                label: provider.fontSize.toInt().toString(),
                onChanged: (v) => provider.setFontSize(v),
              ),
            ),
          ),
          const Divider(),
          const _SectionHeader(title: 'About'),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            title: const Text('GitHub'),
            subtitle: const Text('github.com/tofutree23/termo-app'),
            onTap: () {
              // TODO: Open URL
            },
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final provider = context.read<SettingsProvider>();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...AppThemes.all.map(
              (theme) => ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.background,
                    border: Border.all(color: theme.foreground),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                title: Text(theme.name),
                trailing: provider.currentTheme.name == theme.name
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  provider.setTheme(theme);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/screens/settings_screen.dart
git commit -m "feat: add SettingsScreen with theme and font size"
```

---

## Phase 6: 통합 테스트 및 마무리

### Task 14: 앱 실행 및 통합 테스트

**Step 1: 앱 빌드 확인**

Run: `flutter build ios --debug --no-codesign`
Expected: 빌드 성공

**Step 2: 시뮬레이터에서 앱 실행**

Run: `flutter run`
Expected: iOS 시뮬레이터에서 앱 실행, 홈 화면 표시

**Step 3: 기본 기능 테스트**

수동 테스트 체크리스트:
- [ ] 호스트 추가/편집/삭제
- [ ] 테마 변경
- [ ] 폰트 크기 조절

**Step 4: 최종 Commit**

```bash
git add -A
git commit -m "feat: complete Termo MVP implementation"
```

---

## Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| 1 | 1-2 | 환경 설정, Flutter 프로젝트 초기화 |
| 2 | 3-5 | 데이터 모델 및 서비스 (Host, Storage, SSH) |
| 3 | 6 | 테마 시스템 |
| 4 | 7 | Provider 상태 관리 |
| 5 | 8-13 | UI 구현 (화면 및 위젯) |
| 6 | 14 | 통합 테스트 |

**Total: 14 Tasks**
