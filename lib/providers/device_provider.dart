import 'package:flutter/foundation.dart';

import '../models/device_model.dart';
import '../models/relay_model.dart';

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

  // =========================
  // GETTERS
  // =========================

  Device? get device => _device;

  List<Relay> get relays => List.unmodifiable(_relays);

  bool get hasDevice => _device != null;

  bool get isOnline => _device?.isOnline ?? false;

  // =========================
  // DEVICE METHODS
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

  // =========================
  // RELAY METHODS
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

  // =========================
  // SYNC WITH ESP32
  // =========================

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

  // =========================
  // RENAME RELAY
  // =========================

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
  // CLEAR DEVICE
  // =========================

  void clearDevice() {
    _device = null;

    for (final relay in _relays) {
      relay.isOn = false;
    }

    notifyListeners();
  }
}