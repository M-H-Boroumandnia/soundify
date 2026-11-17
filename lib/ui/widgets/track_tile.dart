import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/track.dart';
import '../../state/favorites_provider.dart';
import '../../state/player_controller.dart';
import '../theme.dart';
import 'add_to_playlist_sheet.dart';
import 'cover_image.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final List<PopupMenuEntry<String>> extraActions;
  final void Function(String action)? onExtraAction;

  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.extraActions = const [],
    this.onExtraAction,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = context.select<PlayerController, bool>(
      (p) => p.current?.id == track.id,
    );
    final isFavorite = context.select<FavoritesProvider, bool>(
      (f) => f.isFavorite(track.id),
    );
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CoverImage(url: track.coverUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCurrent ? AppColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.album.isEmpty
                        ? track.artist
                        : '${track.artist} • ${track.album}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              formatSeconds(track.durationSeconds),
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            IconButton(
              tooltip: isFavorite ? 'حذف از علاقه‌مندی‌ها' : 'افزودن به علاقه‌مندی‌ها',
              icon: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? AppColors.primary : AppColors.textSecondary,
              ),
              onPressed: () => toggleFavorite(context, track),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
              onSelected: (value) {
                if (value == 'add_playlist') {
                  showAddToPlaylistSheet(context, track);
                } else {
                  onExtraAction?.call(value);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'add_playlist',
                  child: Text('افزودن به پلی‌لیست'),
                ),
                ...extraActions,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> toggleFavorite(BuildContext context, Track track) async {
  final error = await context.read<FavoritesProvider>().toggle(track);
  if (error != null && context.mounted) showMessage(context, error, error: true);
}
