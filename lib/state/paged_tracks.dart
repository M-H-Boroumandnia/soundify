import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/paginated.dart';
import '../data/models/track.dart';
import 'load_state.dart';

typedef PageLoader = Future<Paginated<Track>> Function(int page, CancelToken token);

class PagedTracks extends ChangeNotifier {
  final PageLoader _loader;
  final void Function(List<Track>)? onLoaded;

  PagedTracks(this._loader, {this.onLoaded});

  List<Track> _items = [];
  LoadState _state = LoadState.idle;
  String? _error;
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  CancelToken? _token;

  List<Track> get items => List.unmodifiable(_items);
  LoadState get state => _state;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  Future<void> refresh() async {
    _token?.cancel();
    _token = CancelToken();
    _page = 0;
    _hasMore = true;
    _loadingMore = false;
    _error = null;
    _state = LoadState.loading;
    notifyListeners();
    await _fetch(_token!, reset: true);
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || _state != LoadState.loaded) return;
    _loadingMore = true;
    notifyListeners();
    await _fetch(_token ??= CancelToken(), reset: false);
  }

  Future<void> _fetch(CancelToken token, {required bool reset}) async {
    try {
      final result = await _loader(_page + 1, token);
      if (token.isCancelled) return;
      _page++;
      _hasMore = result.hasNext;
      _items = reset ? result.results : [..._items, ...result.results];
      _state = _items.isEmpty ? LoadState.empty : LoadState.loaded;
      onLoaded?.call(result.results);
    } on ApiException catch (e) {
      if (token.isCancelled || e.code == 'cancelled') return;
      if (reset) {
        _error = e.message;
        _state = LoadState.error;
      } else {
        _error = e.message;
      }
    } finally {
      _loadingMore = false;
      if (!token.isCancelled) notifyListeners();
    }
  }

  void clear() {
    _token?.cancel();
    _items = [];
    _state = LoadState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _token?.cancel();
    super.dispose();
  }
}
