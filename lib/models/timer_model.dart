class RelayTimer {
  final String id;
  final int relayId;
  final String relayName;
  final int durationSeconds;
  final DateTime endTime;

  RelayTimer({
    required this.id,
    required this.relayId,
    required this.relayName,
    required this.durationSeconds,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relayId': relayId,
      'relayName': relayName,
      'durationSeconds': durationSeconds,
      'endTime': endTime.toIso8601String(),
    };
  }

  factory RelayTimer.fromJson(Map<String, dynamic> json) {
    return RelayTimer(
      id: json['id'] as String,
      relayId: json['relayId'] as int,
      relayName: json['relayName'] as String,
      durationSeconds: json['durationSeconds'] as int,
      endTime: DateTime.parse(json['endTime'] as String),
    );
  }
}