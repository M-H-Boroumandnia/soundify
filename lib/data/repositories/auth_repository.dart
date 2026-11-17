import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../models/auth_tokens.dart';
import '../models/user.dart';

class OtpRequestResult {
  final int resendAfter;
  final int expiresIn;

  const OtpRequestResult({required this.resendAfter, required this.expiresIn});

  factory OtpRequestResult.fromJson(dynamic data, int fallback) {
    final map = data is Map ? data : const {};
    return OtpRequestResult(
      resendAfter: (map['resend_after'] as num?)?.toInt() ?? fallback,
      expiresIn: (map['expires_in'] as num?)?.toInt() ?? 300,
    );
  }
}

class AuthRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  AuthRepository(this._api, this._storage);

  Future<void> register({
    required String email,
    required String username,
    required String password,
    String? displayName,
  }) async {
    await _api.post('/auth/register/', auth: false, data: {
      'email': email,
      'username': username,
      'password': password,
      if (displayName != null && displayName.isNotEmpty)
        'display_name': displayName,
    });
  }

  Future<void> login(String email, String password) async {
    final data = await _api.post('/auth/login/', auth: false, data: {
      'email': email,
      'password': password,
    });
    await _persist(data);
  }

  Future<OtpRequestResult> requestOtp(String email) async {
    final data = await _api.post('/auth/otp/request/',
        auth: false, data: {'email': email});
    return OtpRequestResult.fromJson(data, 60);
  }

  Future<void> verifyOtp(String email, String code) async {
    final data = await _api.post('/auth/otp/verify/', auth: false, data: {
      'email': email,
      'code': code,
    });
    await _persist(data);
  }

  Future<OtpRequestResult> requestPasswordReset(String email) async {
    final data = await _api.post('/auth/password/reset/request/',
        auth: false, data: {'email': email});
    return OtpRequestResult.fromJson(data, 60);
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _api.post('/auth/password/reset/confirm/', auth: false, data: {
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
  }

  Future<AppUser> me() async => AppUser.fromJson(await _api.get('/users/me/'));

  Future<bool> hasSession() => _storage.hasSession();

  Future<void> logout() => _storage.clear();

  Future<void> _persist(dynamic data) async {
    final tokens = AuthTokens.tryParse(data);
    if (tokens == null) {
      throw const ApiException('پاسخ نامعتبر از سرور دریافت شد');
    }
    await _storage.save(tokens);
  }
}
