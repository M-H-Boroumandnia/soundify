import 'package:material_ui/material_ui.dart';

import '../../theme.dart';
import '../../widgets/app_logo.dart';

class AuthScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;

  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(size: 64, showName: false)),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 32),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const LoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    child: loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.onPrimary),
          )
        : Text(label),
  );
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final TextInputAction action;
  final VoidCallback? onSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    required this.validator,
    this.label = 'رمز عبور',
    this.action = TextInputAction.done,
    this.onSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: _obscure,
    textDirection: TextDirection.ltr,
    textInputAction: widget.action,
    autofillHints: const [AutofillHints.password],
    onFieldSubmitted: (_) => widget.onSubmitted?.call(),
    validator: widget.validator,
    decoration: InputDecoration(
      labelText: widget.label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    ),
  );
}

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool enabled;

  const EmailField({
    super.key,
    required this.controller,
    required this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    keyboardType: TextInputType.emailAddress,
    textDirection: TextDirection.ltr,
    textInputAction: TextInputAction.next,
    autofillHints: const [AutofillHints.email],
    validator: validator,
    decoration: const InputDecoration(
      labelText: 'ایمیل',
      prefixIcon: Icon(Icons.alternate_email_rounded),
    ),
  );
}
