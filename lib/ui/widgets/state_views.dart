import 'package:material_ui/material_ui.dart';

import '../theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.library_music_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) => _MessageView(
        icon: icon,
        message: message,
        iconColor: AppColors.textSecondary,
        action: action,
      );
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => _MessageView(
        icon: Icons.wifi_off_rounded,
        message: message,
        iconColor: AppColors.danger,
        action: SizedBox(
          width: 180,
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تلاش مجدد'),
          ),
        ),
      );
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color iconColor;
  final Widget? action;

  const _MessageView({
    required this.icon,
    required this.message,
    required this.iconColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: iconColor),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      );
}

class FadeSwitcher extends StatelessWidget {
  final Object state;
  final Widget child;

  const FadeSwitcher({super.key, required this.state, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(key: ValueKey(state), child: child),
      );
}
