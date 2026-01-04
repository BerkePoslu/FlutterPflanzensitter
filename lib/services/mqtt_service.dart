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

  Future<void> connect() async {
    // Use a random client ID to avoid collisions
    String clientIdentifier = 'flutter_plant_${Random().nextInt(100000)}';
    
    // MQTT connection using secure config
    client = MqttServerClient(MqttConfig.broker, clientIdentifier);
    client!.port = MqttConfig.port;
    client!.logging(on: false);
    client!.keepAlivePeriod = 20;
    client!.onDisconnected = _onDisconnected;
    client!.onConnected = _onConnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
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
    onConnectionChanged?.call(true);
    
    client!.subscribe(MqttConfig.topic, MqttQos.atLeastOnce);
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      
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
  }

  void disconnect() {
    client?.disconnect();
  }
}
