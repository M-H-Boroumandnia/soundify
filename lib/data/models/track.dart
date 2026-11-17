import '../../core/config.dart';

class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? coverUrl;
  final int durationSeconds;
  final String streamUrl;
  final bool isFavorite;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverUrl,
    required this.durationSeconds,
    required this.streamUrl,
    this.isFavorite = false,
  });

  Duration get duration => Duration(seconds: durationSeconds);

  factory Track.fromJson(Map<String, dynamic> json) {
    final source = json['track'] is Map
        ? Map<String, dynamic>.from(json['track'] as Map)
        : json;
    final id = (source['id'] ?? source['track_id'] ?? '').toString();
    return Track(
      id: id,
      title: (source['title'] ?? '').toString(),
      artist: (source['artist'] ?? '').toString(),
      album: (source['album'] ?? '').toString(),
      coverUrl: source['cover_url']?.toString(),
      durationSeconds: (source['duration'] as num?)?.toInt() ?? 0,
      streamUrl: source['stream_url']?.toString() ??
          '${AppConfig.baseUrl}/tracks/$id/stream/',
      isFavorite: source['is_favorite'] == true,
    );
  }

  Track copyWith({bool? isFavorite}) => Track(
        id: id,
        title: title,
        artist: artist,
        album: album,
        coverUrl: coverUrl,
        durationSeconds: durationSeconds,
        streamUrl: streamUrl,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
