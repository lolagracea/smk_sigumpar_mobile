class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.roles,
    this.token = '',          // ← JWT token dari Keycloak
  });

  final String id;
  final String username;
  final String name;
  final List<String> roles;
  final String token;

  bool hasRole(String role) => roles.contains(role);

  bool get isWakilKepsek =>
      hasRole('wakil-kepsek') || hasRole('wakil_kepsek');

  bool get isKepsek =>
      hasRole('kepala-sekolah') || hasRole('kepsek');
}
