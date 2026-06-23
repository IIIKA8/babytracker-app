import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sleep_timer_visibility.dart';

class SleepTimerService with WidgetsBindingObserver {
  SleepTimerService._();

  static final SleepTimerService instance = SleepTimerService._();

  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  Stream<Duration> get durationStream => _durationController.stream;

  Timer? _uiTimer;
  String? _childId;
  DateTime? _startTime;
  bool _running = false;
  bool _initialized = false;

  bool get isRunning => _running;
  String? get childId => _childId;
  DateTime? get startTime => _startTime;

  bool isRunningFor(String childId) => _running && _childId == childId;

  Duration get currentDuration {
    if (!_running || _startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);
    registerSleepVisibilityCallback(_emit);

    final prefs = await SharedPreferences.getInstance();
    final running = prefs.getBool('sleep_running') ?? false;
    final childId = prefs.getString('sleep_child_id');
    final startMs = prefs.getInt('sleep_start_ms');

    if (running && childId != null && startMs != null) {
      _running = true;
      _childId = childId;
      _startTime = DateTime.fromMillisecondsSinceEpoch(startMs);
      _startUiUpdates();
    }
  }

  Future<void> start(String childId) async {
    await ensureInitialized();
    if (_running) return;

    _childId = childId;
    _startTime = DateTime.now();
    _running = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sleep_running', true);
    await prefs.setString('sleep_child_id', childId);
    await prefs.setInt('sleep_start_ms', _startTime!.millisecondsSinceEpoch);

    _startUiUpdates();
    _emit();
  }

  /// Returns [startTime] if a session was active.
  Future<DateTime?> stop() async {
    if (!_running || _startTime == null) return null;

    final started = _startTime!;
    _running = false;
    _uiTimer?.cancel();
    _childId = null;
    _startTime = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sleep_running');
    await prefs.remove('sleep_child_id');
    await prefs.remove('sleep_start_ms');

    _emit();
    return started;
  }

  void _startUiUpdates() {
    _uiTimer?.cancel();
    _emit();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) => _emit());
  }

  void _emit() {
    if (_durationController.isClosed) return;
    _durationController.add(currentDuration);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _emit();
    }
  }
}
