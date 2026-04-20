class User {
  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.roles,
  });

  final String id;
  final String name;
  final String username;
  final List<String> roles;
}
