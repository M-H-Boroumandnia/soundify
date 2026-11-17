import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/security/device_security.dart';
import '../../state/favorites_provider.dart';
import '../../state/playlists_provider.dart';
import '../theme.dart';
import '../widgets/mini_player.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  static const _tabs = <Widget>[HomeScreen(), SearchScreen(), LibraryScreen(), ProfileScreen()];

  final _navigatorKeys = List.generate(_tabs.length, (_) => GlobalKey<NavigatorState>());
  int _index = 0;

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().load();
      context.read<PlaylistsProvider>().load();
      _warnIfInsecure();
    });
  }

  Future<void> _warnIfInsecure() async {
    final report = await context.read<DeviceSecurityService>().check();
    if (!mounted || report.isSecure) return;
    final reasons = [
      if (report.isRooted) 'دستگاه روت شده است',
      if (report.isEmulator) 'برنامه روی شبیه‌ساز اجرا می‌شود',
      if (report.checkFailed) 'بررسی امنیت انجام نشد',
    ].join(' و ');
    showMessage(context, 'هشدار امنیتی: $reasons');
  }

  void _select(int index) {
    if (index == _index) {
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
    } else {
      _switchTo(index);
    }
  }

  void _switchTo(int index) {
    setState(() => _index = index);
    _fade.forward(from: 0);
  }

  void _handleBack(bool didPop, Object? _) {
    if (didPop) return;
    final nav = _navigatorKeys[_index].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    } else if (_index != 0) {
      _switchTo(0);
    }
  }

  bool get _canExit {
    final nav = _navigatorKeys[_index].currentState;
    return _index == 0 && !(nav?.canPop() ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canExit,
      onPopInvokedWithResult: _handleBack,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
                child: IndexedStack(
                  index: _index,
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Navigator(
                        key: _navigatorKeys[i],
                        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => _tabs[i]),
                      ),
                  ],
                ),
              ),
            ),
            const MiniPlayer(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'خانه',
            ),
            NavigationDestination(icon: Icon(Icons.search_rounded), label: 'جست‌وجو'),
            NavigationDestination(
              icon: Icon(Icons.library_music_outlined),
              selectedIcon: Icon(Icons.library_music_rounded),
              label: 'کتابخانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'پروفایل',
            ),
          ],
        ),
      ),
    );
  }
}
