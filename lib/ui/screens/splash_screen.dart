import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/storage/app_prefs.dart';
import '../../state/auth_provider.dart';
import '../widgets/app_logo.dart';
import 'auth/login_screen.dart';
import 'onboarding_screen.dart';
import 'shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    _decide();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _decide() async {
    final prefs = context.read<AppPrefs>();
    final auth = context.read<AuthProvider>();
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    Widget next;
    if (!prefs.onboardingSeen) {
      next = const OnboardingScreen();
    } else if (await auth.hasStoredSession()) {
      if (auth.biometricEnabled) {
        next = const LoginScreen(autoBiometric: true);
      } else {
        await auth.restoreSession();
        next = auth.status == AuthStatus.authenticated
            ? const ShellScreen()
            : const LoginScreen();
      }
    } else {
      next = const LoginScreen();
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => next,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
            ),
            child: const AppLogo(size: 110),
          ),
        ),
      ),
    );
  }
}
