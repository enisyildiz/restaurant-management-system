enum UserRole {
  waiter,
  admin,
}

class User {
  final String username;
  final UserRole role;

  const User({
    required this.username,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;
}
