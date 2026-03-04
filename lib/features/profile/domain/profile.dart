// Profile domain model used by profile and owner-display flows.
class Profile {
  const Profile({required this.id, required this.username, this.avatarUrl});

  final String id;
  final String username;
  final String? avatarUrl;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}
