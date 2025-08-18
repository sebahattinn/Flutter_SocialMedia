class AppUser {
  final String id;
  final String handle;
  final String name;
  final String avatarUrl;
  final String bio;

  const AppUser({
    required this.id,
    required this.handle,
    required this.name,
    required this.avatarUrl,
    this.bio = '',
  });
}
