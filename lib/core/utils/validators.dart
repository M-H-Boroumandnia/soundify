class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)*\.[a-zA-Z]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'ایمیل را وارد کنید';
    if (!_emailRegex.hasMatch(v)) return 'ایمیل معتبر نیست';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'رمز عبور را وارد کنید';
    if (v.length < 8) return 'رمز عبور باید حداقل ۸ کاراکتر باشد';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'رمز عبور باید شامل حرف و عدد باشد';
    }
    return null;
  }

  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'رمز عبور را وارد کنید';
    return null;
  }

  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'نام کاربری را وارد کنید';
    if (v.length < 3) return 'نام کاربری باید حداقل ۳ کاراکتر باشد';
    if (!RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(v)) {
      return 'فقط حروف انگلیسی، عدد، نقطه و _ مجاز است';
    }
    return null;
  }

  static String? otp(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'کد تأیید را وارد کنید';
    if (!RegExp(r'^\d{4,8}$').hasMatch(v)) return 'کد تأیید معتبر نیست';
    return null;
  }

  static String? required(String? value, String label) {
    if ((value?.trim() ?? '').isEmpty) return '$label را وارد کنید';
    return null;
  }
}
