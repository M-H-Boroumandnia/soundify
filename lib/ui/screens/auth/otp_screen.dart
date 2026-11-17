import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../state/auth_provider.dart';
import '../../navigation.dart';
import '../../theme.dart';
import 'auth_scaffold.dart';
import 'resend_timer.dart';

class OtpScreen extends StatefulWidget {
  final String initialEmail;
  final bool sendOnOpen;
  final String? password;

  const OtpScreen({
    super.key,
    this.initialEmail = '',
    this.sendOnOpen = false,
    this.password,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _codeForm = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _resend = ResendController();
  bool _codeSent = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sendOnOpen && Validators.email(widget.initialEmail) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestCode());
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _resend.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_codeSent && !(_emailForm.currentState?.validate() ?? true)) return;
    setState(() => _loading = true);
    try {
      final result = await context.read<AuthRepository>().requestOtp(_email.text.trim());
      if (!mounted) return;
      _resend.start(result.resendAfter);
      setState(() => _codeSent = true);
      showMessage(context, 'کد تأیید به ایمیل شما ارسال شد');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    if (_loading || !_codeForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final signedIn = await context
          .read<AuthProvider>()
          .verifyOtp(_email.text.trim(), _code.text.trim(), password: widget.password);
      if (!mounted) return;
      if (signedIn) {
        goToHome(context);
      } else {
        showMessage(context, 'حساب شما تأیید شد. اکنون با ایمیل و رمز عبور وارد شوید');
        Navigator.of(context).pop(_email.text.trim());
      }
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'ورود با کد یک‌بار مصرف',
      subtitle: _codeSent
          ? 'کد ارسال شده به ${_email.text.trim()} را وارد کنید'
          : 'ایمیل خود را وارد کنید تا کد تأیید برایتان ارسال شود',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _codeSent ? _buildCodeStage() : _buildEmailStage(),
      ),
    );
  }

  Widget _buildEmailStage() => Form(
        key: _emailForm,
        child: Column(
          key: const ValueKey('email'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EmailField(controller: _email, validator: Validators.email),
            const SizedBox(height: 24),
            LoadingButton(label: 'ارسال کد', loading: _loading, onPressed: _requestCode),
          ],
        ),
      );

  Widget _buildCodeStage() => Form(
        key: _codeForm,
        child: Column(
          key: const ValueKey('code'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OtpField(controller: _code, validator: Validators.otp, onCompleted: _verify),
            const SizedBox(height: 24),
            LoadingButton(label: 'تأیید و ورود', loading: _loading, onPressed: _verify),
            const SizedBox(height: 8),
            ResendButton(controller: _resend, loading: _loading, onResend: _requestCode),
            TextButton(
              onPressed: _loading ? null : () => setState(() => _codeSent = false),
              child: const Text('تغییر ایمیل'),
            ),
          ],
        ),
      );
}
