import 'package:material_ui/material_ui.dart';

import 'screens/auth/login_screen.dart';
import 'screens/shell_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

void goToHome(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const ShellScreen()),
    (_) => false,
  );
}

void goToLogin() {
  rootNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}
