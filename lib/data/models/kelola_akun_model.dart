// lib/data/models/kelola_akun_model.dart

import 'package:equatable/equatable.dart';

/// Model untuk user akun dari auth-service (/api/auth/users)
class KelolaAkunModel extends Equatable {
  final String idKeycloak;
  final String namaLengkap;
  final String username;
  final String? nip;
  final List<String> roles;

  const KelolaAkunModel({
    required this.idKeycloak,
    required this.namaLengkap,
    required this.username,
    this.nip,
    this.roles = const [],
  });

  factory KelolaAkunModel.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    List<String> parsedRoles = [];

    if (rawRoles is List) {
      parsedRoles = rawRoles
          .map((r) => r.toString().trim())
          .where((r) => r.isNotEmpty)
          .toList();
    }

    return KelolaAkunModel(
      idKeycloak: json['id_keycloak']?.toString() ?? '',
      namaLengkap: json['nama_lengkap']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      nip: (json['nip'] == null || json['nip'].toString().isEmpty)
          ? null
          : json['nip'].toString(),
      roles: parsedRoles,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_keycloak': idKeycloak,
        'nama_lengkap': namaLengkap,
        'username': username,
        'nip': nip,
        'roles': roles,
      };

  @override
  List<Object?> get props => [idKeycloak, namaLengkap, username, nip, roles];
}

/// Payload untuk membuat akun baru (POST /api/auth/users)
class CreateAkunPayload {
  final String username;
  final String namaLengkap;
  final String? nip;
  final String password;
  final List<String> roles;

  const CreateAkunPayload({
    required this.username,
    required this.namaLengkap,
    this.nip,
    required this.password,
    required this.roles,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'namaLengkap': namaLengkap,
        'nip': nip ?? '',
        'password': password,
        'roles': roles,
      };
}

/// Payload untuk mengedit akun (PUT /api/auth/users/:id)
class UpdateAkunPayload {
  final String namaLengkap;
  final String? nipVal;
  final String? password;
  final List<String> roles;

  const UpdateAkunPayload({
    required this.namaLengkap,
    this.nipVal,
    this.password,
    required this.roles,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'namaLengkap': namaLengkap,
      'nipVal': nipVal ?? '',
      'roles': roles,
    };
    if (password != null && password!.isNotEmpty) {
      map['password'] = password;
    }
    return map;
  }
}