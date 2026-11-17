import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ApiException(this.message, {this.code, this.statusCode});

  bool get isNetwork => code == 'network';
  bool get isUnauthorized => statusCode == 401;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('زمان پاسخ‌گویی سرور به پایان رسید', code: 'network');
      case DioExceptionType.connectionError:
        return const ApiException('اتصال به اینترنت برقرار نیست', code: 'network');
      case DioExceptionType.cancel:
        return const ApiException('درخواست لغو شد', code: 'cancelled');
      default:
        break;
    }
    final response = e.response;
    final status = response?.statusCode;
    final data = response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      final code = err['code']?.toString();
      return ApiException(
        _translate(code) ?? err['message']?.toString() ?? 'خطای ناشناخته',
        code: code,
        statusCode: status,
      );
    }
    return ApiException(_statusMessage(status), statusCode: status);
  }

  static String? _translate(String? code) {
    const map = {
      'invalid_credentials': 'ایمیل یا رمز عبور اشتباه است',
      'account_not_verified': 'حساب کاربری هنوز تأیید نشده است',
      'not_verified': 'حساب کاربری هنوز تأیید نشده است',
      'invalid_email': 'ایمیل وارد شده معتبر نیست',
      'otp_expired': 'کد تأیید منقضی شده یا درخواست نشده است',
      'invalid_otp': 'کد تأیید اشتباه است',
      'invalid_code': 'کد تأیید اشتباه است',
      'token_not_valid': 'نشست شما منقضی شده است، دوباره وارد شوید',
      'authentication_required': 'برای این کار باید وارد شوید',
      'not_found': 'مورد درخواستی یافت نشد',
      'already_exists': 'این مورد از قبل وجود دارد',
      'already_favorited': 'این آهنگ از قبل در علاقه‌مندی‌هاست',
      'throttled': 'تعداد درخواست‌ها زیاد است، کمی بعد تلاش کنید',
    };
    return map[code];
  }

  static String _statusMessage(int? status) {
    if (status == null) return 'خطا در برقراری ارتباط با سرور';
    if (status == 401) return 'برای این کار باید وارد شوید';
    if (status == 403) return 'دسترسی مجاز نیست';
    if (status == 404) return 'مورد درخواستی یافت نشد';
    if (status == 409) return 'این مورد از قبل وجود دارد';
    if (status == 429) return 'تعداد درخواست‌ها زیاد است، کمی بعد تلاش کنید';
    if (status >= 500) return 'خطای سرور، لطفاً بعداً تلاش کنید';
    return 'خطای ناشناخته ($status)';
  }

  @override
  String toString() => message;
}
