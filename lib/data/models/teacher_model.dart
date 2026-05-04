import 'package:equatable/equatable.dart';

class TeacherModel extends Equatable {
  final String id;
  final String nip;
  final String name;
  final String subject;
  final String? photoUrl;
  final String? phone;
  final String? email;
  final String? address;
  final bool isActive;

  const TeacherModel({
    required this.id,
    required this.nip,
    required this.name,
    required this.subject,
    this.photoUrl,
    this.phone,
    this.email,
    this.address,
    this.isActive = true,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id']?.toString() ?? '',
      nip: json['nip'] ?? '',
      name: json['name'] ?? '',
      subject: json['subject'] ?? '',
      photoUrl: json['photo_url'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nip': nip,
    'name': name,
    'subject': subject,
    'photo_url': photoUrl,
    'phone': phone,
    'email': email,
    'address': address,
    'is_active': isActive,
  };

  @override
  List<Object?> get props => [id, nip, name, subject, isActive];
}
