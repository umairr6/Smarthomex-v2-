import 'dart:convert';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/timer_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class TimerManager {
  TimerManager._();

  static final TimerManager instance = TimerManager._();

  static const int _maxAlarmId = 0x7fffffff;
  static const String _lastExecutionPrefix = 'timer_last_execution_';

  final StorageService _storage = StorageService();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    await AndroidAlarmManager.initialize();
    _initialized = true;
  }

  Future<bool> scheduleOne(RelayTimer timer) async {
    await initialize();

    await cancel(timer);

    if (!timer.endTime.isAfter(DateTime.now())) {
      return false;
    }

    return AndroidAlarmManager.oneShotAt(
      timer.endTime,
      _alarmId(timer.id),
      timerAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
      params: <String, dynamic>{'timer_id': timer.id},
    );
  }

  Future<void> cancel(RelayTimer timer) async {
    if (!_initialized) {
      await initialize();
    }

    await AndroidAlarmManager.cancel(_alarmId(timer.id));
  }

  Future<void> delete(RelayTimer timer) async {
    await cancel(timer);

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('$_lastExecutionPrefix${timer.id}');
  }

  Future<void> rescheduleAll() async {
    await initialize();

    final timers = await _storage.loadTimers();
    final now = DateTime.now();

    for (final timer in timers) {
      if (!timer.endTime.isAfter(now)) {
        continue;
      }

      await scheduleOne(timer);
    }
  }

  int _alarmId(String timerId) {
    return _stableAlarmId(timerId);
  }

  static int _stableAlarmId(String timerId) {
    var hash = 2166136261;

    for (final codeUnit in utf8.encode(timerId)) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0xffffffff;
    }

    return hash & _maxAlarmId;
  }

  static Future<bool> _alreadyExecuted(RelayTimer timer) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('$_lastExecutionPrefix${timer.id}') ==
        timer.endTime.toIso8601String();
  }

  static Future<void> _markExecuted(RelayTimer timer) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      '$_lastExecutionPrefix${timer.id}',
      timer.endTime.toIso8601String(),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> timerAlarmCallback(int alarmId) async {
    WidgetsFlutterBinding.ensureInitialized();

    final storage = StorageService();
    final api = ApiService();

    final timers = await storage.loadTimers();

    RelayTimer? timer;

    for (final item in timers) {
      if (_stableAlarmId(item.id) == alarmId) {
        timer = item;
        break;
      }
    }

    if (timer == null) {
      return;
    }

    if (await _alreadyExecuted(timer)) {
      return;
    }

    final now = DateTime.now();

    // The alarm fired slightly early.
    // Schedule it again for the actual expiration time.
    if (timer.endTime.isAfter(now)) {
      await AndroidAlarmManager.oneShotAt(
        timer.endTime,
        _stableAlarmId(timer.id),
        timerAlarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
        params: <String, dynamic>{'timer_id': timer.id},
      );

      return;
    }

    final device = await storage.loadDevice();

    if (device == null) {
      // Keep the timer instead of silently losing it.
      await _retryTimer(timer);
      return;
    }

    bool success = false;

    for (var attempt = 0; attempt < 2; attempt++) {
      success = await api.turnRelayOff(device.ipAddress, timer.relayId);

      if (success) {
        break;
      }

      if (attempt == 0) {
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    }

    if (!success) {
      // ESP32 was unavailable.
      // Keep the timer and retry later.
      await _retryTimer(timer);
      return;
    }

    // Only mark the timer complete after the relay
    // was successfully turned OFF.
    await _markExecuted(timer);

    final remaining = await storage.loadTimers();

    remaining.removeWhere((item) => item.id == timer!.id);

    await storage.saveTimers(remaining);
  }

  static Future<void> _retryTimer(RelayTimer timer) async {
    // Retry after 1 minute if the ESP32 was temporarily
    // unavailable when the timer expired.
    final retryAt = DateTime.now().add(const Duration(minutes: 1));

    await AndroidAlarmManager.oneShotAt(
      retryAt,
      _stableAlarmId(timer.id),
      timerAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
      params: <String, dynamic>{'timer_id': timer.id},
    );
  }
}
