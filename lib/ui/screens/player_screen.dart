import 'dart:math' as math;

import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../state/favorites_provider.dart';
import '../../state/player_controller.dart';
import '../theme.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/cover_image.dart';
import '../widgets/track_tile.dart';
import '../widgets/auto_text.dart';
import '../widgets/equalizer_sheet.dart';

void openPlayerScreen(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => const PlayerScreen(),
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
        child: child,
      ),
    ),
  );
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Stream<PositionData> _position = context
      .read<PlayerController>()
      .positionStream;
  double? _dragValue;
  String? _shownError;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final track = player.current;
    final textTheme = Theme.of(context).textTheme;

    final error = player.error;
    if (error != null && error != _shownError) {
      _shownError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showMessage(context, error, error: true);
      });
    } else if (error == null) {
      _shownError = null;
    }

    if (track == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('آهنگی در حال پخش نیست')),
      );
    }

    final isFavorite = context.select<FavoritesProvider, bool>(
      (f) => f.isFavorite(track.id),
    );
    final coverSize = math.min(MediaQuery.sizeOf(context).width - 64, 340.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1D3B2A), AppColors.background],
            stops: [0, 0.65],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'بستن',
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 32,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'در حال پخش',
                        textAlign: TextAlign.center,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'اکولایزر',
                      icon: const Icon(Icons.equalizer_rounded),
                      onPressed: () => _showEqualizer(context, player),
                    ),
                  ],
                ),
                const Spacer(),
                Hero(
                  tag: 'cover-${track.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 40,
                          offset: Offset(0, 16),
                        ),
                      ],
                    ),
                    child: CoverImage(
                      url: track.coverUrl,
                      size: coverSize,
                      radius: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 36,
                  child: _Visualizer(
                    active: player.isPlaying && !player.isBuffering,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoText(
                            track.title,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AutoText(
                            track.album.isEmpty
                                ? track.artist
                                : '${track.artist} • ${track.album}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'افزودن به پلی‌لیست',
                      icon: const Icon(Icons.playlist_add_rounded),
                      onPressed: () => showAddToPlaylistSheet(context, track),
                    ),
                    IconButton(
                      tooltip: 'علاقه‌مندی',
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? AppColors.primary : null,
                        size: 28,
                      ),
                      onPressed: () => toggleFavorite(context, track),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSeekBar(player),
                const SizedBox(height: 8),
                _buildControls(player),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeekBar(PlayerController player) {
    return StreamBuilder<PositionData>(
      stream: _position,
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            PositionData(
              Duration.zero,
              Duration.zero,
              player.current?.duration ?? Duration.zero,
            );
        final max = data.duration.inMilliseconds.toDouble();
        final position = data.position.inMilliseconds.clamp(0, max).toDouble();
        final value = (_dragValue ?? position).clamp(0.0, max > 0 ? max : 1.0);
        final buffered = data.buffered.inMilliseconds.clamp(0, max).toDouble();
        final style = Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.textSecondary);

        return Column(
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: LinearProgressIndicator(
                      value: max > 0 ? buffered / max : 0,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                      color: AppColors.textSecondary.withValues(alpha: 0.35),
                      backgroundColor: AppColors.surfaceHigh,
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context)
                        .copyWith(inactiveTrackColor: Colors.transparent),
                    child: Slider(
                      min: 0,
                      max: max > 0 ? max : 1,
                      value: value,
                      onChanged: max > 0
                          ? (v) => setState(() => _dragValue = v)
                          : null,
                      onChangeEnd: (v) {
                        player.seek(Duration(milliseconds: v.round()));
                        setState(() => _dragValue = null);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDuration(Duration(milliseconds: value.round())),
                      style: style,
                    ),
                    Text(formatDuration(data.duration), style: style),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(PlayerController player) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StreamBuilder<LoopMode>(
            stream: player.player.loopModeStream,
            builder: (context, snapshot) {
              final mode = snapshot.data ?? LoopMode.off;
              return IconButton(
                tooltip: 'تکرار',
                icon: Icon(
                  mode == LoopMode.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  color: mode == LoopMode.off
                      ? AppColors.textSecondary
                      : AppColors.primary,
                ),
                onPressed: () => player.player.setLoopMode(
                  LoopMode.values[(mode.index + 1) % LoopMode.values.length],
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'قبلی',
            iconSize: 40,
            icon: const Icon(Icons.skip_previous_rounded),
            onPressed: player.previous,
          ),
          SizedBox(
            width: 72,
            height: 72,
            child: player.isBuffering
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : IconButton.filled(
                    tooltip: player.isPlaying ? 'توقف' : 'پخش',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    iconSize: 42,
                    icon: Icon(
                      player.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    onPressed: player.togglePlay,
                  ),
          ),
          IconButton(
            tooltip: 'بعدی',
            iconSize: 40,
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: player.canNext ? player.next : null,
          ),
          StreamBuilder<bool>(
            stream: player.player.shuffleModeEnabledStream,
            builder: (context, snapshot) {
              final enabled = snapshot.data ?? false;
              return IconButton(
                tooltip: 'پخش تصادفی',
                icon: Icon(
                  Icons.shuffle_rounded,
                  color: enabled ? AppColors.primary : AppColors.textSecondary,
                ),
                onPressed: () async {
                  if (!enabled) await player.player.shuffle();
                  await player.player.setShuffleModeEnabled(!enabled);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEqualizer(BuildContext context, PlayerController player) {
    showEqualizerSheet(context, player.equalizer);
  }
}

class _Visualizer extends StatefulWidget {
  final bool active;

  const _Visualizer({required this.active});

  @override
  State<_Visualizer> createState() => _VisualizerState();
}

class _VisualizerState extends State<_Visualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _Visualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bars = 24;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(bars, (i) {
            final wave = widget.active
                ? 0.25 +
                      0.75 *
                          ((math.sin(t * 2 + i * 0.7) +
                                  math.sin(t * 3 + i * 1.3) +
                                  2) /
                              4)
                : 0.12;
            return Container(
              width: 4,
              height: 36 * wave,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.4 + 0.6 * wave),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
