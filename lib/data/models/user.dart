class AppUser {
  final String id;
  final String email;
  final String username;
  final String displayName;
  final bool isVerified;

  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    required this.isVerified,
  });

  String get name => displayName.isNotEmpty ? displayName : username;

  String get initials {
    final source = name.trim();
    return source.isEmpty ? '?' : source.characters.first.toUpperCase();
  }

  factory AppUser.fromJson(dynamic data) {
    final json = data is Map && data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : Map<String, dynamic>.from(data as Map);
    return AppUser(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      isVerified: json['is_verified'] != false,
    );
  }
}

extension on String {
  Iterable<String> get characters => runes.map(String.fromCharCode);
}
