import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

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
      print('MQTT: Device UID is empty.');
      return false;
    }

    if (isConnected) {
      print('MQTT: Already connected.');
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

      print(
        'MQTT: EMQX CA certificate loaded.',
      );
    } catch (e) {
      print(
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
      print('');
      print('========================================');
      print('SmartHomeX MQTT');
      print('Connecting to EMQX...');
      print('Broker: $broker');
      print('Port: $port');
      print('Device: $_deviceUid');
      print('========================================');

      final status = await client.connect();

      if (status?.state !=
          MqttConnectionState.connected) {
        print('');
        print('MQTT CONNECTION FAILED');
        print(
          'State: ${status?.state}',
        );
        print(
          'Return code: ${status?.returnCode}',
        );

        try {
          client.disconnect();
        } catch (_) {}

        return false;
      }

      print('');
      print('========================================');
      print('MQTT CONNECTED!');
      print('Client ID: $clientId');
      print('========================================');

      _subscribeToDevice();

      return true;
    } catch (e) {
      print('');
      print(
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
    print(
      'SmartHomeX MQTT onConnected callback',
    );

    _subscribeToDevice();
  }

  // =====================================================
  // DISCONNECTED
  // =====================================================

  void _onDisconnected() {
    print(
      'SmartHomeX MQTT disconnected',
    );
  }

  // =====================================================
  // AUTO RECONNECT
  // =====================================================

  void _onAutoReconnect() {
    print(
      'SmartHomeX MQTT reconnecting...',
    );
  }

  void _onAutoReconnected() {
    print(
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
      print(
        'MQTT: Not connected, cannot subscribe.',
      );
      return;
    }

    if (topic == null) return;

    print('');
    print(
      'MQTT subscribing to:',
    );
    print(topic);

    client.subscribe(
      topic,
      MqttQos.atMostOnce,
    );

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

      print('');
      print('========================================');
      print('MQTT MESSAGE RECEIVED');
      print('Topic: $receivedTopic');
      print('Payload: $payload');
      print('========================================');

      if (receivedTopic != stateTopic) {
        continue;
      }

      try {
        final decoded = jsonDecode(payload);

        if (decoded is Map) {
          final state =
              Map<String, dynamic>.from(decoded);

          _stateListener?.call(state);
        }
      } catch (e) {
        print(
          'MQTT: Invalid state JSON: $e',
        );
      }
    }
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
      print(
        'MQTT: Client is null.',
      );
      return false;
    }

    if (topic == null) {
      print(
        'MQTT: Command topic is null.',
      );
      return false;
    }

    if (!isConnected) {
      print(
        'MQTT: Not connected.',
      );
      return false;
    }

    if (relayNumber < 1 ||
        relayNumber > 4) {
      print(
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

    print('');
    print('========================================');
    print('MQTT COMMAND SENT');
    print('Topic: $topic');
    print('Command: $command');
    print('========================================');

    return true;
  }

  // =====================================================
  // DISCONNECT
  // =====================================================

  void disconnect() {
    try {
      _client?.disconnect();
    } catch (_) {}

    _client = null;
    _listening = false;
    _stateListener = null;
  }
}