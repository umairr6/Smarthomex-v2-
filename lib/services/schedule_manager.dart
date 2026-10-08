import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/schedule_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Production Android schedule engine for SmartHomeX.
///
/// Android AlarmManager owns the actual execution, so schedules continue
/// working when the Schedules screen is closed or the app is in background.
class ScheduleManager {
  ScheduleManager._();

  static final ScheduleManager instance = ScheduleManager._();

  static const int _maxAlarmId = 0x7fffffff;
  static const String _lastExecutionPrefix = 'schedule_last_execution_';

  /// Retry a failed device command after this amount of time.
  static const Duration _retryDelay = Duration(minutes: 1);

  final StorageService _storage = StorageService();

  bool _initialized = false;
  bool _exactAlarmAvailable = false;

  bool get isInitialized => _initialized;

  bool get exactAlarmAvailable => _exactAlarmAvailable;

  Future<void> initialize() async {
    if (_initialized) {
      final wasAvailable = _exactAlarmAvailable;

      _exactAlarmAvailable = await _checkExactAlarmPermission();

      if (!wasAvailable && _exactAlarmAvailable) {
        await rescheduleAll();
      }

      return;
    }

    await AndroidAlarmManager.initialize();

    _initialized = true;

    _exactAlarmAvailable = await _checkExactAlarmPermission();

    if (_exactAlarmAvailable) {
      await rescheduleAll();
    }
  }

  Future<bool> _checkExactAlarmPermission() async {
    try {
      final status = await Permission.scheduleExactAlarm.status;

      return status.isGranted;
    } catch (_) {
      // Older Android versions do not require this permission.
      return true;
    }
  }

  /// Requests Android exact-alarm permission when required.
  Future<bool> requestExactAlarmPermission() async {
    try {
      var status = await Permission.scheduleExactAlarm.status;

      if (status.isGranted) {
        _exactAlarmAvailable = true;
        return true;
      }

      status = await Permission.scheduleExactAlarm.request();

      _exactAlarmAvailable = status.isGranted;

      return _exactAlarmAvailable;
    } catch (_) {
      _exactAlarmAvailable = true;
      return true;
    }
  }

  /// Creates or replaces the Android alarm for one schedule.
  Future<bool> scheduleOne(RelaySchedule schedule) async {
    await initialize();

    if (!schedule.enabled || schedule.weekdays.isEmpty) {
      await cancel(schedule);
      return true;
    }

    if (!_exactAlarmAvailable) {
      final granted = await requestExactAlarmPermission();

      if (!granted) {
        return false;
      }
    }

    await cancel(schedule);

    final next = _nextOccurrence(schedule, DateTime.now());

    return AndroidAlarmManager.oneShotAt(
      next,
      _alarmId(schedule.id),
      scheduleAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
      params: <String, dynamic>{'schedule_id': schedule.id},
    );
  }

  /// Restores all saved schedules into Android AlarmManager.
  Future<void> rescheduleAll() async {
    if (!_initialized) {
      await AndroidAlarmManager.initialize();

      _initialized = true;
    }

    _exactAlarmAvailable = await _checkExactAlarmPermission();

    if (!_exactAlarmAvailable) {
      return;
    }

    final schedules = await _storage.loadSchedules();

    for (final schedule in schedules) {
      if (!schedule.enabled || schedule.weekdays.isEmpty) {
        await cancel(schedule);
        continue;
      }

      await cancel(schedule);

      final next = _nextOccurrence(schedule, DateTime.now());

      await AndroidAlarmManager.oneShotAt(
        next,
        _alarmId(schedule.id),
        scheduleAlarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
        params: <String, dynamic>{'schedule_id': schedule.id},
      );
    }
  }

  Future<void> cancel(RelaySchedule schedule) async {
    if (!_initialized) {
      return;
    }

    await AndroidAlarmManager.cancel(_alarmId(schedule.id));
  }

  Future<void> delete(RelaySchedule schedule) async {
    await cancel(schedule);

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('$_lastExecutionPrefix${schedule.id}');
  }

  Future<void> syncSchedule(RelaySchedule schedule) async {
    if (schedule.enabled) {
      await scheduleOne(schedule);
    } else {
      await cancel(schedule);
    }
  }

  int _alarmId(String scheduleId) {
    return _stableAlarmId(scheduleId);
  }

  static int _stableAlarmId(String scheduleId) {
    var hash = 2166136261;

    for (final codeUnit in utf8.encode(scheduleId)) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0xffffffff;
    }

    return hash & _maxAlarmId;
  }

  DateTime _nextOccurrence(RelaySchedule schedule, DateTime from) {
    for (var offset = 0; offset <= 7; offset++) {
      final candidateDate = DateTime(
        from.year,
        from.month,
        from.day + offset,
        schedule.hour,
        schedule.minute,
      );

      if (!schedule.weekdays.contains(candidateDate.weekday)) {
        continue;
      }

      if (candidateDate.isAfter(from)) {
        return candidateDate;
      }
    }

    return DateTime(
      from.year,
      from.month,
      from.day + 7,
      schedule.hour,
      schedule.minute,
    );
  }

  static DateTime _nextOccurrenceStatic(RelaySchedule schedule, DateTime from) {
    for (var offset = 0; offset <= 7; offset++) {
      final candidateDate = DateTime(
        from.year,
        from.month,
        from.day + offset,
        schedule.hour,
        schedule.minute,
      );

      if (!schedule.weekdays.contains(candidateDate.weekday)) {
        continue;
      }

      if (candidateDate.isAfter(from)) {
        return candidateDate;
      }
    }

    return DateTime(
      from.year,
      from.month,
      from.day + 7,
      schedule.hour,
      schedule.minute,
    );
  }

  static Future<void> _scheduleNextFromBackground(
    RelaySchedule schedule,
  ) async {
    final next = _nextOccurrenceStatic(schedule, DateTime.now());

    await AndroidAlarmManager.oneShotAt(
      next,
      _stableAlarmId(schedule.id),
      scheduleAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
      params: <String, dynamic>{'schedule_id': schedule.id},
    );
  }

  /// Schedules a retry for a failed ESP32 command.
  ///
  /// The retry uses the same alarm ID, so it replaces the currently
  /// executing one-shot alarm. The weekly schedule will be armed again
  /// after the command succeeds.
  static Future<void> _scheduleRetry(RelaySchedule schedule) async {
    final retryAt = DateTime.now().add(_retryDelay);

    await AndroidAlarmManager.oneShotAt(
      retryAt,
      _stableAlarmId(schedule.id),
      scheduleAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
      params: <String, dynamic>{'schedule_id': schedule.id},
    );
  }

  static Future<bool> _alreadyExecuted(
    RelaySchedule schedule,
    DateTime now,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final key = '${now.year}-${now.month}-${now.day}-${now.hour}-${now.minute}';

    return prefs.getString('$_lastExecutionPrefix${schedule.id}') == key;
  }

  static Future<void> _markExecuted(
    RelaySchedule schedule,
    DateTime now,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final key = '${now.year}-${now.month}-${now.day}-${now.hour}-${now.minute}';

    await prefs.setString('$_lastExecutionPrefix${schedule.id}', key);
  }

  /// Entry point executed by Android AlarmManager's background isolate.
  @pragma('vm:entry-point')
  static Future<void> scheduleAlarmCallback(int alarmId) async {
    WidgetsFlutterBinding.ensureInitialized();

    final storage = StorageService();
    final api = ApiService();

    final schedules = await storage.loadSchedules();

    RelaySchedule? schedule;

    for (final item in schedules) {
      if (_stableAlarmId(item.id) == alarmId) {
        schedule = item;
        break;
      }
    }

    if (schedule == null) {
      return;
    }

    if (!schedule.enabled || schedule.weekdays.isEmpty) {
      return;
    }

    final now = DateTime.now();

    /*
     * If this is a retry alarm, the current day is still valid.
     *
     * If the alarm fires on a day that is not part of the schedule,
     * simply arm the next normal occurrence.
     */
    if (!schedule.weekdays.contains(now.weekday)) {
      await _scheduleNextFromBackground(schedule);
      return;
    }

    /*
     * Prevent duplicate execution during the same scheduled minute.
     */
    if (await _alreadyExecuted(schedule, now)) {
      await _scheduleNextFromBackground(schedule);
      return;
    }

    final device = await storage.loadDevice();

    /*
     * No device information is available.
     *
     * Keep trying instead of silently losing the schedule.
     */
    if (device == null) {
      await _scheduleRetry(schedule);
      return;
    }

    bool success = false;

    /*
     * First attempt.
     */
    for (var attempt = 0; attempt < 2; attempt++) {
      success = schedule.turnOn
          ? await api.turnRelayOn(device.ipAddress, schedule.relayId)
          : await api.turnRelayOff(device.ipAddress, schedule.relayId);

      if (success) {
        break;
      }

      /*
       * Give the ESP32/Wi-Fi a few seconds before the second attempt.
       */
      if (attempt == 0) {
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    }

    /*
     * Device command failed.
     *
     * DO NOT mark the schedule as executed.
     * Retry in one minute.
     */
    if (!success) {
      await _scheduleRetry(schedule);
      return;
    }

    /*
     * The device command succeeded.
     */
    await _markExecuted(schedule, now);

    /*
     * Re-arm the next weekly occurrence.
     */
    await _scheduleNextFromBackground(schedule);
  }
}
