import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Monitor 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HomePage(),
    );
  }
}

class SoilData {
  final int raw;
  final int percent;
  final String state;
  final DateTime timestamp;

  SoilData({
    required this.raw,
    required this.percent,
    required this.state,
    required this.timestamp,
  });

  factory SoilData.fromJson(Map<String, dynamic> json) {
    return SoilData(
      raw: json['raw'] ?? 0,
      percent: json['percent'] ?? 0,
      state: json['state'] ?? 'unknown',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raw': raw,
      'percent': percent,
      'state': state,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MqttServerClient? client;
  final String _topic = 'BBW/SoilMoisture';
  
  SoilData? _currentData;
  bool _isConnected = false;
  List<SoilData> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _connect();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? historyJson = prefs.getStringList('soil_history');
    
    if (historyJson != null && historyJson.isNotEmpty) {
      setState(() {
        _history = historyJson
            .map((item) => SoilData.fromJson(jsonDecode(item)))
            .toList();
        // Sort by timestamp
        _history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        // Set current data to the latest if available
        if (_history.isNotEmpty) {
          _currentData = _history.last;
        }
      });
    } else {
      // Only generate mock data if history is completely empty
      _generateMockHistory();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep only last 7 days of data or max 100 points to avoid bloating
    if (_history.length > 100) {
      _history = _history.sublist(_history.length - 100);
    }
    
    final List<String> historyJson = _history
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    
    await prefs.setStringList('soil_history', historyJson);
  }

  void _generateMockHistory() {
    final now = DateTime.now();
    final random = Random();
    List<SoilData> mockData = [];
    for (int i = 6; i >= 0; i--) {
      mockData.add(SoilData(
        raw: 2000 + random.nextInt(500),
        percent: 40 + random.nextInt(40),
        state: 'ok',
        timestamp: now.subtract(Duration(days: i)),
      ));
    }
    setState(() {
      _history = mockData;
      if (_history.isNotEmpty) {
        _currentData = _history.last;
      }
    });
  }

  Future<void> _connect() async {
    // Use a random client ID to avoid collisions
    String clientIdentifier = 'flutter_plant_${Random().nextInt(100000)}';
    
    // Simple MQTT connection matching ESP32 configuration
    client = MqttServerClient('public.cloud.shiftr.io', clientIdentifier);
    client!.port = 1883;
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
      await client!.connect('public', 'public');
    } catch (e) {
      debugPrint('Exception: $e');
      client!.disconnect();
    }
  }

  void _onConnected() {
    debugPrint('Connected to MQTT broker');
    setState(() {
      _isConnected = true;
    });
    client!.subscribe(_topic, MqttQos.atLeastOnce);
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      
      try {
        final json = jsonDecode(pt);
        // Ensure we create a new object with current timestamp
        final newData = SoilData(
          raw: json['raw'] ?? 0,
          percent: json['percent'] ?? 0,
          state: json['state'] ?? 'unknown',
          timestamp: DateTime.now(),
        );
        
        setState(() {
          _currentData = newData;
          _history.add(newData);
        });
        
        // Save to cache
        _saveHistory();
        
      } catch (e) {
        debugPrint('Error parsing JSON: $e');
      }
    });
  }

  void _onDisconnected() {
    debugPrint('Disconnected from MQTT broker');
    setState(() {
      _isConnected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Background Gradient
    return Scaffold(
      body: Stack(
        children: [
          // Nature/Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A2980), // Deep Blue
                  Color(0xFF26D0CE), // Light Blue/Green
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildLiquidIndicator(),
                        const SizedBox(height: 40),
                        _buildInfoCards(),
                        const SizedBox(height: 40),
                        _buildWeekViewButton(context),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Plant',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isConnected ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isConnected ? CupertinoIcons.wifi : CupertinoIcons.wifi_slash,
                  color: _isConnected ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _isConnected ? 'Online' : 'Offline',
                  style: GoogleFonts.poppins(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidIndicator() {
    double percent = _currentData?.percent.toDouble() ?? 0.0;
    // Clamp percent between 0 and 100
    percent = percent.clamp(0, 100);
    
    return SizedBox(
      height: 250,
      width: 250,
      child: LiquidCircularProgressIndicator(
        value: percent / 100,
        valueColor: AlwaysStoppedAnimation(Colors.cyanAccent.withValues(alpha: 0.6)),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        borderColor: Colors.white.withValues(alpha: 0.5),
        borderWidth: 2.0,
        direction: Axis.vertical,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${percent.toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            Text(
              'Moisture',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildGlassCard(
              title: 'Raw Value',
              value: _currentData?.raw.toString() ?? '--',
              icon: CupertinoIcons.waveform_path_ecg,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildGlassCard(
              title: 'Status',
              value: _currentData?.state.toUpperCase() ?? '--',
              icon: CupertinoIcons.heart_fill,
              color: (_currentData?.state == 'ok') ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 120,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
          stops: const [0.1, 1],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0.1), // Light border
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekViewButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => WeekViewPage(history: _history)),
        );
      },
      child: GlassmorphicContainer(
        width: 200,
        height: 60,
        borderRadius: 30,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderGradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.1)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View History',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class WeekViewPage extends StatelessWidget {
  final List<SoilData> history;

  const WeekViewPage({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Nature Background (Greenery theme for this page)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF134E5E), // Dark Green
                  Color(0xFF71B280), // Light Green
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Weekly Insights',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: GlassmorphicContainer(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 30,
                      blur: 30,
                      alignment: Alignment.center,
                      border: 2,
                      linearGradient: LinearGradient(
                        colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderGradient: LinearGradient(
                        colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.1)],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Moisture Levels',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Expanded(
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          int index = value.toInt();
                                          if (index >= 0 && index < history.length) {
                                            // Show date for every 5th item or if list is short
                                            if (history.length > 10 && index % (history.length ~/ 5) != 0) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                DateFormat('E').format(history[index].timestamp),
                                                style: const TextStyle(color: Colors.white60, fontSize: 10),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                        interval: 1,
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  minX: 0,
                                  maxX: (history.length - 1).toDouble(),
                                  minY: 0,
                                  maxY: 100,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: history.asMap().entries.map((e) {
                                        return FlSpot(e.key.toDouble(), e.value.percent.toDouble());
                                      }).toList(),
                                      isCurved: true,
                                      color: Colors.white,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.white.withValues(alpha: 0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
