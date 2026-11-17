import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/playlist.dart';
import '../../data/models/track.dart';
import '../../state/load_state.dart';
import '../../state/playlists_provider.dart';
import '../theme.dart';
import 'cover_image.dart';
import 'playlist_form_dialog.dart';
import 'state_views.dart';

Future<void> showAddToPlaylistSheet(BuildContext context, Track track) {
  final provider = context.read<PlaylistsProvider>();
  if (provider.state == LoadState.idle || provider.state == LoadState.error) {
    provider.load();
  }
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (sheetContext) => _AddToPlaylistSheet(track: track),
  );
}

class _AddToPlaylistSheet extends StatelessWidget {
  final Track track;

  const _AddToPlaylistSheet({required this.track});

  Future<void> _add(
    BuildContext context,
    PlaylistsProvider provider,
    Playlist playlist,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    try {
      await provider.addTrack(playlist, track);
      messenger.showSnackBar(SnackBar(content: Text('به «${playlist.name}» اضافه شد')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.statusCode == 409 ? 'این آهنگ از قبل در پلی‌لیست است' : e.message),
      ));
    }
  }

  Future<void> _createAndAdd(BuildContext context, PlaylistsProvider provider) async {
    final result = await showPlaylistFormDialog(context);
    if (result == null || !context.mounted) return;
    try {
      final created = await provider.create(result.name, result.description);
      if (context.mounted) await _add(context, provider, created);
    } on ApiException catch (e) {
      if (context.mounted) showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlaylistsProvider>();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('افزودن به پلی‌لیست',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  TextButton.icon(
                    onPressed: () => _createAndAdd(context, provider),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('پلی‌لیست جدید'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: switch (provider.state) {
                LoadState.loading || LoadState.idle => const LoadingView(),
                LoadState.error => ErrorView(
                    message: provider.error ?? 'خطا',
                    onRetry: provider.load,
                  ),
                LoadState.empty => const EmptyView(
                    message: 'هنوز پلی‌لیستی نساخته‌اید',
                    icon: Icons.queue_music_rounded,
                  ),
                LoadState.loaded => ListView(
                    shrinkWrap: true,
                    children: [
                      for (final p in provider.playlists)
                        ListTile(
                          leading: CoverImage(
                            url: p.coverUrl,
                            size: 44,
                            placeholderIcon: Icons.queue_music_rounded,
                          ),
                          title: Text(p.name),
                          subtitle: Text('${p.trackCount} آهنگ',
                              style: const TextStyle(color: AppColors.textSecondary)),
                          onTap: () => _add(context, provider, p),
                        ),
                    ],
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
