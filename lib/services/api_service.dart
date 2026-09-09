import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const Duration timeout = Duration(seconds: 5);

  /// Build the base URL for the ESP32.
  String _baseUrl(String ipAddress) {
    return 'http://$ipAddress';
  }

  /// Check whether the ESP32 is reachable.
  Future<bool> checkConnection(String ipAddress) async {
    try {
      final response = await http
          .get(
            Uri.parse('${_baseUrl(ipAddress)}/status'),
          )
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get the current status of all relays.
  Future<Map<String, dynamic>?> getStatus(String ipAddress) async {
    try {
      final response = await http
          .get(
            Uri.parse('${_baseUrl(ipAddress)}/status'),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Turn a relay ON.
  Future<bool> turnRelayOn(
    String ipAddress,
    int relayId,
  ) async {
    return _setRelay(
      ipAddress: ipAddress,
      relayId: relayId,
      state: 'on',
    );
  }

  /// Turn a relay OFF.
  Future<bool> turnRelayOff(
    String ipAddress,
    int relayId,
  ) async {
    return _setRelay(
      ipAddress: ipAddress,
      relayId: relayId,
      state: 'off',
    );
  }

  /// Send relay command to ESP32.
  Future<bool> _setRelay({
    required String ipAddress,
    required int relayId,
    required String state,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${_baseUrl(ipAddress)}/relay$relayId/$state',
            ),
          )
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}