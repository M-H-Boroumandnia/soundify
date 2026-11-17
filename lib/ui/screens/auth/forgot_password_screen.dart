import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../theme.dart';
import 'auth_scaffold.dart';
import 'resend_timer.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _resend = ResendController();
  int _step = 0;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_email, _code, _password, _confirm]) {
      c.dispose();
    }
    _resend.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (_step == 0 && !_emailForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final result = await context
          .read<AuthRepository>()
          .requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      _resend.start(result.resendAfter);
      setState(() => _step = 1);
      showMessage(context, 'کد بازیابی به ایمیل شما ارسال شد');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmReset() async {
    if (!_resetForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await context.read<AuthRepository>().confirmPasswordReset(
            email: _email.text.trim(),
            code: _code.text.trim(),
            newPassword: _password.text,
          );
      if (!mounted) return;
      showMessage(context, 'رمز عبور با موفقیت تغییر کرد. اکنون وارد شوید');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'بازیابی رمز عبور',
      subtitle: _step == 0
          ? 'مرحله ۱ از ۲: ایمیل حساب خود را وارد کنید'
          : 'مرحله ۲ از ۲: کد ارسال شده و رمز جدید را وارد کنید',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _step == 0 ? _buildEmailStep() : _buildResetStep(),
      ),
    );
  }

  Widget _buildEmailStep() => Form(
        key: _emailForm,
        child: Column(
          key: const ValueKey('email'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EmailField(controller: _email, validator: Validators.email),
            const SizedBox(height: 24),
            LoadingButton(label: 'دریافت کد بازیابی', loading: _loading, onPressed: _requestCode),
          ],
        ),
      );

  Widget _buildResetStep() => Form(
        key: _resetForm,
        child: Column(
          key: const ValueKey('reset'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OtpField(controller: _code, validator: Validators.otp),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              label: 'رمز عبور جدید',
              validator: Validators.password,
              action: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirm,
              label: 'تکرار رمز عبور جدید',
              validator: (v) => v != _password.text ? 'رمز عبور و تکرار آن یکسان نیستند' : null,
              onSubmitted: _confirmReset,
            ),
            const SizedBox(height: 24),
            LoadingButton(label: 'ثبت رمز جدید', loading: _loading, onPressed: _confirmReset),
            const SizedBox(height: 8),
            ResendButton(controller: _resend, loading: _loading, onResend: _requestCode),
          ],
        ),
      );
}
