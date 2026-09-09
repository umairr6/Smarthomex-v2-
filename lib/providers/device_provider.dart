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

  // -------------------------
  // Getters
  // -------------------------

  Device? get device => _device;

  List<Relay> get relays => List.unmodifiable(_relays);

  bool get hasDevice => _device != null;

  bool get isOnline => _device?.isOnline ?? false;

  // -------------------------
  // Device
  // -------------------------

  void setDevice(Device device) {
    _device = device;
    notifyListeners();
  }

  void updateDeviceStatus(bool online) {
    if (_device == null) return;

    _device!.isOnline = online;
    notifyListeners();
  }

  // -------------------------
  // Relay
  // -------------------------

  Relay? getRelay(int relayId) {
    try {
      return _relays.firstWhere(
        (relay) => relay.id == relayId,
      );
    } catch (_) {
      return null;
    }
  }

  void updateRelayState(int relayId, bool isOn) {
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

  // -------------------------
  // Rename Relay
  // -------------------------

  void renameRelay(int relayId, String newName) {
    final relay = getRelay(relayId);

    if (relay == null) return;

    relay.name = newName;
    notifyListeners();
  }

  // -------------------------
  // Reset
  // -------------------------

  void clearDevice() {
    _device = null;

    for (final relay in _relays) {
      relay.isOn = false;
    }

    notifyListeners();
  }
}