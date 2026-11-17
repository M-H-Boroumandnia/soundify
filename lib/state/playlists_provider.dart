import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/playlist.dart';
import '../data/models/track.dart';
import '../data/repositories/music_repository.dart';
import 'load_state.dart';

class PlaylistsProvider extends ChangeNotifier {
  final MusicRepository _repo;

  PlaylistsProvider(this._repo);

  List<Playlist> _playlists = [];
  LoadState _state = LoadState.idle;
  String? _error;

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  LoadState get state => _state;
  String? get error => _error;

  Playlist? byId(String id) {
    for (final p in _playlists) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> load() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _playlists = await _repo.playlists();
      _state = _playlists.isEmpty ? LoadState.empty : LoadState.loaded;
    } on ApiException catch (e) {
      _error = e.message;
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<Playlist> fetchDetail(String id) async {
    final detail = await _repo.playlist(id);
    _replace(detail);
    return detail;
  }

  Future<Playlist> create(String name, String description) async {
    final created = await _repo.createPlaylist(name, description);
    _playlists = [created, ..._playlists];
    _state = LoadState.loaded;
    notifyListeners();
    return created;
  }

  Future<void> update(Playlist playlist, String name, String description) async {
    await _repo.updatePlaylist(playlist.id, name, description);
    _replace(playlist.copyWith(name: name, description: description));
  }

  Future<void> delete(String id) async {
    await _repo.deletePlaylist(id);
    _playlists = _playlists.where((p) => p.id != id).toList();
    if (_playlists.isEmpty) _state = LoadState.empty;
    notifyListeners();
  }

  Future<void> addTrack(Playlist playlist, Track track) async {
    await _repo.addToPlaylist(playlist.id, track.id);
    final current = byId(playlist.id) ?? playlist;
    if (current.tracks.any((t) => t.id == track.id)) return;
    _replace(current.copyWith(tracks: [...current.tracks, track]));
  }

  Future<void> removeTrack(Playlist playlist, Track track) async {
    await _repo.removeFromPlaylist(playlist.id, track.id);
    final current = byId(playlist.id) ?? playlist;
    _replace(current.copyWith(
      tracks: current.tracks.where((t) => t.id != track.id).toList(),
    ));
  }

  void clear() {
    _playlists = [];
    _state = LoadState.idle;
    notifyListeners();
  }

  void _replace(Playlist updated) {
    final index = _playlists.indexWhere((p) => p.id == updated.id);
    if (index == -1) {
      _playlists = [updated, ..._playlists];
    } else {
      _playlists = [..._playlists]..[index] = updated;
    }
    notifyListeners();
  }
}
