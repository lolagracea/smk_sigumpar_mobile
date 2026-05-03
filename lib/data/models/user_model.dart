import 'package:equatable/equatable.dart';

/// ─────────────────────────────────────────────────────────────
/// UserModel — Model user dengan MULTI-ROLE support
///
/// PERUBAHAN dari versi lama:
/// - `String role` → `List<String> roles` + `String primaryRole`
/// - `fromJson` membaca array roles dari response backend/JWT
/// - Backward compatible: `role` getter tetap ada (alias primaryRole)
///
/// Format response backend yang diharapkan:
/// {
///   "name": "User",
///   "roles": ["kepala_sekolah", "guru", "pramuka"],
///   "primary_role": "kepala_sekolah",
///   "token": "xxx"
/// }
/// ─────────────────────────────────────────────────────────────
class UserModel extends Equatable {
  final String id;
  final String name;
  final String username;
  final String email;

  /// Semua role yang dimiliki user (multi-role)
  final List<String> roles;

  /// Role utama / prioritas tertinggi
  final String primaryRole;

  final String? photoUrl;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.roles,
    required this.primaryRole,
    this.photoUrl,
    this.phone,
    this.isActive = true,
    this.createdAt,
  });

  /// Backward compatibility getter — alias untuk primaryRole
  /// Gunakan ini untuk fitur yang hanya butuh 1 role (label, redirect, dsb)
  String get role => primaryRole;

  /// Cek apakah user punya role tertentu
  bool hasRole(String role) => roles.contains(role);

  /// Cek apakah user punya salah satu dari daftar role
  bool hasAnyRole(List<String> checkRoles) =>
      checkRoles.any((r) => roles.contains(r));

  // ─── fromJson ─────────────────────────────────────────────
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse roles — support berbagai format response
    List<String> parsedRoles = [];

    if (json['roles'] is List) {
      parsedRoles = (json['roles'] as List).map((r) => r.toString()).toList();
    } else if (json['role'] is String && (json['role'] as String).isNotEmpty) {
      // Fallback: kalau backend kirim single role string
      parsedRoles = [json['role'] as String];
    }

    // Parse primary role
    String parsedPrimary = json['primary_role']?.toString() ?? '';
    if (parsedPrimary.isEmpty && parsedRoles.isNotEmpty) {
      parsedPrimary = parsedRoles.first;
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      roles: parsedRoles,
      primaryRole: parsedPrimary,
      photoUrl: json['photo_url'],
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'email': email,
        'roles': roles,
        'primary_role': primaryRole,
        'photo_url': photoUrl,
        'phone': phone,
        'is_active': isActive,
        'created_at': createdAt?.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    List<String>? roles,
    String? primaryRole,
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
      roles: roles ?? this.roles,
      primaryRole: primaryRole ?? this.primaryRole,
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
        roles,
        primaryRole,
        photoUrl,
        phone,
        isActive,
      ];

  @override
  String toString() =>
      'UserModel(name: $name, primaryRole: $primaryRole, roles: $roles)';
}