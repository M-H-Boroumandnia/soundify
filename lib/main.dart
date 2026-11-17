import 'package:just_audio_background/just_audio_background.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/security/biometric_service.dart';
import 'core/security/device_security.dart';
import 'core/storage/app_prefs.dart';
import 'core/storage/token_storage.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/music_repository.dart';
import 'state/auth_provider.dart';
import 'state/favorites_provider.dart';
import 'state/player_controller.dart';
import 'state/playlists_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'ir.soundify.channel.audio',
    androidNotificationChannelName: 'پخش موسیقی',
    androidNotificationOngoing: true,
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final prefs = await AppPrefs.create();
  final tokens = TokenStorage();
  late final AuthProvider auth;
  final api = ApiClient(
    storage: tokens,
    onSessionExpired: () => auth.handleSessionExpired(),
  );
  final authRepo = AuthRepository(api, tokens);
  final musicRepo = MusicRepository(api);
  auth = AuthProvider(authRepo, prefs, BiometricService());
  final player = PlayerController();
  await player.init();

  runApp(SoundifyApp(
    prefs: prefs,
    authRepository: authRepo,
    musicRepository: musicRepo,
    auth: auth,
    favorites: FavoritesProvider(musicRepo),
    playlists: PlaylistsProvider(musicRepo),
    player: player,
    deviceSecurity: DeviceSecurityService(),
  ));
}
