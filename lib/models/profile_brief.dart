class ProfileBrief {
  final String id;
  final String username;
  final String? avatarUrl;

  ProfileBrief({required this.id, required this.username, this.avatarUrl});

  factory ProfileBrief.fromRow(Map<String, dynamic> row) => ProfileBrief(
    id: row['id'] as String,
    username: (row['username'] ?? 'unknown') as String,
    avatarUrl: row['avatar_url'] as String?,
  );
}
