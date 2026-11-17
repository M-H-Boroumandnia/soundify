import 'package:material_ui/material_ui.dart';

class AppColors {
  static const background = Color(0xFF0E0F13);
  static const surface = Color(0xFF181A20);
  static const surfaceHigh = Color(0xFF22252D);
  static const primary = Color(0xFF1ED760);
  static const onPrimary = Color(0xFF06140B);
  static const textPrimary = Color(0xFFF2F3F5);
  static const textSecondary = Color(0xFF9EA3AE);
  static const danger = Color(0xFFFF5A5F);
  static const warning = Color(0xFFFFB547);
}

ThemeData buildDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.primary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceHigh,
    outlineVariant: AppColors.surfaceHigh,
    error: AppColors.danger,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Vazirmatn',
  );
  final geometry = Typography.material2021(platform: TargetPlatform.android).englishLike;
  final textTheme = _evenLeading(geometry.merge(base.textTheme)).apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );
  final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return base.copyWith(
    textTheme: textTheme,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      titleTextStyle: const TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.surfaceHigh, thickness: 1, space: 1),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: textTheme.titleSmall,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: AppColors.primary, width: 3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
      ),
      overlayColor: WidgetStatePropertyAll(AppColors.primary.withValues(alpha: 0.08)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected)
          ? Colors.white
          : AppColors.textSecondary),
      trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected)
          ? AppColors.primary
          : AppColors.surfaceHigh),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.textSecondary,
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: rounded,
      clipBehavior: Clip.antiAlias,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceHigh,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: textTheme.labelLarge,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      position: PopupMenuPosition.under,
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: textTheme.bodyMedium,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      border: _fieldBorder(Colors.transparent, 0),
      enabledBorder: _fieldBorder(Colors.transparent, 0),
      disabledBorder: _fieldBorder(Colors.transparent, 0),
      focusedBorder: _fieldBorder(AppColors.primary, 2),
      errorBorder: _fieldBorder(AppColors.danger, 1.4),
      focusedErrorBorder: _fieldBorder(AppColors.danger, 2),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) => TextStyle(
            color: states.contains(WidgetState.error)
                ? AppColors.danger
                : states.contains(WidgetState.focused)
                    ? AppColors.primary
                    : AppColors.textSecondary,
          )),
      prefixIconColor: AppColors.textSecondary,
      suffixIconColor: AppColors.textSecondary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.surfaceHigh, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      extendedTextStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      height: 68,
      indicatorColor: AppColors.primary.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelSmall?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          )),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.surfaceHigh,
      thumbColor: Colors.white,
      trackHeight: 4,
      trackShape: const RoundedRectSliderTrackShape(),
      overlayColor: AppColors.primary.withValues(alpha: 0.2),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 8,
        elevation: 3,
        pressedElevation: 6,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
    ),
  );
}

InputBorder _fieldBorder(Color color, double width) => UnderlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: width == 0 ? BorderSide.none : BorderSide(color: color, width: width),
    );

TextTheme _evenLeading(TextTheme t) {
  TextStyle? fix(TextStyle? s) =>
      s?.copyWith(leadingDistribution: TextLeadingDistribution.even);
  return t.copyWith(
    displayLarge: fix(t.displayLarge),
    displayMedium: fix(t.displayMedium),
    displaySmall: fix(t.displaySmall),
    headlineLarge: fix(t.headlineLarge),
    headlineMedium: fix(t.headlineMedium),
    headlineSmall: fix(t.headlineSmall),
    titleLarge: fix(t.titleLarge),
    titleMedium: fix(t.titleMedium),
    titleSmall: fix(t.titleSmall),
    bodyLarge: fix(t.bodyLarge),
    bodyMedium: fix(t.bodyMedium),
    bodySmall: fix(t.bodySmall),
    labelLarge: fix(t.labelLarge),
    labelMedium: fix(t.labelMedium),
    labelSmall: fix(t.labelSmall),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger.withValues(alpha: 0.92) : null,
    ));
}

PopupMenuItem<String> menuItem(String value, IconData icon, String label, {bool danger = false}) {
  final color = danger ? AppColors.danger : AppColors.textPrimary;
  return PopupMenuItem<String>(
    value: value,
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: danger ? AppColors.danger : AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
      ],
    ),
  );
}
