import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/track.dart';
import '../../state/favorites_provider.dart';
import '../../state/player_controller.dart';
import '../theme.dart';
import 'add_to_playlist_sheet.dart';
import 'cover_image.dart';
import 'auto_text.dart';

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

    final secondary = textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 6, 8),
        child: Row(
          children: [
            CoverImage(url: track.coverUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoText(
                    track.title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCurrent ? AppColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: AutoText(
                          track.album.isEmpty
                              ? track.artist
                              : '${track.artist} • ${track.album}',
                          style: secondary,
                        ),
                      ),
                      Text('  •  ', style: secondary),
                      Text(
                        formatSeconds(track.durationSeconds),
                        textDirection: TextDirection.ltr,
                        style: secondary?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: isFavorite ? 'حذف از علاقه‌مندی‌ها' : 'افزودن به علاقه‌مندی‌ها',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 34, height: 40),
              style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              icon: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
              onPressed: () => toggleFavorite(context, track),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 40),
                fixedSize: const Size(28, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 22),
              onSelected: (value) {
                if (value == 'add_playlist') {
                  showAddToPlaylistSheet(context, track);
                } else {
                  onExtraAction?.call(value);
                }
              },
              itemBuilder: (_) => [
                menuItem('add_playlist', Icons.playlist_add_rounded, 'افزودن به پلی‌لیست'),
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
