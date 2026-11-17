import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/storage/app_prefs.dart';
import '../theme.dart';
import 'auth/login_screen.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingPage(this.icon, this.title, this.body);
}

const _pages = [
  _OnboardingPage(
    Icons.headphones_rounded,
    'به ساندیفای خوش آمدید',
    'هزاران آهنگ از خوانندگان محبوب، هر زمان و هر جا به صورت آنلاین.',
  ),
  _OnboardingPage(
    Icons.queue_music_rounded,
    'پلی‌لیست شخصی بسازید',
    'آهنگ‌های مورد علاقه‌تان را لایک کنید و پلی‌لیست‌های خودتان را مدیریت کنید.',
  ),
  _OnboardingPage(
    Icons.fingerprint_rounded,
    'امن و بی‌وقفه',
    'ورود با اثر انگشت، ذخیره امن اطلاعات و پخش در پس‌زمینه حتی با صفحه خاموش.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<AppPrefs>().setOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _isLast ? null : _finish,
                child: Text(_isLast ? '' : 'رد شدن'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                          child: Icon(page.icon, size: 96, color: AppColors.primary),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SmoothPageIndicator(
              controller: _controller,
              count: _pages.length,
              textDirection: TextDirection.rtl,
              effect: const ExpandingDotsEffect(
                activeDotColor: AppColors.primary,
                dotColor: AppColors.surfaceHigh,
                dotHeight: 8,
                dotWidth: 8,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: FilledButton(
                onPressed: _next,
                child: Text(_isLast ? 'شروع کنید' : 'بعدی'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
