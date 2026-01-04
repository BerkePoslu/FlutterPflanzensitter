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
