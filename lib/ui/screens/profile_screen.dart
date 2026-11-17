import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/security/device_security.dart';
import '../../state/auth_provider.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<DeviceSecurityReport> _security =
      context.read<DeviceSecurityService>().check();
  bool _togglingBiometric = false;

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _togglingBiometric = true);
    final error = await context.read<AuthProvider>().setBiometricEnabled(value);
    if (!mounted) return;
    setState(() => _togglingBiometric = false);
    if (error != null) {
      showMessage(context, error, error: true);
    } else {
      showMessage(context, value ? 'ورود بیومتریک فعال شد' : 'ورود بیومتریک غیرفعال شد');
    }
  }

  Future<void> _logout({required bool forget}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(forget ? 'خروج و حذف اطلاعات' : 'خروج از حساب'),
        content: Text(forget
            ? 'توکن‌ها و تنظیمات ورود بیومتریک از این دستگاه حذف می‌شوند.'
            : 'آیا می‌خواهید از حساب کاربری خارج شوید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout(forgetDevice: forget);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _security = context.read<DeviceSecurityService>().check(force: true));
          await auth.refreshUser();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primary,
                child: Text(
                  user?.initials ?? '?',
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.name ?? 'کاربر',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (user != null) ...[
              const SizedBox(height: 4),
              Text(
                user.email,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 24),
            _Section(
              title: 'اطلاعات حساب',
              children: [
                _InfoRow(icon: Icons.person_outline_rounded, label: 'نام کاربری', value: user?.username ?? '-'),
                _InfoRow(icon: Icons.badge_outlined, label: 'نام نمایشی', value: user?.displayName.isNotEmpty == true ? user!.displayName : '-'),
                _InfoRow(icon: Icons.alternate_email_rounded, label: 'ایمیل', value: user?.email ?? '-'),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'تنظیمات امنیتی',
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                  title: const Text('ورود با اثر انگشت / تشخیص چهره'),
                  subtitle: const Text('ورود سریع بدون وارد کردن رمز عبور',
                      style: TextStyle(color: AppColors.textSecondary)),
                  value: auth.biometricEnabled,
                  onChanged: _togglingBiometric ? null : _toggleBiometric,
                ),
                const ListTile(
                  leading: Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                  title: Text('ذخیره‌سازی امن توکن‌ها'),
                  subtitle: Text('توکن‌ها در Android Keystore رمزنگاری شده‌اند',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                FutureBuilder<DeviceSecurityReport>(
                  future: _security,
                  builder: (context, snapshot) => _DeviceSecurityTile(report: snapshot.data),
                ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _logout(forget: false),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('خروج از حساب'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _logout(forget: true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('خروج و حذف اطلاعات از این دستگاه'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: children),
          ),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}

class _DeviceSecurityTile extends StatelessWidget {
  final DeviceSecurityReport? report;

  const _DeviceSecurityTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final r = report;
    if (r == null) {
      return const ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('در حال بررسی امنیت دستگاه...'),
      );
    }
    final issues = <String>[
      if (r.isRooted) 'دستگاه روت شده است',
      if (r.isEmulator) 'برنامه روی شبیه‌ساز اجرا می‌شود',
      if (r.isDevelopmentMode) 'حالت توسعه‌دهنده فعال است',
      if (r.checkFailed) 'بررسی امنیت دستگاه انجام نشد',
    ];
    final secure = r.isSecure;
    return ListTile(
      leading: Icon(
        secure ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
        color: secure ? AppColors.primary : AppColors.warning,
      ),
      title: Text(secure ? 'دستگاه امن است' : 'هشدار امنیتی دستگاه'),
      subtitle: Text(
        [
          'روت: ${r.isRooted ? 'بله' : 'خیر'}  •  شبیه‌ساز: ${r.isEmulator ? 'بله' : 'خیر'}',
          ...issues,
        ].join('\n'),
        style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
      ),
      isThreeLine: issues.isNotEmpty,
    );
  }
}
