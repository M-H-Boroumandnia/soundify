import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/track.dart';
import '../data/repositories/music_repository.dart';
import 'load_state.dart';

class FavoritesProvider extends ChangeNotifier {
  final MusicRepository _repo;

  FavoritesProvider(this._repo);

  List<Track> _tracks = [];
  final Set<String> _ids = {};
  final Set<String> _pending = {};
  LoadState _state = LoadState.idle;
  String? _error;

  List<Track> get tracks => List.unmodifiable(_tracks);
  LoadState get state => _state;
  String? get error => _error;

  bool isFavorite(String id) => _ids.contains(id);

  Future<void> load() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _tracks = await _repo.favorites();
      _ids
        ..clear()
        ..addAll(_tracks.map((t) => t.id));
      _state = _tracks.isEmpty ? LoadState.empty : LoadState.loaded;
    } on ApiException catch (e) {
      _error = e.message;
      _state = LoadState.error;
    }
    notifyListeners();
  }

  void seed(Iterable<Track> tracks) {
    var changed = false;
    for (final t in tracks) {
      if (t.isFavorite && _ids.add(t.id)) changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<String?> toggle(Track track) async {
    if (_pending.contains(track.id)) return null;
    _pending.add(track.id);
    final wasFavorite = _ids.contains(track.id);
    _apply(track, !wasFavorite);
    try {
      if (wasFavorite) {
        await _repo.removeFavorite(track.id);
      } else {
        await _repo.addFavorite(track.id);
      }
      return null;
    } on ApiException catch (e) {
      if (!wasFavorite && e.statusCode == 409) return null;
      if (wasFavorite && e.statusCode == 404) return null;
      _apply(track, wasFavorite);
      return e.message;
    } finally {
      _pending.remove(track.id);
    }
  }

  void clear() {
    _tracks = [];
    _ids.clear();
    _state = LoadState.idle;
    notifyListeners();
  }

  void _apply(Track track, bool favorite) {
    if (favorite) {
      _ids.add(track.id);
      _tracks = [track.copyWith(isFavorite: true), ..._tracks.where((t) => t.id != track.id)];
    } else {
      _ids.remove(track.id);
      _tracks = _tracks.where((t) => t.id != track.id).toList();
    }
    if (_state != LoadState.idle && _state != LoadState.loading) {
      _state = _tracks.isEmpty ? LoadState.empty : LoadState.loaded;
    }
    notifyListeners();
  }
}
