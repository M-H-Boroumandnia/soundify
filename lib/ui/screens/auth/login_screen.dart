import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../state/auth_provider.dart';
import '../../navigation.dart';
import '../../theme.dart';
import 'auth_scaffold.dart';
import 'forgot_password_screen.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool autoBiometric;

  const LoginScreen({super.key, this.autoBiometric = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    if (auth.sessionExpired) {
      auth.consumeSessionExpired();
      showMessage(context, 'نشست شما منقضی شده است، دوباره وارد شوید', error: true);
    }
    final available = await auth.canUseBiometricLogin();
    if (!mounted) return;
    setState(() => _biometricAvailable = available);
    if (available && widget.autoBiometric) _loginBiometric();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final email = _email.text.trim();
    try {
      await context.read<AuthProvider>().login(email, _password.text);
      if (mounted) goToHome(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403) {
        showMessage(context, 'حساب شما تأیید نشده است. کد تأیید به ایمیل شما ارسال می‌شود');
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => OtpScreen(
            initialEmail: email,
            sendOnOpen: true,
            password: _password.text,
          ),
        ));
      } else {
        showMessage(context, e.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginBiometric() async {
    setState(() => _loading = true);
    try {
      final ok = await context.read<AuthProvider>().loginWithBiometric();
      if (!mounted) return;
      if (ok) {
        goToHome(context);
      } else {
        showMessage(context, 'احراز هویت بیومتریک انجام نشد', error: true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showMessage(context, e.message, error: true);
      setState(() => _biometricAvailable = false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openOtp() async {
    final email = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => OtpScreen(initialEmail: _email.text.trim()),
    ));
    if (email != null && mounted) _email.text = email;
  }

  void _push(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: false,
      title: 'ورود به حساب',
      subtitle: 'برای ادامه وارد حساب ساندیفای خود شوید',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmailField(controller: _email, validator: Validators.email),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                validator: Validators.loginPassword,
                onSubmitted: _login,
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => _push(ForgotPasswordScreen(initialEmail: _email.text.trim())),
                  child: const Text('رمز عبور را فراموش کرده‌اید؟'),
                ),
              ),
              const SizedBox(height: 8),
              LoadingButton(label: 'ورود', loading: _loading, onPressed: _login),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : _openOtp,
                icon: const Icon(Icons.mark_email_read_outlined),
                label: const Text('ورود با کد یک‌بار مصرف'),
              ),
              if (_biometricAvailable) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _loginBiometric,
                  icon: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                  label: const Text('ورود با اثر انگشت / چهره'),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('حساب کاربری ندارید؟',
                      style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => _push(const RegisterScreen()),
                    child: const Text('ثبت‌نام کنید'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
