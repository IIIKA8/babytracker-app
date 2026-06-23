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

  Stream<bool> get playingStream => player.playingStream;

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

  Future<void> stop() async {
    ++_op; // cancel any in-flight prepare/play
    try {
      await player.pause();
      await player.seek(Duration.zero);
    } catch (_) {}
  }

  void startTimer(Duration duration) {
    stopTimer();

    var remaining = duration;
    _timerController.add(remaining);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining -= const Duration(seconds: 1);

      if (remaining.inSeconds <= 0) {
        _timerController.add(Duration.zero);
        stopTimer();
        return;
      }

      _timerController.add(remaining);
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    stopTimer();
    await player.dispose();
    await _timerController.close();
  }
}
