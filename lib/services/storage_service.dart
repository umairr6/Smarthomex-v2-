import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_model.dart';

class StorageService {
  static const String _deviceKey = 'saved_device';

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
}