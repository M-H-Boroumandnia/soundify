import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/playlist.dart';
import '../../data/models/track.dart';
import '../../state/player_controller.dart';
import '../../state/playlists_provider.dart';
import '../theme.dart';
import '../widgets/cover_image.dart';
import '../widgets/state_views.dart';
import '../widgets/track_tile.dart';
import 'library_screen.dart';
import '../widgets/auto_text.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<PlaylistsProvider>().fetchDetail(widget.playlistId);
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _removeTrack(Playlist playlist, Track track) async {
    try {
      await context.read<PlaylistsProvider>().removeTrack(playlist, track);
      if (mounted) showMessage(context, '«${track.title}» از پلی‌لیست حذف شد');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlist = context.select<PlaylistsProvider, Playlist?>(
      (p) => p.byId(widget.playlistId),
    );

    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _loading
            ? const LoadingView()
            : ErrorView(message: _error ?? 'پلی‌لیست یافت نشد', onRetry: _load),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'ویرایش',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => editPlaylist(context, playlist),
          ),
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final deleted = await deletePlaylist(context, playlist);
              if (deleted && context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _Header(playlist: playlist),
            if (_loading && playlist.tracks.isEmpty)
              const LoadingView()
            else if (_error != null && playlist.tracks.isEmpty)
              ErrorView(message: _error!, onRetry: _load)
            else if (playlist.tracks.isEmpty)
              const EmptyView(
                message: 'این پلی‌لیست خالی است.\nاز منوی هر آهنگ آن را به پلی‌لیست اضافه کنید',
              )
            else
              for (var i = 0; i < playlist.tracks.length; i++)
                TrackTile(
                  track: playlist.tracks[i],
                  onTap: () =>
                      context.read<PlayerController>().playTracks(playlist.tracks, i),
                  extraActions: [
                    menuItem(
                      'remove',
                      Icons.playlist_remove_rounded,
                      'حذف از این پلی‌لیست',
                      danger: true,
                    ),
                  ],
                  onExtraAction: (action) {
                    if (action == 'remove') _removeTrack(playlist, playlist.tracks[i]);
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Playlist playlist;

  const _Header({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          CoverImage(
            url: playlist.coverUrl,
            size: 180,
            radius: 16,
            placeholderIcon: Icons.queue_music_rounded,
          ),
          const SizedBox(height: 16),
          AutoText(
            playlist.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (playlist.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              playlist.description,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '${toPersianDigits(playlist.tracks.length)} آهنگ',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (playlist.tracks.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: FilledButton.icon(
                onPressed: () =>
                    context.read<PlayerController>().playTracks(playlist.tracks, 0),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('پخش'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
