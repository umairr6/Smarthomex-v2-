import 'package:flutter/foundation.dart';

import '../models/device_model.dart';
import '../models/relay_model.dart';
import '../models/schedule_model.dart';
import '../models/timer_model.dart';

class DeviceProvider extends ChangeNotifier {
  Device? _device;

  final List<Relay> _relays = [
    Relay(
      id: 1,
      name: 'Light 1',
      icon: 'light',
    ),
    Relay(
      id: 2,
      name: 'Light 2',
      icon: 'light',
    ),
    Relay(
      id: 3,
      name: 'Fan',
      icon: 'fan',
    ),
    Relay(
      id: 4,
      name: 'Socket',
      icon: 'socket',
    ),
  ];

  final List<RelayTimer> _timers = [];

  final List<RelaySchedule> _schedules = [];

  // =========================
  // GETTERS
  // =========================

  Device? get device => _device;

  List<Relay> get relays =>
      List.unmodifiable(_relays);

  List<RelayTimer> get timers =>
      List.unmodifiable(_timers);

  List<RelaySchedule> get schedules =>
      List.unmodifiable(_schedules);

  bool get hasDevice => _device != null;

  bool get isOnline =>
      _device?.isOnline ?? false;

  // =========================
  // DEVICE
  // =========================

  void setDevice(Device device) {
    _device = device;
    notifyListeners();
  }

  void updateDeviceStatus(bool online) {
    if (_device == null) return;

    _device!.isOnline = online;

    notifyListeners();
  }

  void clearDevice() {
    _device = null;

    for (final relay in _relays) {
      relay.isOn = false;
    }

    _timers.clear();
    _schedules.clear();

    notifyListeners();
  }

  // =========================
  // RELAYS
  // =========================

  Relay? getRelay(int relayId) {
    try {
      return _relays.firstWhere(
        (relay) => relay.id == relayId,
      );
    } catch (_) {
      return null;
    }
  }

  void updateRelayState(
    int relayId,
    bool isOn,
  ) {
    final relay = getRelay(relayId);

    if (relay == null) return;

    relay.isOn = isOn;

    notifyListeners();
  }

  void toggleRelayLocally(int relayId) {
    final relay = getRelay(relayId);

    if (relay == null) return;

    relay.isOn = !relay.isOn;

    notifyListeners();
  }

  void syncRelayStates(
    Map<String, dynamic> status,
  ) {
    for (int i = 1; i <= 4; i++) {
      final relay = getRelay(i);

      if (relay == null) continue;

      final value = status['relay$i'];

      if (value is bool) {
        relay.isOn = value;
      }
    }

    notifyListeners();
  }

  void loadSavedRelays(
    List<Relay> savedRelays,
  ) {
    for (final savedRelay in savedRelays) {
      final relay = getRelay(savedRelay.id);

      if (relay == null) continue;

      relay.name = savedRelay.name;
      relay.icon = savedRelay.icon;
    }

    notifyListeners();
  }

  void renameRelay(
    int relayId,
    String newName,
  ) {
    final relay = getRelay(relayId);

    if (relay == null) return;

    relay.name = newName;

    notifyListeners();
  }

  // =========================
  // TIMERS
  // =========================

  void loadSavedTimers(
    List<RelayTimer> savedTimers,
  ) {
    _timers.clear();

    final now = DateTime.now();

    for (final timer in savedTimers) {
      if (timer.endTime.isAfter(now)) {
        _timers.add(timer);
      }
    }

    notifyListeners();
  }

  void addTimer(
    RelayTimer timer,
  ) {
    _timers.add(timer);

    notifyListeners();
  }

  void removeTimer(
    String timerId,
  ) {
    _timers.removeWhere(
      (timer) => timer.id == timerId,
    );

    notifyListeners();
  }

  RelayTimer? getTimer(
    String timerId,
  ) {
    try {
      return _timers.firstWhere(
        (timer) => timer.id == timerId,
      );
    } catch (_) {
      return null;
    }
  }

  void removeExpiredTimers() {
    final now = DateTime.now();

    _timers.removeWhere(
      (timer) => !timer.endTime.isAfter(now),
    );

    notifyListeners();
  }

  // =========================
  // SCHEDULES
  // =========================

  void loadSavedSchedules(
    List<RelaySchedule> savedSchedules,
  ) {
    _schedules
      ..clear()
      ..addAll(savedSchedules);

    notifyListeners();
  }

  void addSchedule(
    RelaySchedule schedule,
  ) {
    _schedules.add(schedule);

    notifyListeners();
  }

  void removeSchedule(
    String scheduleId,
  ) {
    _schedules.removeWhere(
      (schedule) => schedule.id == scheduleId,
    );

    notifyListeners();
  }

  void toggleSchedule(
    String scheduleId,
    bool enabled,
  ) {
    final index = _schedules.indexWhere(
      (schedule) => schedule.id == scheduleId,
    );

    if (index == -1) return;

    _schedules[index].enabled = enabled;

    notifyListeners();
  }

  RelaySchedule? getSchedule(
    String scheduleId,
  ) {
    try {
      return _schedules.firstWhere(
        (schedule) => schedule.id == scheduleId,
      );
    } catch (_) {
      return null;
    }
  }
}