class AuthTokens {
  final String access;
  final String? refresh;

  const AuthTokens({required this.access, this.refresh});

  static AuthTokens? tryParse(dynamic json) {
    final access = _find(json, _isAccessKey);
    if (access == null) return null;
    return AuthTokens(access: access, refresh: _find(json, _isRefreshKey));
  }

  static bool _isAccessKey(String key) {
    final k = key.toLowerCase();
    return k == 'access' ||
        k == 'access_token' ||
        k == 'accesstoken' ||
        k == 'token' ||
        k == 'jwt' ||
        k == 'id_token';
  }

  static bool _isRefreshKey(String key) {
    final k = key.toLowerCase();
    return k == 'refresh' || k == 'refresh_token' || k == 'refreshtoken';
  }

  static String? _find(dynamic node, bool Function(String) match, [int depth = 0]) {
    if (depth > 4 || node is! Map) return null;
    for (final entry in node.entries) {
      final value = entry.value;
      if (match(entry.key.toString()) && value is String && value.isNotEmpty) {
        return value;
      }
    }
    for (final value in node.values) {
      final found = _find(value, match, depth + 1);
      if (found != null) return found;
    }
    return null;
  }
}
