import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/soil_data.dart';
import '../services/mqtt_service.dart';
import 'week_view_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MqttService _mqttService = MqttService();
  
  SoilData? _currentData;
  bool _isConnected = false;
  List<SoilData> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _setupMqttCallbacks();
    _mqttService.connect();
  }

  void _setupMqttCallbacks() {
    _mqttService.onDataReceived = (data) {
      setState(() {
        _currentData = data;
        _history.add(data);
      });
      _saveHistory();
    };

    _mqttService.onConnectionChanged = (connected) {
      setState(() {
        _isConnected = connected;
      });
    };
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
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
          Colors.white.withValues(alpha: 0.1),
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
