class AppConfig {
  static const String baseUrl = 'https://soundify.easyfound.ir/api/v1';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration searchDebounce = Duration(milliseconds: 450);
  static const int otpResendSeconds = 60;
  static const int pageSize = 20;
}
