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
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 1100));

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
    await minDelay;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => next,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 450),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _anim, curve: const Interval(0.3, 1, curve: Curves.easeOut));
    final pulse = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.0).animate(pulse),
            child: const AppLogo(size: 104, showName: false),
          ),
          Align(
            alignment: const Alignment(0, 0.24),
            child: FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(fade),
                child: Text(
                  'Soundify',
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            child: FadeTransition(
              opacity: fade,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
