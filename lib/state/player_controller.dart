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
  bool _loaded = false;
  bool _retrying = false;
  int _retries = 0;
  int _loadId = 0;

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
  bool get canNext => _index != null && _index! + 1 < _queue.length;
  bool get canPrevious => _index != null && _index! > 0;
  String? get error => _error;

  Stream<PositionData> get positionStream {
    late StreamController<PositionData> controller;
    StreamSubscription<Duration>? sub;
    controller = StreamController<PositionData>(
      onListen: () {
        sub = _player
            .createPositionStream(
              minPeriod: const Duration(milliseconds: 200),
              maxPeriod: const Duration(milliseconds: 200),
            )
            .listen((position) {
              controller.add(
                PositionData(
                  position,
                  _player.bufferedPosition,
                  _player.duration ?? current?.duration ?? Duration.zero,
                ),
              );
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
    _subs.add(
      _player.currentIndexStream.listen((index) {
        if (_index != index) _retries = 0;
        _index = index;
        notifyListeners();
      }),
    );
    _subs.add(_player.playerStateStream.listen((_) => notifyListeners()));
    _subs.add(_player.errorStream.listen((_) => _onPlaybackError()));
    _subs.add(
      _player.playbackEventStream.listen(
        (_) {},
        onError: (Object e, StackTrace _) => _onPlaybackError(),
      ),
    );
  }

  Future<void> playTracks(List<Track> tracks, int startIndex) {
    _retries = 0;
    return _load(tracks, startIndex);
  }

  Future<void> _load(List<Track> tracks, int startIndex) async {
    if (tracks.isEmpty) return;
    final sameQueue =
        _queue.length == tracks.length &&
        Iterable.generate(tracks.length)
            .every((i) => _queue[i].id == tracks[i].id);
    if (sameQueue && _loaded) {
      await _player.seek(Duration.zero, index: startIndex);
      _start();
      return;
    }
    final loadId = ++_loadId;
    _error = null;
    _queue = List.of(tracks);
    _index = startIndex;
    _loaded = false;
    notifyListeners();
    try {
      final loading = _player.setAudioSources(
        _queue.map(_toSource).toList(),
        initialIndex: startIndex,
      );
      _start();
      await loading;
      if (loadId != _loadId) return;
      _loaded = true;
      if (!_player.playing) _start();
    } on PlayerException {
      if (loadId != _loadId) return;
      _loaded = false;
      _onPlaybackError();
    } on PlayerInterruptedException {
      return;
    }
  }

  void _start() {
    unawaited(_player.play().catchError((Object _) {}));
  }

  void _halt() {
    unawaited(_player.stop().catchError((Object _) {}));
  }

  void _onPlaybackError() {
    if (_queue.isEmpty || _index == null) return;
    _loaded = false;
    if (_retrying) return;
    if (_retries >= 2) {
      _error = 'خطا در پخش آهنگ';
      _halt();
      notifyListeners();
      return;
    }
    final loadId = _loadId;
    _retries++;
    _retrying = true;
    _error = 'اتصال قطع شد؛ تلاش دوباره';
    notifyListeners();
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      _retrying = false;
      if (loadId != _loadId || _queue.isEmpty || _index == null) return;
      _load(_queue, _index!);
    });
  }

  Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
      return;
    }
    if (current == null) return;
    final state = _player.processingState;
    if (state == ProcessingState.loading ||
        state == ProcessingState.buffering) {
      return;
    }
    if (!_loaded) {
      await _load(_queue, _index ?? 0);
      return;
    }
    if (state == ProcessingState.completed) {
      await _player.seek(Duration.zero, index: _index ?? 0);
    }
    _start();
  }

  Future<void> next() async {
    final index = _index;
    if (index == null || index + 1 >= _queue.length) return;
    if (_loaded && _player.hasNext) {
      await _player.seekToNext();
      return;
    }
    await _load(_queue, index + 1);
  }

  Future<void> previous() async {
    final index = _index;
    if (index == null) return;
    if (_player.position > const Duration(seconds: 3) || index == 0) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_loaded && _player.hasPrevious) {
      await _player.seekToPrevious();
      return;
    }
    await _load(_queue, index - 1);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() async {
    _loadId++;
    await _player.stop();
    _queue = [];
    _index = null;
    _loaded = false;
    _retries = 0;
    _error = null;
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
    _loadId++;
    _queue = [];
    _index = null;
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
