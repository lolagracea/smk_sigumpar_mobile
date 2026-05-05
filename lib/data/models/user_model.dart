import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String username;
  final String email;

  /// Role utama user.
  ///
  /// Contoh:
  /// kepala-sekolah
  final String role;

  /// Semua role user.
  ///
  /// Contoh:
  /// ['kepala-sekolah', 'tata-usaha']
  final List<String> roles;

  final String? photoUrl;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    this.roles = const [],
    this.photoUrl,
    this.phone,
    this.isActive = true,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final parsedRoles = _parseRoles(json);

    final primaryRole = json['role']?.toString() ??
        (parsedRoles.isNotEmpty ? parsedRoles.first : '');

    return UserModel(
      id: json['id']?.toString() ?? json['sub']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['nama_lengkap']?.toString() ??
          json['preferred_username']?.toString() ??
          json['username']?.toString() ??
          '',
      username: json['username']?.toString() ??
          json['preferred_username']?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      role: primaryRole,
      roles: parsedRoles.isNotEmpty
          ? parsedRoles
          : primaryRole.isNotEmpty
          ? [primaryRole]
          : const [],
      photoUrl: json['photo_url']?.toString(),
      phone: json['phone']?.toString(),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  static List<String> _parseRoles(Map<String, dynamic> json) {
    final result = <String>{};

    final rawRoles = json['roles'];

    if (rawRoles is List) {
      result.addAll(
        rawRoles
            .map((role) => role.toString().trim())
            .where((role) => role.isNotEmpty),
      );
    }

    if (rawRoles is String && rawRoles.trim().isNotEmpty) {
      result.addAll(
        rawRoles
            .split(RegExp(r'[,;|]+'))
            .map((role) => role.trim())
            .where((role) => role.isNotEmpty),
      );
    }

    final rawRole = json['role'];

    if (rawRole is String && rawRole.trim().isNotEmpty) {
      result.addAll(
        rawRole
            .split(RegExp(r'[,;|]+'))
            .map((role) => role.trim())
            .where((role) => role.isNotEmpty),
      );
    }

    return result.toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'roles': roles,
      'photo_url': photoUrl,
      'phone': phone,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? role,
    List<String>? roles,
    String? photoUrl,
    String? phone,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    username,
    email,
    role,
    roles,
    photoUrl,
    phone,
    isActive,
    createdAt,
  ];
}