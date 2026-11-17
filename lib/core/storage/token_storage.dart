import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/auth_tokens.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  String? _accessCache;
  String? _refreshCache;

  Future<String?> readAccess() async =>
      _accessCache ??= await _storage.read(key: _accessKey);

  Future<String?> readRefresh() async =>
      _refreshCache ??= await _storage.read(key: _refreshKey);

  Future<bool> hasSession() async => (await readRefresh()) != null;

  Future<void> save(AuthTokens tokens) async {
    _accessCache = tokens.access;
    await _storage.write(key: _accessKey, value: tokens.access);
    if (tokens.refresh != null) {
      _refreshCache = tokens.refresh;
      await _storage.write(key: _refreshKey, value: tokens.refresh);
    }
  }

  Future<void> clear() async {
    _accessCache = null;
    _refreshCache = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
