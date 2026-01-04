import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/soil_data.dart';
import '../models/plant_thresholds.dart';
import '../models/sensor_calibration.dart';
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

  // Plant selection
  PlantThreshold _selectedPlant = PlantDatabase.defaultPlant;

  // Sensor calibration - calculate % from raw values
  SensorCalibration _calibration = SensorCalibration.defaultCalibration;

  /// Get the calculated moisture percentage from raw sensor value
  int get _calculatedPercent {
    if (_currentData == null) return 0;
    return _calibration.rawToPercent(_currentData!.raw);
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadSelectedPlant();
    _loadCalibration();
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
        _history =
            historyJson
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

    final List<String> historyJson =
        _history.map((item) => jsonEncode(item.toJson())).toList();

    await prefs.setStringList('soil_history', historyJson);
  }

  void _generateMockHistory() {
    final now = DateTime.now();
    final random = Random();
    List<SoilData> mockData = [];
    for (int i = 6; i >= 0; i--) {
      mockData.add(
        SoilData(
          raw: 2000 + random.nextInt(500),
          percent: 40 + random.nextInt(40),
          state: 'ok',
          timestamp: now.subtract(Duration(days: i)),
        ),
      );
    }
    setState(() {
      _history = mockData;
      if (_history.isNotEmpty) {
        _currentData = _history.last;
      }
    });
  }

  Future<void> _loadSelectedPlant() async {
    final prefs = await SharedPreferences.getInstance();
    final plantName = prefs.getString('selected_plant') ?? 'Generic Plant';
    setState(() {
      _selectedPlant = PlantDatabase.plants.firstWhere(
        (p) => p.name == plantName,
        orElse: () => PlantDatabase.defaultPlant,
      );
    });
  }

  Future<void> _saveSelectedPlant() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_plant', _selectedPlant.name);
  }

  Future<void> _loadCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    final calibrationJson = prefs.getString('sensor_calibration');
    if (calibrationJson != null) {
      setState(() {
        _calibration = SensorCalibration.fromJson(jsonDecode(calibrationJson));
      });
    }
  }

  Future<void> _saveCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'sensor_calibration',
      jsonEncode(_calibration.toJson()),
    );
  }

  void _showCalibrationSettings() {
    int wetValue = _calibration.wetValue;
    int dryValue = _calibration.dryValue;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder:
                  (context, setModalState) => Container(
                    height: MediaQuery.of(context).size.height * 0.75,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A2980),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sensor Calibration',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.pop(context),
                                child: const Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Current raw value display
                        if (_currentData != null)
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.waveform,
                                  color: Colors.cyanAccent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Current Raw: ${_currentData!.raw}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Preset selector
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Presets:',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children:
                                      SensorCalibration.presets.map((preset) {
                                        final isSelected =
                                            preset.name == _calibration.name;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              setModalState(() {
                                                wetValue = preset.wetValue;
                                                dryValue = preset.dryValue;
                                              });
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isSelected
                                                        ? Colors.cyanAccent
                                                            .withValues(
                                                              alpha: 0.3,
                                                            )
                                                        : Colors.white
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color:
                                                      isSelected
                                                          ? Colors.cyanAccent
                                                          : Colors.white24,
                                                ),
                                              ),
                                              child: Text(
                                                preset.name,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Manual calibration sliders
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                // Wet value
                                Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.drop_fill,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Wet (in water):',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$wetValue',
                                      style: GoogleFonts.poppins(
                                        color: Colors.cyanAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                CupertinoSlider(
                                  value: wetValue.toDouble(),
                                  min: 0,
                                  max: 4095,
                                  activeColor: Colors.blue,
                                  onChanged:
                                      (v) => setModalState(
                                        () => wetValue = v.round(),
                                      ),
                                ),
                                const SizedBox(height: 16),

                                // Dry value
                                Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.sun_max_fill,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Dry (in air):',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$dryValue',
                                      style: GoogleFonts.poppins(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                CupertinoSlider(
                                  value: dryValue.toDouble(),
                                  min: 0,
                                  max: 4095,
                                  activeColor: Colors.orange,
                                  onChanged:
                                      (v) => setModalState(
                                        () => dryValue = v.round(),
                                      ),
                                ),

                                const SizedBox(height: 24),

                                // Preview calculation
                                if (_currentData != null)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.greenAccent.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Preview with current raw (${_currentData!.raw}):',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${SensorCalibration(wetValue: wetValue, dryValue: dryValue).rawToPercent(_currentData!.raw)}%',
                                          style: GoogleFonts.poppins(
                                            color: Colors.greenAccent,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Save button
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              color: Colors.greenAccent,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: () {
                                setState(() {
                                  _calibration = SensorCalibration(
                                    wetValue: wetValue,
                                    dryValue: dryValue,
                                    name: 'Custom',
                                  );
                                });
                                _saveCalibration();
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Save Calibration',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
    );
  }

  IconData _getStatusIcon(PlantWaterStatus status) {
    switch (status) {
      case PlantWaterStatus.tooWet:
        return CupertinoIcons.drop_fill;
      case PlantWaterStatus.optimal:
        return CupertinoIcons.checkmark_seal_fill;
      case PlantWaterStatus.needsWaterSoon:
        return CupertinoIcons.clock_fill;
      case PlantWaterStatus.needsWaterNow:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case PlantWaterStatus.stressed:
        return CupertinoIcons.flame_fill;
    }
  }

  void _showPlantSelector() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Material(
            color: Colors.transparent,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Color(0xFF1A2980),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Your Plant',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: PlantDatabase.sortedByName.length,
                      itemBuilder: (context, index) {
                        final plant = PlantDatabase.sortedByName[index];
                        final isSelected = plant.name == _selectedPlant.name;
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(
                                plant.getStatus(50).colorValue,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${plant.waterNeededThreshold}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            plant.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            plant.nameDE,
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          trailing:
                              isSelected
                                  ? const Icon(
                                    CupertinoIcons.checkmark_circle_fill,
                                    color: Colors.greenAccent,
                                  )
                                  : Text(
                                    'p=${plant.depletionFraction}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                          onTap: () {
                            setState(() {
                              _selectedPlant = plant;
                            });
                            _saveSelectedPlant();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
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
          Expanded(
            child: GestureDetector(
              onTap: _showPlantSelector,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _selectedPlant.name,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                  Text(
                    'Tap to change plant • Water at ${_selectedPlant.waterNeededThreshold}%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  _isConnected
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isConnected ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isConnected
                      ? CupertinoIcons.wifi
                      : CupertinoIcons.wifi_slash,
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
    // Use calculated percent from raw value with calibration
    double percent = _calculatedPercent.toDouble();
    // Clamp percent between 0 and 100
    percent = percent.clamp(0, 100);

    // Get FAO-based status for the selected plant
    final status = _selectedPlant.getStatus(percent.toInt());
    final statusColor = Color(status.colorValue);

    return SizedBox(
      height: 250,
      width: 250,
      child: LiquidCircularProgressIndicator(
        value: percent / 100,
        valueColor: AlwaysStoppedAnimation(statusColor.withValues(alpha: 0.7)),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        borderColor: statusColor.withValues(alpha: 0.8),
        borderWidth: 3.0,
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
              status.label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    final percent = _calculatedPercent;
    final status = _selectedPlant.getStatus(percent);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Raw value and calibration row
          Row(
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
                child: GestureDetector(
                  onTap: _showCalibrationSettings,
                  child: _buildGlassCard(
                    title: 'Calibration ⚙️',
                    value: '${_calibration.wetValue}-${_calibration.dryValue}',
                    icon: CupertinoIcons.slider_horizontal_3,
                    color: Colors.purpleAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Threshold row
          Row(
            children: [
              Expanded(
                child: _buildGlassCard(
                  title: 'Water at (FAO)',
                  value: '${_selectedPlant.waterNeededThreshold}%',
                  icon: CupertinoIcons.drop,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildGlassCard(
                  title: 'Depletion (p)',
                  value: 'p = ${_selectedPlant.depletionFraction}',
                  icon: CupertinoIcons.leaf_arrow_circlepath,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Watering advice card
          _buildAdviceCard(status),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(PlantWaterStatus status) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 100,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(status.colorValue).withValues(alpha: 0.2),
          Color(status.colorValue).withValues(alpha: 0.1),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(status.colorValue).withValues(alpha: 0.8),
          Color(status.colorValue).withValues(alpha: 0.3),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(_getStatusIcon(status), color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    status.label,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _selectedPlant.wateringAdvice,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
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
          CupertinoPageRoute(
            builder: (context) => WeekViewPage(history: _history),
          ),
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
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.1),
          ],
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
            const Icon(
              CupertinoIcons.arrow_right,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
