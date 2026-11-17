import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/security/device_security.dart';
import 'core/storage/app_prefs.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/music_repository.dart';
import 'state/auth_provider.dart';
import 'state/favorites_provider.dart';
import 'state/player_controller.dart';
import 'state/playlists_provider.dart';
import 'ui/navigation.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme.dart';

class SoundifyApp extends StatefulWidget {
  final AppPrefs prefs;
  final AuthRepository authRepository;
  final MusicRepository musicRepository;
  final AuthProvider auth;
  final FavoritesProvider favorites;
  final PlaylistsProvider playlists;
  final PlayerController player;
  final DeviceSecurityService deviceSecurity;

  const SoundifyApp({
    super.key,
    required this.prefs,
    required this.authRepository,
    required this.musicRepository,
    required this.auth,
    required this.favorites,
    required this.playlists,
    required this.player,
    required this.deviceSecurity,
  });

  @override
  State<SoundifyApp> createState() => _SoundifyAppState();
}

class _SoundifyAppState extends State<SoundifyApp> {
  late AuthStatus _lastStatus = widget.auth.status;

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final status = widget.auth.status;
    if (_lastStatus == AuthStatus.authenticated && status == AuthStatus.unauthenticated) {
      widget.player.stop();
      widget.favorites.clear();
      widget.playlists.clear();
      goToLogin();
    }
    _lastStatus = status;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: widget.prefs),
        Provider.value(value: widget.authRepository),
        Provider.value(value: widget.musicRepository),
        Provider.value(value: widget.deviceSecurity),
        ChangeNotifierProvider.value(value: widget.auth),
        ChangeNotifierProvider.value(value: widget.favorites),
        ChangeNotifierProvider.value(value: widget.playlists),
        ChangeNotifierProvider.value(value: widget.player),
      ],
      child: MaterialApp(
        title: 'Soundify',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        theme: buildDarkTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.dark,
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
