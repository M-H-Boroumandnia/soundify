import 'paginated.dart';
import 'track.dart';

class Playlist {
  final String id;
  final String name;
  final String description;
  final bool isPublic;
  final int trackCount;
  final List<Track> tracks;
  final String? coverUrl;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.isPublic,
    required this.trackCount,
    required this.tracks,
    this.coverUrl,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final tracks = Paginated.extractList(json['tracks'])
        .map(Track.fromJson)
        .where((t) => t.id.isNotEmpty)
        .toList();
    return Playlist(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      isPublic: json['is_public'] == true,
      trackCount: ((json['track_count'] ?? json['tracks_count']) as num?)
              ?.toInt() ??
          tracks.length,
      tracks: tracks,
      coverUrl: json['cover_url']?.toString() ??
          (tracks.isNotEmpty ? tracks.first.coverUrl : null),
    );
  }

  Playlist copyWith({
    String? name,
    String? description,
    List<Track>? tracks,
  }) {
    final newTracks = tracks ?? this.tracks;
    return Playlist(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      isPublic: isPublic,
      trackCount: tracks != null ? newTracks.length : trackCount,
      tracks: newTracks,
      coverUrl: newTracks.isNotEmpty ? newTracks.first.coverUrl : coverUrl,
    );
  }
}
