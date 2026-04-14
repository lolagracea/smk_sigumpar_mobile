import 'package:equatable/equatable.dart';

class StudentModel extends Equatable {
  final String id;
  final String nis;
  final String name;
  final String classId;
  final String className;
  final String gender;
  final String? photoUrl;
  final String? address;
  final String? parentName;
  final String? parentPhone;
  final bool isActive;

  const StudentModel({
    required this.id,
    required this.nis,
    required this.name,
    required this.classId,
    required this.className,
    required this.gender,
    this.photoUrl,
    this.address,
    this.parentName,
    this.parentPhone,
    this.isActive = true,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id']?.toString() ?? '',
      nis: json['nis'] ?? '',
      name: json['name'] ?? '',
      classId: json['class_id']?.toString() ?? '',
      className: json['class_name'] ?? json['class']?['name'] ?? '',
      gender: json['gender'] ?? '',
      photoUrl: json['photo_url'],
      address: json['address'],
      parentName: json['parent_name'],
      parentPhone: json['parent_phone'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nis': nis,
        'name': name,
        'class_id': classId,
        'class_name': className,
        'gender': gender,
        'photo_url': photoUrl,
        'address': address,
        'parent_name': parentName,
        'parent_phone': parentPhone,
        'is_active': isActive,
      };

  @override
  List<Object?> get props => [id, nis, name, classId, className, gender, isActive];
}
