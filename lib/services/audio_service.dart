import 'dart:async';

import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer player = AudioPlayer();

  final StreamController<Duration> _timerController =
      StreamController.broadcast();

  Stream<Duration> get timerStream => _timerController.stream;

  Timer? _timer;
  String? _loadedPath;
  bool _initialized = false;
  int _op = 0;
  Duration? _remaining;

  Stream<bool> get playingStream => player.playingStream;

  Duration? get remaining => _remaining;

  bool get isLoading {
    final state = player.processingState;
    return state == ProcessingState.loading ||
        state == ProcessingState.buffering;
  }

  Future<void> init() async {
    if (_initialized) return;
    await player.setLoopMode(LoopMode.one);
    _initialized = true;
  }

  Future<void> prepare(String path) async {
    await init();
    if (_loadedPath == path) return;

    final op = ++_op;
    await player.setAsset(path);
    if (op != _op) return;
    _loadedPath = path;
  }

  Future<void> play(String path) async {
    await init();

    final op = ++_op;
    if (_loadedPath != path) {
      await player.setAsset(path);
      if (op != _op) return;
      _loadedPath = path;
    }

    await player.seek(Duration.zero);
    if (op != _op) return;
    await player.play();
  }

  Future<void> pause() async {
    ++_op;
    try {
      await player.pause();
    } catch (_) {}
  }

  Future<void> stop() async {
    ++_op;
    try {
      await player.pause();
      await player.seek(Duration.zero);
    } catch (_) {}
  }

  void setTimerDuration(Duration? duration) {
    _remaining = duration == null ? null : duration;
    if (duration != null) {
      _emit();
    }
  }

  void startCountdown() {
    if (_remaining == null) return;
    _tick();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pauseCountdown() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (_remaining == null) return;

    if (_remaining!.inSeconds <= 0) {
      _remaining = Duration.zero;
      _emit();
      pauseCountdown();
      return;
    }

    _emit();
    _remaining = _remaining! - const Duration(seconds: 1);
  }

  void _emit() {
    if (_timerController.isClosed) return;
    _timerController.add(_remaining ?? Duration.zero);
  }

  void stopTimer() {
    pauseCountdown();
    _remaining = null;
  }

  Future<void> dispose() async {
    stopTimer();
    await player.dispose();
    await _timerController.close();
  }
}
