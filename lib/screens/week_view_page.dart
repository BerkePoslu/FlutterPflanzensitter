import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/soil_data.dart';

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
