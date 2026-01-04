import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../config.dart';
import '../models/soil_data.dart';

class MqttService {
  MqttServerClient? client;
  bool isConnected = false;

  Function(SoilData)? onDataReceived;
  Function(bool)? onConnectionChanged;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  bool _isDisposed = false;

  Future<void> connect() async {
    String clientId = 'flutter_${Random().nextInt(100000)}';

    client = MqttServerClient(MqttConfig.broker, clientId);
    client!.port = MqttConfig.port;
    client!.keepAlivePeriod = 60;
    client!.onDisconnected = _onDisconnected;
    client!.onConnected = _onConnected;

    final connMess =
        MqttConnectMessage().withClientIdentifier(clientId).startClean();
    client!.connectionMessage = connMess;

    try {
      debugPrint('Connecting to MQTT broker...');
      await client!.connect(MqttConfig.username, MqttConfig.password);
    } catch (e) {
      debugPrint('Exception: $e');
      client!.disconnect();
    }
  }

  void _onConnected() {
    debugPrint('Connected to MQTT broker');
    isConnected = true;
    _reconnectAttempts = 0; // Reset reconnect attempts on successful connection
    onConnectionChanged?.call(true);

    client!.subscribe(MqttConfig.topic, MqttQos.atLeastOnce);
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );

      try {
        final json = jsonDecode(pt);
        final newData = SoilData(
          raw: json['raw'] ?? 0,
          percent: json['percent'] ?? 0,
          state: json['state'] ?? 'unknown',
          timestamp: DateTime.now(),
        );

        onDataReceived?.call(newData);
      } catch (e) {
        debugPrint('Error parsing JSON: $e');
      }
    });
  }

  void _onDisconnected() {
    debugPrint('Disconnected from MQTT broker');
    isConnected = false;
    onConnectionChanged?.call(false);

    // Attempt automatic reconnection
    if (!_isDisposed && _reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached. Giving up.');
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    // Exponential backoff: 2s, 4s, 8s, 16s, 32s
    final delaySeconds = pow(2, _reconnectAttempts + 1).toInt();
    _reconnectAttempts++;

    debugPrint(
      'Scheduling reconnect attempt $_reconnectAttempts in $delaySeconds seconds...',
    );

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isDisposed) {
        debugPrint('Attempting reconnection...');
        connect();
      }
    });
  }

  void disconnect() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    client?.disconnect();
    isConnected = false;
  }
}
