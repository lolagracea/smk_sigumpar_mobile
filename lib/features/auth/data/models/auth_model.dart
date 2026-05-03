// lib/features/auth/data/models/auth_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? accessToken;
  final String? refreshToken;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.accessToken,
    this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['sub']?.toString() ?? '',
      name: json['name']?.toString() ?? json['preferred_username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: _extractRole(json),
      accessToken: json['access_token']?.toString(),
      refreshToken: json['refresh_token']?.toString(),
    );
  }

  static String _extractRole(Map<String, dynamic> json) {
    // Cek resource_access dulu (Keycloak format)
    final resourceAccess = json['resource_access'];
    if (resourceAccess is Map) {
      final client = resourceAccess['smk-frontend'];
      if (client is Map) {
        final roles = client['roles'] as List?;
        if (roles != null && roles.isNotEmpty) return roles.first.toString();
      }
    }

    // Fallback ke realm_access
    final realmAccess = json['realm_access'];
    if (realmAccess is Map) {
      final roles = realmAccess['roles'] as List?;
      if (roles != null) {
        for (final r in roles) {
          if (r.toString().startsWith('guru')) return r.toString();
        }
      }
    }

    return json['role']?.toString() ?? 'guru-mapel';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
  };

  String get displayRole {
    switch (role) {
      case 'guru-mapel':
        return 'Guru Mata Pelajaran';
      case 'wali-kelas':
        return 'Wali Kelas';
      case 'kepala-sekolah':
        return 'Kepala Sekolah';
      case 'wakil-kepala-sekolah':
        return 'Wakil Kepala Sekolah';
      case 'tata-usaha':
        return 'Tata Usaha';
      case 'pramuka':
        return 'Pembina Pramuka';
      case 'piket':
        return 'Guru Piket';
      default:
        return role;
    }
  }

  String get inisial {
    final words = name.split(' ');
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'G';
  }
}