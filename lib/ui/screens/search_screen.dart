import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/utils/debouncer.dart';
import '../../data/repositories/music_repository.dart';
import '../../state/favorites_provider.dart';
import '../../state/load_state.dart';
import '../../state/paged_tracks.dart';
import '../../state/player_controller.dart';
import '../widgets/state_views.dart';
import '../widgets/track_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _debouncer = Debouncer(AppConfig.searchDebounce);
  late final MusicRepository _repo = context.read<MusicRepository>();
  late final PagedTracks _results = PagedTracks(
    (page, token) => _repo.tracks(query: _query, page: page, cancelToken: token),
    onLoaded: context.read<FavoritesProvider>().seed,
  );
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _results.loadMore();
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    _scroll.dispose();
    _results.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    final query = value.trim();
    if (query.isEmpty) {
      _debouncer.cancel();
      _query = '';
      _results.clear();
      return;
    }
    _debouncer.run(() {
      if (query == _query && _results.state != LoadState.error) return;
      _query = query;
      _results.refresh();
    });
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جست‌وجو')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'نام آهنگ یا خواننده...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.close_rounded), onPressed: _clear),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _results,
              builder: (context, _) => switch (_results.state) {
                LoadState.idle => const EmptyView(
                    message: 'آهنگ یا خواننده مورد نظر خود را جست‌وجو کنید',
                    icon: Icons.manage_search_rounded,
                  ),
                LoadState.loading => const LoadingView(),
                LoadState.error => ErrorView(
                    message: _results.error ?? 'خطا',
                    onRetry: _results.refresh,
                  ),
                LoadState.empty => EmptyView(
                    message: 'نتیجه‌ای برای «$_query» یافت نشد',
                    icon: Icons.search_off_rounded,
                  ),
                LoadState.loaded => ListView.builder(
                    controller: _scroll,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: _results.items.length + (_results.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= _results.items.length) return const LoadingView();
                      return TrackTile(
                        track: _results.items[i],
                        onTap: () => context
                            .read<PlayerController>()
                            .playTracks(_results.items, i),
                      );
                    },
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
