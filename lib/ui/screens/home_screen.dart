import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/track.dart';
import '../../data/repositories/music_repository.dart';
import '../../state/auth_provider.dart';
import '../../state/favorites_provider.dart';
import '../../state/load_state.dart';
import '../../state/paged_tracks.dart';
import '../../state/player_controller.dart';
import '../theme.dart';
import '../widgets/cover_image.dart';
import '../widgets/state_views.dart';
import '../widgets/track_tile.dart';
import 'track_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MusicRepository _repo = context.read<MusicRepository>();
  late final PagedTracks _all = PagedTracks(
    (page, token) => _repo.tracks(page: page, cancelToken: token),
    onLoaded: context.read<FavoritesProvider>().seed,
  );
  final _scroll = ScrollController();

  List<Track> _featured = [];
  LoadState _featuredState = LoadState.idle;
  String? _featuredError;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _all.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) _all.loadMore();
  }

  Future<void> _load() async {
    setState(() {
      _featuredState = LoadState.loading;
      _featuredError = null;
    });
    await Future.wait([_loadFeatured(), _all.refresh()]);
  }

  Future<void> _loadFeatured() async {
    try {
      final items = await _repo.featured();
      if (!mounted) return;
      context.read<FavoritesProvider>().seed(items);
      setState(() {
        _featured = items;
        _featuredState = items.isEmpty ? LoadState.empty : LoadState.loaded;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _featuredError = e.message;
        _featuredState = LoadState.error;
      });
    }
  }

  List<String> get _artists {
    final counts = <String, int>{};
    for (final t in [..._featured, ..._all.items]) {
      if (t.artist.isEmpty) continue;
      counts[t.artist] = (counts[t.artist] ?? 0) + 1;
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return sorted.take(10).toList();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صبح بخیر';
    if (hour < 18) return 'عصر بخیر';
    return 'شب بخیر';
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthProvider, String?>((a) => a.user?.name);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _all,
          builder: (context, _) {
            if (_featuredState == LoadState.error && _all.state == LoadState.error) {
              return ErrorView(message: _featuredError ?? 'خطا', onRetry: _load);
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(name)),
                  SliverToBoxAdapter(child: _buildFeatured()),
                  if (_artists.isNotEmpty) SliverToBoxAdapter(child: _buildCategories()),
                  const SliverToBoxAdapter(child: _SectionTitle('همه آهنگ‌ها')),
                  ..._buildAllTracks(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String? name) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          name == null ? _greeting : '$_greeting، $name',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      );

  Widget _buildFeatured() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('منتخب‌ها'),
        SizedBox(
          height: 230,
          child: switch (_featuredState) {
            LoadState.idle || LoadState.loading => const LoadingView(),
            LoadState.error => ErrorView(message: _featuredError ?? 'خطا', onRetry: _loadFeatured),
            LoadState.empty => const EmptyView(message: 'آهنگ منتخبی وجود ندارد'),
            LoadState.loaded => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _featured.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) => _FeaturedCard(
                  track: _featured[i],
                  onTap: () => context.read<PlayerController>().playTracks(_featured, i),
                ),
              ),
          },
        ),
      ],
    );
  }

  Widget _buildCategories() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('دسته‌بندی خوانندگان'),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _artists.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final artist = _artists[i];
                return ActionChip(
                  label: Text(artist),
                  avatar: const Icon(Icons.mic_rounded, size: 18),
                  backgroundColor: AppColors.surfaceHigh,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => TrackListScreen(
                      title: artist,
                      loader: (page, token) =>
                          _repo.tracksByArtist(artist, page: page, cancelToken: token),
                    ),
                  )),
                );
              },
            ),
          ),
        ],
      );

  List<Widget> _buildAllTracks() {
    switch (_all.state) {
      case LoadState.idle:
      case LoadState.loading:
        return const [SliverToBoxAdapter(child: LoadingView())];
      case LoadState.error:
        return [
          SliverToBoxAdapter(
            child: ErrorView(message: _all.error ?? 'خطا', onRetry: _all.refresh),
          ),
        ];
      case LoadState.empty:
        return const [SliverToBoxAdapter(child: EmptyView(message: 'آهنگی یافت نشد'))];
      case LoadState.loaded:
        final items = _all.items;
        return [
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => TrackTile(
              track: items[i],
              onTap: () => context.read<PlayerController>().playTracks(items, i),
            ),
          ),
          SliverToBoxAdapter(
            child: _all.hasMore
                ? const Padding(padding: EdgeInsets.all(16), child: LoadingView())
                : const SizedBox(height: 24),
          ),
        ];
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      );
}

class _FeaturedCard extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const _FeaturedCard({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CoverImage(url: track.coverUrl, size: 160, radius: 14),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.play_arrow_rounded, color: AppColors.onPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
