import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String username;
  final String email;
  final String role;
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
    this.photoUrl,
    this.phone,
    this.isActive = true,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
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
        'role': role,
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
    String? role,
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
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, username, email, role, photoUrl, phone, isActive];
}
