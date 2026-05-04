import 'package:equatable/equatable.dart';

class UserSearchModel extends Equatable {
  final String id;
  final String username;
  final String? email;
  final String fullName;
  final List<String> roles;

  const UserSearchModel({
    required this.id,
    required this.username,
    this.email,
    required this.fullName,
    this.roles = const [],
  });

  factory UserSearchModel.fromJson(Map<String, dynamic> json) {
    return UserSearchModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      fullName: json['nama_lengkap']?.toString() ??
          json['name']?.toString() ??
          json['full_name']?.toString() ??
          json['username']?.toString() ??
          '',
      roles: json['roles'] is List
          ? List<String>.from(
        (json['roles'] as List).map((role) => role.toString()),
      )
          : const [],
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    fullName,
    roles,
  ];
}