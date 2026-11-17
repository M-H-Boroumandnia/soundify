import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../theme.dart';
import 'auth_scaffold.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_email, _username, _displayName, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final email = _email.text.trim();
    try {
      await context.read<AuthRepository>().register(
            email: email,
            username: _username.text.trim(),
            password: _password.text,
            displayName: _displayName.text.trim(),
          );
      if (!mounted) return;
      showMessage(context, 'ثبت‌نام انجام شد. کد تأیید را وارد کنید');
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => OtpScreen(
          initialEmail: email,
          sendOnOpen: true,
          password: _password.text,
        ),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      showMessage(
        context,
        e.statusCode == 409 ? 'این ایمیل یا نام کاربری قبلاً ثبت شده است' : e.message,
        error: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'ساخت حساب جدید',
      subtitle: 'اطلاعات خود را وارد کنید',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmailField(controller: _email, validator: Validators.email),
              const SizedBox(height: 16),
              TextFormField(
                controller: _username,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newUsername],
                validator: Validators.username,
                decoration: const InputDecoration(
                  labelText: 'نام کاربری',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayName,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'نام نمایشی (اختیاری)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                validator: Validators.password,
                action: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirm,
                label: 'تکرار رمز عبور',
                validator: (v) => v != _password.text ? 'رمز عبور و تکرار آن یکسان نیستند' : null,
                onSubmitted: _register,
              ),
              const SizedBox(height: 28),
              LoadingButton(label: 'ثبت‌نام', loading: _loading, onPressed: _register),
            ],
          ),
        ),
      ),
    );
  }
}
