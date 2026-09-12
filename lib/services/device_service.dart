import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class DeviceService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ==========================================
  // CHECK ESP32
  // ==========================================

  Future<Map<String, dynamic>> getDeviceInfo(
    String ipAddress,
  ) async {
    final ip = ipAddress.trim();

    if (ip.isEmpty) {
      throw Exception('Enter the ESP32 IP address.');
    }

    final response = await http
        .get(
          Uri.parse(
            'http://$ip/info',
          ),
        )
        .timeout(
          const Duration(seconds: 5),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'ESP32 returned an error.',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map) {
      throw Exception(
        'Invalid response from ESP32.',
      );
    }

    final result =
        Map<String, dynamic>.from(data);

    if (result['device_uid'] == null) {
      throw Exception(
        'This device does not have a SmartHomeX Device UID.',
      );
    }

    return result;
  }

  // ==========================================
  // PAIR DEVICE
  // ==========================================

  Future<Map<String, dynamic>> pairDevice({
    required String roomId,
    required String ipAddress,
    required String deviceUid,
    required String name,
    required int relayCount,
  }) async {
    // Check whether this device is already paired.
    final existing = await _supabase
        .from('devices')
        .select('id, room_id')
        .eq(
          'device_uid',
          deviceUid,
        )
        .maybeSingle();

    if (existing != null) {
      throw Exception(
        'This ESP32 is already paired with SmartHomeX.',
      );
    }

    // Create device.
    final deviceResponse =
        await _supabase
            .from('devices')
            .insert({
              'room_id': roomId,
              'device_uid': deviceUid,
              'name': name.trim().isEmpty
                  ? 'ESP32'
                  : name.trim(),
              'ip_address': ipAddress.trim(),
              'is_online': true,
              'relay_count': relayCount,
            })
            .select()
            .single();

    final device =
        Map<String, dynamic>.from(
      deviceResponse,
    );

    final deviceId =
        device['id'] as String;

    // ========================================
    // Create relays
    // ========================================

    final relayRows =
        <Map<String, dynamic>>[];

    final defaultNames = [
      'Light 1',
      'Light 2',
      'Fan',
      'Socket',
    ];

    final defaultIcons = [
      'light',
      'light',
      'fan',
      'socket',
    ];

    for (int i = 1;
        i <= relayCount;
        i++) {
      relayRows.add({
        'device_id': deviceId,
        'relay_number': i,
        'name': i <= defaultNames.length
            ? defaultNames[i - 1]
            : 'Switch $i',
        'icon': i <= defaultIcons.length
            ? defaultIcons[i - 1]
            : 'light',
        'is_on': false,
      });
    }

    if (relayRows.isNotEmpty) {
      await _supabase
          .from('relays')
          .insert(relayRows);
    }

    return device;
  }

  // ==========================================
  // ROOM DEVICES
  // ==========================================

  Future<List<Map<String, dynamic>>>
      getRoomDevices(
    String roomId,
  ) async {
    final response = await _supabase
        .from('devices')
        .select()
        .eq(
          'room_id',
          roomId,
        )
        .order('created_at');

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  // ==========================================
  // DEVICE RELAYS
  // ==========================================

  Future<List<Map<String, dynamic>>>
      getDeviceRelays(
    String deviceId,
  ) async {
    final response = await _supabase
        .from('relays')
        .select()
        .eq(
          'device_id',
          deviceId,
        )
        .order('relay_number');

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  // ==========================================
  // DELETE DEVICE
  // ==========================================

  Future<void> deleteDevice(
    String deviceId,
  ) async {
    await _supabase
        .from('devices')
        .delete()
        .eq(
          'id',
          deviceId,
        );
  }
}