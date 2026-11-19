import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/player_controller.dart';
import '../screens/player_screen.dart';
import '../theme.dart';
import 'cover_image.dart';
import 'auto_text.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  late final Stream<PositionData> _position = context
      .read<PlayerController>()
      .positionStream;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final track = player.current;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: track == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Material(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                elevation: 6,
                shadowColor: Colors.black,
                child: InkWell(
                  onTap: () => openPlayerScreen(context),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<PositionData>(
                        stream: _position,
                        builder: (context, snapshot) {
                          final data = snapshot.data;
                          final total = data?.duration.inMilliseconds ?? 0;
                          final value = total > 0
                              ? (data!.position.inMilliseconds / total).clamp(
                                  0.0,
                                  1.0,
                                )
                              : 0.0;
                          return Directionality(
                            textDirection: TextDirection.ltr,
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 2,
                              color: AppColors.primary,
                              backgroundColor: Colors.transparent,
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'cover-${track.id}',
                              child: CoverImage(
                                url: track.coverUrl,
                                size: 44,
                                radius: 6,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AutoText(
                                    track.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  AutoText(
                                    player.error ?? track.artist,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: player.error != null
                                              ? AppColors.danger
                                              : AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'قبلی',
                                    onPressed: player.previous,
                                    icon: const Icon(
                                      Icons.skip_previous_rounded,
                                    ),
                                  ),
                                  _PlayPauseButton(player: player),
                                  IconButton(
                                    tooltip: 'بعدی',
                                    onPressed: player.canNext
                                        ? player.next
                                        : null,
                                    icon: const Icon(Icons.skip_next_rounded),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final PlayerController player;

  const _PlayPauseButton({required this.player});

  @override
  Widget build(BuildContext context) {
    if (player.isBuffering) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.primary,
          ),
        ),
      );
    }
    if (player.error != null && !player.isPlaying) {
      return IconButton(
        tooltip: 'تلاش دوباره',
        onPressed: player.togglePlay,
        icon: const Icon(
          Icons.refresh_rounded,
          size: 28,
          color: AppColors.danger,
        ),
      );
    }
    return IconButton(
      tooltip: player.isPlaying ? 'توقف' : 'پخش',
      onPressed: player.togglePlay,
      icon: Icon(
        player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: 30,
      ),
    );
  }
}
