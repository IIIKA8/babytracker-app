import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'sleep_timer_visibility.dart';

class AudioService {
  final AudioPlayer player = AudioPlayer();

  final StreamController<Duration> _timerController =
      StreamController.broadcast();

  Stream<Duration> get timerStream => _timerController.stream;

  String? _loadedPath;
  bool _initialized = false;
  int _op = 0;

  Duration? _remaining;
  DateTime? _endsAt;
  int _countdownGen = 0;
  bool _visibilityHooked = false;

  Stream<bool> get playingStream => player.playingStream;

  Duration? get remaining => _remaining;

  bool get isCountdownActive => _endsAt != null;

  bool get isLoading {
    final state = player.processingState;
    return state == ProcessingState.loading ||
        state == ProcessingState.buffering;
  }

  Future<void> init() async {
    if (_initialized) return;
    await player.setLoopMode(LoopMode.one);
    _initialized = true;
    _hookVisibility();
  }

  void _hookVisibility() {
    if (_visibilityHooked) return;
    _visibilityHooked = true;
    registerSleepVisibilityCallback(_syncFromClock);
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
    pauseCountdown();
    _remaining = duration;
    if (duration != null) {
      _emit();
    }
  }

  void startCountdown() {
    if (_remaining == null || _remaining!.inSeconds <= 0) return;

    _endsAt = DateTime.now().add(_remaining!);
    final gen = ++_countdownGen;
    _syncFromClock();
    _runCountdownLoop(gen);
  }

  Future<void> _runCountdownLoop(int gen) async {
    while (gen == _countdownGen && _endsAt != null) {
      await Future.delayed(const Duration(seconds: 1));
      if (gen != _countdownGen || _endsAt == null) return;

      _syncFromClock();

      if (_remaining != null && _remaining!.inSeconds <= 0) {
        pauseCountdown();
        return;
      }
    }
  }

  void pauseCountdown() {
    _countdownGen++;
    if (_endsAt != null) {
      _syncFromClock();
      _endsAt = null;
      _emit();
    }
  }

  void _syncFromClock() {
    if (_endsAt == null) return;
    final left = _endsAt!.difference(DateTime.now());
    _remaining = left.isNegative ? Duration.zero : left;
    _emit();
  }

  void _emit() {
    if (_timerController.isClosed) return;
    _timerController.add(_remaining ?? Duration.zero);
  }

  void stopTimer() {
    pauseCountdown();
    _remaining = null;
    _emit();
  }

  Future<void> dispose() async {
    stopTimer();
    await player.dispose();
    await _timerController.close();
  }
}
