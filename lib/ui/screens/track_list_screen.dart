import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/favorites_provider.dart';
import '../../state/load_state.dart';
import '../../state/paged_tracks.dart';
import '../../state/player_controller.dart';
import '../widgets/state_views.dart';
import '../widgets/track_tile.dart';

class TrackListScreen extends StatefulWidget {
  final String title;
  final PageLoader loader;

  const TrackListScreen({super.key, required this.title, required this.loader});

  @override
  State<TrackListScreen> createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  late final PagedTracks _paged = PagedTracks(
    widget.loader,
    onLoaded: context.read<FavoritesProvider>().seed,
  )..refresh();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _paged.loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _paged.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListenableBuilder(
        listenable: _paged,
        builder: (context, _) => switch (_paged.state) {
          LoadState.idle || LoadState.loading => const LoadingView(),
          LoadState.error => ErrorView(message: _paged.error ?? 'خطا', onRetry: _paged.refresh),
          LoadState.empty => const EmptyView(message: 'آهنگی یافت نشد'),
          LoadState.loaded => RefreshIndicator(
              onRefresh: _paged.refresh,
              child: ListView.builder(
                controller: _scroll,
                itemCount: _paged.items.length + (_paged.hasMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= _paged.items.length) return const LoadingView();
                  return TrackTile(
                    track: _paged.items[i],
                    onTap: () => context.read<PlayerController>().playTracks(_paged.items, i),
                  );
                },
              ),
            ),
        },
      ),
    );
  }
}
