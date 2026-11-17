class AuthTokens {
  final String access;
  final String? refresh;

  const AuthTokens({required this.access, this.refresh});

  static AuthTokens? tryParse(dynamic json) {
    if (json is! Map) return null;
    final access = _pick(json, const ['access', 'access_token', 'accessToken']);
    if (access != null) {
      return AuthTokens(
        access: access,
        refresh: _pick(json, const ['refresh', 'refresh_token', 'refreshToken']),
      );
    }
    for (final key in const ['tokens', 'token', 'data']) {
      final nested = tryParse(json[key]);
      if (nested != null) return nested;
    }
    return null;
  }

  static String? _pick(Map json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }
}
