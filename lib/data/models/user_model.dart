class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.roles,
  });

  final String id;
  final String username;
  final String name;
  final List<String> roles;
}
