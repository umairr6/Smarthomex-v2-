import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_model.dart';
import '../models/relay_model.dart';
import '../models/schedule_model.dart';
import '../models/timer_model.dart';

class StorageService {
  static const String _deviceKey = 'saved_device';
  static const String _relaysKey = 'saved_relays';
  static const String _timersKey = 'saved_timers';
  static const String _schedulesKey = 'saved_schedules';

  // =========================
  // DEVICE
  // =========================

  Future<void> saveDevice(Device device) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _deviceKey,
      jsonEncode(device.toJson()),
    );
  }

  Future<Device?> loadDevice() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString(_deviceKey);

    if (jsonString == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(jsonString);

      if (decoded is Map<String, dynamic>) {
        return Device.fromJson(decoded);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDevice() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_deviceKey);
  }

  // =========================
  // RELAYS
  // =========================

  Future<void> saveRelays(
    List<Relay> relays,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final relayData = relays
        .map((relay) => relay.toJson())
        .toList();

    await prefs.setString(
      _relaysKey,
      jsonEncode(relayData),
    );
  }

  Future<List<Relay>?> loadRelays() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString(_relaysKey);

    if (jsonString == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        return null;
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(
            (json) => Relay.fromJson(json),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearRelays() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_relaysKey);
  }

  // =========================
  // TIMERS
  // =========================

  Future<void> saveTimers(
    List<RelayTimer> timers,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final timerData = timers
        .map((timer) => timer.toJson())
        .toList();

    await prefs.setString(
      _timersKey,
      jsonEncode(timerData),
    );
  }

  Future<List<RelayTimer>> loadTimers() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString(_timersKey);

    if (jsonString == null) {
      return [];
    }

    try {
      final decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(
            (json) => RelayTimer.fromJson(json),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearTimers() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_timersKey);
  }

  // =========================
  // SCHEDULES
  // =========================

  Future<void> saveSchedules(
    List<RelaySchedule> schedules,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final scheduleData = schedules
        .map((schedule) => schedule.toJson())
        .toList();

    await prefs.setString(
      _schedulesKey,
      jsonEncode(scheduleData),
    );
  }

  Future<List<RelaySchedule>> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString(_schedulesKey);

    if (jsonString == null) {
      return [];
    }

    try {
      final decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(
            (json) => RelaySchedule.fromJson(json),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearSchedules() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_schedulesKey);
  }
}