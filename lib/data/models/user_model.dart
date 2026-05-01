import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;

  /// Dipertahankan karena banyak file project kamu masih memakai user.name
  final String name;

  final String username;
  final String? email;

  /// Role utama untuk tampilan/debug.
  /// Untuk pengecekan menu, gunakan roles atau hasRole().
  final String role;

  /// Semua role dari Keycloak realm_access.roles.
  final List<String> roles;

  const UserModel({
    required this.id,
    required this.name,
    this.username = '',
    this.email,
    this.role = 'user',
    this.roles = const [],
  });

  String get fullName => name;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final parsedRoles = _parseRoles(json['roles'] ?? json['role']);
    final selectedRole = _selectPrimaryRole(
      parsedRoles,
      fallback: json['role']?.toString(),
    );

    final username = json['username']?.toString() ??
        json['preferred_username']?.toString() ??
        '';

    final name = json['name']?.toString() ??
        json['full_name']?.toString() ??
        _buildFullName(
          json['given_name']?.toString(),
          json['family_name']?.toString(),
        ) ??
        username.ifEmpty('Pengguna');

    return UserModel(
      id: json['id']?.toString() ?? json['sub']?.toString() ?? '',
      name: name,
      username: username,
      email: json['email']?.toString(),
      role: selectedRole,
      roles: parsedRoles,
    );
  }

  factory UserModel.fromTokenPayload(Map<String, dynamic> payload) {
    final realmAccess = payload['realm_access'];
    final rawRealmRoles = realmAccess is Map ? realmAccess['roles'] : null;

    final resourceAccess = payload['resource_access'];
    final accountAccess =
    resourceAccess is Map ? resourceAccess['account'] : null;
    final rawAccountRoles = accountAccess is Map ? accountAccess['roles'] : null;

    final roles = <String>{
      ..._parseRoles(rawRealmRoles),
      ..._parseRoles(rawAccountRoles),
    }.toList();

    final selectedRole = _selectPrimaryRole(roles);

    final username = payload['preferred_username']?.toString() ?? '';

    final name = payload['name']?.toString() ??
        _buildFullName(
          payload['given_name']?.toString(),
          payload['family_name']?.toString(),
        ) ??
        username.ifEmpty('Pengguna');

    return UserModel(
      id: payload['sub']?.toString() ?? '',
      name: name,
      username: username,
      email: payload['email']?.toString(),
      role: selectedRole,
      roles: roles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'roles': roles,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? role,
    List<String>? roles,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      roles: roles ?? this.roles,
    );
  }

  bool hasRole(String roleName) {
    return roles.contains(roleName);
  }

  bool hasAnyRole(List<String> roleNames) {
    return roleNames.any(roles.contains);
  }

  bool get isTataUsaha => hasRole('tata-usaha');
  bool get isKepalaSekolah => hasRole('kepala-sekolah');
  bool get isWakaSekolah => hasRole('waka-sekolah');
  bool get isGuruMapel => hasRole('guru-mapel');
  bool get isWaliKelas => hasRole('wali-kelas');
  bool get isPramuka => hasRole('pramuka');
  bool get isVokasi => hasRole('vokasi');

  static List<String> _parseRoles(dynamic rawRoles) {
    if (rawRoles == null) return [];

    if (rawRoles is List) {
      return rawRoles
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toSet()
          .toList();
    }

    if (rawRoles is String) {
      if (rawRoles.trim().isEmpty) return [];

      if (rawRoles.contains(',')) {
        return rawRoles
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();
      }

      return [rawRoles.trim()];
    }

    return [];
  }

  static String _selectPrimaryRole(
      List<String> roles, {
        String? fallback,
      }) {
    if (roles.contains('tata-usaha')) return 'tata-usaha';
    if (roles.contains('kepala-sekolah')) return 'kepala-sekolah';
    if (roles.contains('waka-sekolah')) return 'waka-sekolah';
    if (roles.contains('guru-mapel')) return 'guru-mapel';
    if (roles.contains('wali-kelas')) return 'wali-kelas';
    if (roles.contains('vokasi')) return 'vokasi';
    if (roles.contains('pramuka')) return 'pramuka';

    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback.trim();
    }

    return roles.isNotEmpty ? roles.first : 'user';
  }

  static String? _buildFullName(String? givenName, String? familyName) {
    final parts = [
      if (givenName != null && givenName.trim().isNotEmpty) givenName.trim(),
      if (familyName != null && familyName.trim().isNotEmpty)
        familyName.trim(),
    ];

    if (parts.isEmpty) return null;

    return parts.join(' ');
  }

  @override
  List<Object?> get props => [
    id,
    name,
    username,
    email,
    role,
    roles,
  ];
}

extension _StringEmptyExt on String {
  String ifEmpty(String fallback) {
    return trim().isEmpty ? fallback : this;
  }
}