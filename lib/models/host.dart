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
