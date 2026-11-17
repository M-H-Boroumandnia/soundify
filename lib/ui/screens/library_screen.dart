import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/playlist.dart';
import '../../state/favorites_provider.dart';
import '../../state/load_state.dart';
import '../../state/player_controller.dart';
import '../../state/playlists_provider.dart';
import '../theme.dart';
import '../widgets/cover_image.dart';
import '../widgets/playlist_form_dialog.dart';
import '../widgets/state_views.dart';
import '../widgets/track_tile.dart';
import 'playlist_detail_screen.dart';
import '../widgets/auto_text.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('کتابخانه من'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'پلی‌لیست‌ها', icon: Icon(Icons.queue_music_rounded)),
              Tab(text: 'علاقه‌مندی‌ها', icon: Icon(Icons.favorite_rounded)),
            ],
          ),
        ),
        body: const TabBarView(children: [_PlaylistsTab(), _FavoritesTab()]),
      ),
    );
  }
}

Future<void> createPlaylist(BuildContext context) async {
  final result = await showPlaylistFormDialog(context);
  if (result == null || !context.mounted) return;
  try {
    await context.read<PlaylistsProvider>().create(result.name, result.description);
    if (context.mounted) showMessage(context, 'پلی‌لیست «${result.name}» ساخته شد');
  } on ApiException catch (e) {
    if (context.mounted) showMessage(context, e.message, error: true);
  }
}

Future<void> editPlaylist(BuildContext context, Playlist playlist) async {
  final result = await showPlaylistFormDialog(
    context,
    initialName: playlist.name,
    initialDescription: playlist.description,
  );
  if (result == null || !context.mounted) return;
  try {
    await context.read<PlaylistsProvider>().update(playlist, result.name, result.description);
    if (context.mounted) showMessage(context, 'پلی‌لیست ویرایش شد');
  } on ApiException catch (e) {
    if (context.mounted) showMessage(context, e.message, error: true);
  }
}

Future<bool> deletePlaylist(BuildContext context, Playlist playlist) async {
  final confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      title: const Text('حذف پلی‌لیست'),
      content: Text('آیا از حذف «${playlist.name}» مطمئن هستید؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('حذف'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  try {
    await context.read<PlaylistsProvider>().delete(playlist.id);
    if (context.mounted) showMessage(context, 'پلی‌لیست حذف شد');
    return true;
  } on ApiException catch (e) {
    if (context.mounted) showMessage(context, e.message, error: true);
    return false;
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlaylistsProvider>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create-playlist',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => createPlaylist(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('پلی‌لیست جدید'),
      ),
      body: FadeSwitcher(
        state: provider.state,
        child: switch (provider.state) {
          LoadState.idle || LoadState.loading => const LoadingView(),
          LoadState.error => ErrorView(message: provider.error ?? 'خطا', onRetry: provider.load),
          LoadState.empty => const EmptyView(
            message: 'هنوز پلی‌لیستی نساخته‌اید.\nبا دکمه پایین اولین پلی‌لیست خود را بسازید',
            icon: Icons.queue_music_rounded,
          ),
          LoadState.loaded => RefreshIndicator(
            onRefresh: provider.load,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: provider.playlists.length,
              itemBuilder: (context, i) => _PlaylistTile(playlist: provider.playlists[i]),
            ),
          ),
        },
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CoverImage(
        url: playlist.coverUrl,
        size: 56,
        placeholderIcon: Icons.queue_music_rounded,
      ),
      title: AutoText(
        playlist.name,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        playlist.description.isEmpty
            ? '${toPersianDigits(playlist.trackCount)} آهنگ'
            : '${toPersianDigits(playlist.trackCount)} آهنگ • ${playlist.description}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PlaylistDetailScreen(playlistId: playlist.id)),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
        onSelected: (value) {
          if (value == 'edit') editPlaylist(context, playlist);
          if (value == 'delete') deletePlaylist(context, playlist);
        },
        itemBuilder: (_) => [
          menuItem('edit', Icons.edit_outlined, 'ویرایش'),
          menuItem('delete', Icons.delete_outline_rounded, 'حذف', danger: true),
        ],
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FavoritesProvider>();
    final tracks = provider.tracks;
    return FadeSwitcher(
      state: provider.state,
      child: switch (provider.state) {
        LoadState.idle || LoadState.loading => const LoadingView(),
        LoadState.error => ErrorView(message: provider.error ?? 'خطا', onRetry: provider.load),
        LoadState.empty => const EmptyView(
          message: 'هنوز آهنگی را لایک نکرده‌اید',
          icon: Icons.favorite_border_rounded,
        ),
        LoadState.loaded => RefreshIndicator(
          onRefresh: provider.load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: FilledButton.icon(
                  onPressed: () => context.read<PlayerController>().playTracks(tracks, 0),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('پخش همه (${tracks.length})'),
                ),
              ),
              for (var i = 0; i < tracks.length; i++)
                TrackTile(
                  track: tracks[i],
                  onTap: () => context.read<PlayerController>().playTracks(tracks, i),
                ),
            ],
          ),
        ),
      },
    );
  }
}
