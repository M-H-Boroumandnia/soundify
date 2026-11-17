import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../data/models/track.dart';

class PositionData {
  final Duration position;
  final Duration buffered;
  final Duration duration;

  const PositionData(this.position, this.buffered, this.duration);
}

class PlayerController extends ChangeNotifier {
  final AndroidEqualizer equalizer = AndroidEqualizer();
  late final AudioPlayer _player = AudioPlayer(
    audioPipeline: AudioPipeline(androidAudioEffects: [equalizer]),
    audioLoadConfiguration: const AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        minBufferDuration: Duration(seconds: 15),
        maxBufferDuration: Duration(seconds: 60),
        bufferForPlaybackDuration: Duration(milliseconds: 500),
        bufferForPlaybackAfterRebufferDuration: Duration(seconds: 2),
        prioritizeTimeOverSizeThresholds: true,
      ),
    ),
  );

  final List<StreamSubscription<dynamic>> _subs = [];
  List<Track> _queue = [];
  int? _index;
  String? _error;
  bool _initialized = false;

  AudioPlayer get player => _player;
  List<Track> get queue => List.unmodifiable(_queue);
  Track? get current =>
      _index != null && _index! < _queue.length ? _queue[_index!] : null;
  bool get hasTrack => current != null;
  bool get isPlaying => _player.playing;
  bool get isBuffering =>
      _player.processingState == ProcessingState.loading ||
      _player.processingState == ProcessingState.buffering;
  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;
  String? get error => _error;

  Stream<PositionData> get positionStream {
    late StreamController<PositionData> controller;
    StreamSubscription<Duration>? sub;
    controller = StreamController<PositionData>(
      onListen: () {
        sub = _player.createPositionStream(
          minPeriod: const Duration(milliseconds: 200),
          maxPeriod: const Duration(milliseconds: 200),
        ).listen((position) {
          controller.add(PositionData(
            position,
            _player.bufferedPosition,
            _player.duration ?? current?.duration ?? Duration.zero,
          ));
        });
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _subs.add(_player.currentIndexStream.listen((index) {
      _index = index;
      notifyListeners();
    }));
    _subs.add(_player.playerStateStream.listen((_) => notifyListeners()));
    _subs.add(_player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace _) {
        _error = 'خطا در پخش آهنگ';
        notifyListeners();
      },
    ));
  }

  Future<void> playTracks(List<Track> tracks, int startIndex) async {
    if (tracks.isEmpty) return;
    final sameQueue = _queue.length == tracks.length &&
        Iterable.generate(tracks.length)
            .every((i) => _queue[i].id == tracks[i].id);
    if (sameQueue) {
      unawaited(_player.seek(Duration.zero, index: startIndex));
      unawaited(_player.play());
      return;
    }
    _error = null;
    _queue = List.of(tracks);
    _index = startIndex;
    notifyListeners();
    try {
      final loading = _player.setAudioSources(
        _queue.map(_toSource).toList(),
        initialIndex: startIndex,
      );
      unawaited(_player.play());
      await loading;
    } on PlayerException catch (e) {
      _error = e.message ?? 'خطا در پخش آهنگ';
      notifyListeners();
    } on PlayerInterruptedException {
      return;
    }
  }

  Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero, index: 0);
      }
      unawaited(_player.play());
    }
  }

  Future<void> next() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  Future<void> previous() async {
    if (_player.position > const Duration(seconds: 3) || !_player.hasPrevious) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() async {
    await _player.stop();
    _queue = [];
    _index = null;
    notifyListeners();
  }

  AudioSource _toSource(Track track) => AudioSource.uri(
        Uri.parse(track.streamUrl),
        tag: MediaItem(
          id: track.id,
          title: track.title,
          artist: track.artist,
          album: track.album,
          duration: track.durationSeconds > 0 ? track.duration : null,
          artUri: track.coverUrl != null ? Uri.tryParse(track.coverUrl!) : null,
        ),
      );

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
