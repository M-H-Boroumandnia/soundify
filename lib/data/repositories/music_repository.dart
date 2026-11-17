import 'package:dio/dio.dart';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../models/paginated.dart';
import '../models/playlist.dart';
import '../models/track.dart';

class MusicRepository {
  final ApiClient _api;

  MusicRepository(this._api);

  Future<List<Track>> featured() async {
    final data = await _api.get('/tracks/featured/');
    return Paginated.fromJson(data, Track.fromJson).results;
  }

  Future<Paginated<Track>> tracks({
    String? query,
    int page = 1,
    int pageSize = AppConfig.pageSize,
    CancelToken? cancelToken,
  }) async {
    final data = await _api.get(
      '/tracks/',
      query: {
        if (query != null && query.isNotEmpty) 'q': query,
        'page': page,
        'page_size': pageSize,
      },
      cancelToken: cancelToken,
    );
    return Paginated.fromJson(data, Track.fromJson);
  }

  Future<Paginated<Track>> tracksByArtist(
    String artist, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final data = await _api.get(
      '/tracks/',
      query: {'artist': artist, 'page': page, 'page_size': AppConfig.pageSize},
      cancelToken: cancelToken,
    );
    return Paginated.fromJson(data, Track.fromJson);
  }

  Future<List<Track>> favorites() async {
    final data = await _api.get('/favorites/', query: {'page_size': 100});
    return Paginated.fromJson(data, Track.fromJson)
        .results
        .where((t) => t.id.isNotEmpty)
        .map((t) => t.copyWith(isFavorite: true))
        .toList();
  }

  Future<void> addFavorite(String trackId) =>
      _api.post('/favorites/', data: {'track_id': trackId});

  Future<void> removeFavorite(String trackId) =>
      _api.delete('/favorites/$trackId/');

  Future<List<Playlist>> playlists() async {
    final data = await _api.get('/playlists/');
    return Paginated.fromJson(data, Playlist.fromJson).results;
  }

  Future<Playlist> playlist(String id) async {
    final data = await _api.get('/playlists/$id/');
    return Playlist.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Playlist> createPlaylist(String name, String description) async {
    final data = await _api.post('/playlists/', data: {
      'name': name,
      'description': description,
      'is_public': false,
    });
    return Playlist.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> updatePlaylist(String id, String name, String description) =>
      _api.patch('/playlists/$id/', data: {
        'name': name,
        'description': description,
      });

  Future<void> deletePlaylist(String id) => _api.delete('/playlists/$id/');

  Future<void> addToPlaylist(String playlistId, String trackId) =>
      _api.post('/playlists/$playlistId/tracks/', data: {'track_id': trackId});

  Future<void> removeFromPlaylist(String playlistId, String trackId) =>
      _api.delete('/playlists/$playlistId/tracks/$trackId/');
}
