/// M5Stack Earth Moisture Sensor Calibration
///
/// The sensor measures electrical conductivity between two probes.
/// Raw ADC values (0-4095 for 12-bit ADC) need to be converted to %.
///
/// IMPORTANT: These values are INVERTED for most soil moisture sensors:
/// - WET soil = MORE conductive = LOWER raw value
/// - DRY soil = LESS conductive = HIGHER raw value
library;

class SensorCalibration {
  /// Raw ADC value when sensor is in WATER (fully wet) - typically LOW
  final int wetValue;

  /// Raw ADC value when sensor is in AIR (completely dry) - typically HIGH
  final int dryValue;

  /// Name for this calibration profile
  final String name;

  const SensorCalibration({
    required this.wetValue,
    required this.dryValue,
    this.name = 'Default',
  });

  /// Convert raw sensor value to moisture percentage (0-100%)
  /// Handles both normal and inverted sensors
  int rawToPercent(int rawValue) {
    // Determine if sensor is inverted (wet < dry) or normal (wet > dry)
    if (wetValue < dryValue) {
      // Inverted: wet=low, dry=high (most common for soil sensors)
      // Map: wetValue -> 100%, dryValue -> 0%
      double percent = ((dryValue - rawValue) / (dryValue - wetValue)) * 100;
      return percent.clamp(0, 100).round();
    } else {
      // Normal: wet=high, dry=low
      // Map: wetValue -> 100%, dryValue -> 0%
      double percent = ((rawValue - dryValue) / (wetValue - dryValue)) * 100;
      return percent.clamp(0, 100).round();
    }
  }

  /// Convert moisture percentage back to approximate raw value
  int percentToRaw(int percent) {
    if (wetValue < dryValue) {
      // Inverted sensor
      return (dryValue - ((percent / 100) * (dryValue - wetValue))).round();
    } else {
      // Normal sensor
      return (dryValue + ((percent / 100) * (wetValue - dryValue))).round();
    }
  }

  /// Check if raw value indicates sensor might be disconnected or faulty
  bool isSensorError(int rawValue) {
    // If value is at absolute extremes, sensor might be disconnected
    return rawValue <= 10 || rawValue >= 4090;
  }

  /// Get a human-readable description of the calibration
  String get description {
    if (wetValue < dryValue) {
      return 'Wet=$wetValue (low), Dry=$dryValue (high) - Inverted';
    } else {
      return 'Wet=$wetValue (high), Dry=$dryValue (low) - Normal';
    }
  }

  Map<String, dynamic> toJson() {
    return {'wetValue': wetValue, 'dryValue': dryValue, 'name': name};
  }

  factory SensorCalibration.fromJson(Map<String, dynamic> json) {
    return SensorCalibration(
      wetValue: json['wetValue'] ?? defaultCalibration.wetValue,
      dryValue: json['dryValue'] ?? defaultCalibration.dryValue,
      name: json['name'] ?? 'Custom',
    );
  }

  /// Default calibration for M5Stack Earth Sensor
  /// Based on typical values - user should calibrate for their specific sensor/soil
  static const SensorCalibration defaultCalibration = SensorCalibration(
    wetValue: 1200, // Typical value in water
    dryValue: 3500, // Typical value in air
    name: 'M5Stack Default',
  );

  /// Preset calibrations for different soil types
  static const SensorCalibration sandySoil = SensorCalibration(
    wetValue: 1000,
    dryValue: 3200,
    name: 'Sandy Soil',
  );

  static const SensorCalibration loamySoil = SensorCalibration(
    wetValue: 1200,
    dryValue: 3400,
    name: 'Loamy Soil',
  );

  static const SensorCalibration claySoil = SensorCalibration(
    wetValue: 1400,
    dryValue: 3600,
    name: 'Clay Soil',
  );

  static const SensorCalibration pottingMix = SensorCalibration(
    wetValue: 1100,
    dryValue: 3300,
    name: 'Potting Mix',
  );

  /// All preset calibrations
  static const List<SensorCalibration> presets = [
    defaultCalibration,
    sandySoil,
    loamySoil,
    claySoil,
    pottingMix,
  ];
}
