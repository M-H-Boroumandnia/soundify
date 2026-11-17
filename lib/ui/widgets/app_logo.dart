import 'package:material_ui/material_ui.dart';

import '../theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showName;

  const AppLogo({super.key, this.size = 88, this.showName = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF0FA34A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: size * 0.4,
              ),
            ],
          ),
          child: Icon(Icons.graphic_eq_rounded, size: size * 0.55, color: AppColors.onPrimary),
        ),
        if (showName) ...[
          SizedBox(height: size * 0.22),
          Text(
            'Soundify',
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ],
    );
  }
}
