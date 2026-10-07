import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  static const String broker =
      'b8022b1a.ala.asia-southeast1.emqxsl.com';

  static const int port = 8883;

  static const String username = 'smarthomex_esp32';

  static const String password = 'umlain@1420';

  MqttServerClient? _client;

  String? _deviceUid;

  bool _listening = false;

  // =====================================================
  // DEVICE LIVE STATUS
  // =====================================================

  Timer? _deviceOfflineTimer;

  // If the ESP32 stops sending state/availability messages,
  // consider it offline after this period.
  static const Duration _deviceOfflineTimeout =
      Duration(seconds: 45);

  void Function(Map<String, dynamic> state)? _stateListener;

  bool get isConnected {
    return _client?.connectionStatus?.state ==
        MqttConnectionState.connected;
  }

  String? get deviceUid => _deviceUid;

  String? get commandTopic {
    if (_deviceUid == null) return null;

    return 'smarthomex/device/$_deviceUid/command';
  }

  String? get stateTopic {
    if (_deviceUid == null) return null;

    return 'smarthomex/device/$_deviceUid/state';
  }

  String? get availabilityTopic {
    if (_deviceUid == null) return null;

    return 'smarthomex/device/$_deviceUid/availability';
  }

  // =====================================================
  // STATE LISTENER
  // =====================================================

  void setStateListener(
    void Function(Map<String, dynamic> state)? listener,
  ) {
    _stateListener = listener;
  }

  // =====================================================
  // CONNECT
  // =====================================================

  Future<bool> connect(String deviceUid) async {
    _deviceUid = deviceUid.trim();

    if (_deviceUid == null || _deviceUid!.isEmpty) {
      debugPrint('MQTT: Device UID is empty.');
      return false;
    }

    if (isConnected) {
      debugPrint('MQTT: Already connected.');
      _subscribeToDevice();
      return true;
    }

    if (_client != null) {
      try {
        _client!.disconnect();
      } catch (_) {}
    }

    final clientId =
        'smarthomex_app_${DateTime.now().millisecondsSinceEpoch}';

    final client = MqttServerClient.withPort(
      broker,
      clientId,
      port,
    );

    _client = client;

    // ===================================================
    // MQTT SETTINGS
    // ===================================================

    client.secure = true;
    client.useWebSocket = false;
    client.keepAlivePeriod = 30;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;
    client.connectTimeoutPeriod = 10000;
    client.logging(on: false);

    // ===================================================
    // LOAD CA CERTIFICATE
    // ===================================================

    try {
      final certificateData = await rootBundle.load(
        'assets/certificates/emqxsl-ca.crt',
      );

      final certificateBytes =
          certificateData.buffer.asUint8List(
        certificateData.offsetInBytes,
        certificateData.lengthInBytes,
      );

      final securityContext =
          SecurityContext(withTrustedRoots: true);

      securityContext.setTrustedCertificatesBytes(
        Uint8List.fromList(certificateBytes),
      );

      client.securityContext = securityContext;

      debugPrint(
        'MQTT: EMQX CA certificate loaded.',
      );
    } catch (e) {
      debugPrint(
        'MQTT: Failed to load CA certificate: $e',
      );

      return false;
    }

    // ===================================================
    // CONNECTION MESSAGE
    // ===================================================

    final connectMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(
          username,
          password,
        )
        .startClean()
        .withWillQos(
          MqttQos.atMostOnce,
        );

    client.connectionMessage = connectMessage;

    // ===================================================
    // CALLBACKS
    // ===================================================

    client.onConnected = _onConnected;

    client.onDisconnected = _onDisconnected;

    client.onAutoReconnect = _onAutoReconnect;

    client.onAutoReconnected = _onAutoReconnected;

    // ===================================================
    // CONNECT
    // ===================================================

    try {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('SmartHomeX MQTT');
      debugPrint('Connecting to EMQX...');
      debugPrint('Broker: $broker');
      debugPrint('Port: $port');
      debugPrint('Device: $_deviceUid');
      debugPrint('========================================');

      final status = await client.connect();

      if (status?.state !=
          MqttConnectionState.connected) {
        debugPrint('');
        debugPrint('MQTT CONNECTION FAILED');
        debugPrint(
          'State: ${status?.state}',
        );
        debugPrint(
          'Return code: ${status?.returnCode}',
        );

        try {
          client.disconnect();
        } catch (_) {}

        return false;
      }

      debugPrint('');
      debugPrint('========================================');
      debugPrint('MQTT CONNECTED!');
      debugPrint('Client ID: $clientId');
      debugPrint('========================================');

      _subscribeToDevice();

      return true;
    } catch (e) {
      debugPrint('');
      debugPrint(
        'MQTT CONNECTION EXCEPTION: $e',
      );

      try {
        client.disconnect();
      } catch (_) {}

      return false;
    }
  }

  // =====================================================
  // CONNECTED
  // =====================================================

  void _onConnected() {
    debugPrint(
      'SmartHomeX MQTT onConnected callback',
    );

    _subscribeToDevice();
  }

  // =====================================================
  // DISCONNECTED
  // =====================================================

  void _onDisconnected() {
    debugPrint(
      'SmartHomeX MQTT disconnected',
    );
  }

  // =====================================================
  // AUTO RECONNECT
  // =====================================================

  void _onAutoReconnect() {
    debugPrint(
      'SmartHomeX MQTT reconnecting...',
    );
  }

  void _onAutoReconnected() {
    debugPrint(
      'SmartHomeX MQTT reconnected!',
    );

    _subscribeToDevice();
  }

  // =====================================================
  // SUBSCRIBE
  // =====================================================

  void _subscribeToDevice() {
    final client = _client;
    final topic = stateTopic;

    if (client == null) return;

    if (!isConnected) {
      debugPrint(
        'MQTT: Not connected, cannot subscribe.',
      );
      return;
    }

    if (topic == null) return;

    debugPrint('');
    debugPrint(
      'MQTT subscribing to:',
    );
    debugPrint(topic);

    client.subscribe(
      topic,
      MqttQos.atMostOnce,
    );

    // Subscribe to the ESP32 availability/LWT topic too.
    final availability = availabilityTopic;

    if (availability != null) {
      debugPrint('MQTT subscribing to availability:');
      debugPrint(availability);

      client.subscribe(
        availability,
        MqttQos.atMostOnce,
      );
    }

    // Only attach one listener to the MQTT update stream.
    if (!_listening) {
      _listening = true;

      client.updates?.listen(
        _handleMessages,
      );
    }
  }

  // =====================================================
  // RECEIVE STATE
  // =====================================================

  void _handleMessages(
    List<MqttReceivedMessage<MqttMessage>> messages,
  ) {
    for (final message in messages) {
      final receivedTopic =
          message.topic;

      final mqttMessage =
          message.payload as MqttPublishMessage;

      final payload =
          MqttPublishPayload.bytesToStringAsString(
        mqttMessage.payload.message,
      );

      debugPrint('');
      debugPrint('========================================');
      debugPrint('MQTT MESSAGE RECEIVED');
      debugPrint('Topic: $receivedTopic');
      debugPrint('Payload: $payload');
      debugPrint('========================================');

      // =====================================================
      // ESP32 AVAILABILITY
      // =====================================================

      if (receivedTopic == availabilityTopic) {
        final availability = payload.trim().toLowerCase();

        if (availability == 'online' ||
            availability == '1' ||
            availability == 'true') {
          _markDeviceAlive();
        } else if (availability == 'offline' ||
            availability == '0' ||
            availability == 'false') {
          _markDeviceOffline();
        }

        continue;
      }

      // =====================================================
      // ESP32 STATE
      // =====================================================

      if (receivedTopic != stateTopic) {
        continue;
      }

      try {
        final decoded = jsonDecode(payload);

        if (decoded is Map) {
          final state =
              Map<String, dynamic>.from(decoded);

          // A valid state message proves the ESP32 is alive.
          _markDeviceAlive();

          _stateListener?.call(state);
        }
      } catch (e) {
        debugPrint(
          'MQTT: Invalid state JSON: $e',
        );
      }
    }
  }

  // =====================================================
  // DEVICE LIVE STATUS
  // =====================================================

  void _markDeviceAlive() {
    _deviceOfflineTimer?.cancel();

    // Send a status event to the RoomControlScreen.
    _stateListener?.call({
      'device_uid': _deviceUid,
      '_availability': 'online',
    });

    _deviceOfflineTimer = Timer(
      _deviceOfflineTimeout,
      _markDeviceOffline,
    );
  }

  void _markDeviceOffline() {
    _deviceOfflineTimer?.cancel();

    _stateListener?.call({
      'device_uid': _deviceUid,
      '_availability': 'offline',
    });
  }

  // =====================================================
  // RELAY COMMAND
  // =====================================================

  bool setRelay(
    int relayNumber,
    bool turnOn,
  ) {
    final client = _client;
    final topic = commandTopic;

    if (client == null) {
      debugPrint(
        'MQTT: Client is null.',
      );
      return false;
    }

    if (topic == null) {
      debugPrint(
        'MQTT: Command topic is null.',
      );
      return false;
    }

    if (!isConnected) {
      debugPrint(
        'MQTT: Not connected.',
      );
      return false;
    }

    if (relayNumber < 1 ||
        relayNumber > 4) {
      debugPrint(
        'MQTT: Invalid relay number: $relayNumber',
      );
      return false;
    }

    final command =
        'relay$relayNumber:${turnOn ? 'on' : 'off'}';

    final builder =
        MqttClientPayloadBuilder();

    builder.addString(command);

    client.publishMessage(
      topic,
      MqttQos.atMostOnce,
      builder.payload!,
    );

    debugPrint('');
    debugPrint('========================================');
    debugPrint('MQTT COMMAND SENT');
    debugPrint('Topic: $topic');
    debugPrint('Command: $command');
    debugPrint('========================================');

    return true;
  }

  // =====================================================
  // DISCONNECT
  // =====================================================

  void disconnect() {
    _deviceOfflineTimer?.cancel();
    _deviceOfflineTimer = null;

    // Tell the screen immediately that this MQTT session
    // is no longer connected to the device.
    _stateListener?.call({
      'device_uid': _deviceUid,
      '_availability': 'offline',
    });

    try {
      _client?.disconnect();
    } catch (_) {}

    _client = null;
    _listening = false;
    _stateListener = null;
  }
}