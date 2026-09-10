class RelaySchedule {
  final String id;
  final int relayId;
  final String relayName;
  final int hour;
  final int minute;
  final List<int> weekdays;
  final bool turnOn;
  bool enabled;

  RelaySchedule({
    required this.id,
    required this.relayId,
    required this.relayName,
    required this.hour,
    required this.minute,
    required this.weekdays,
    required this.turnOn,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relayId': relayId,
      'relayName': relayName,
      'hour': hour,
      'minute': minute,
      'weekdays': weekdays,
      'turnOn': turnOn,
      'enabled': enabled,
    };
  }

  factory RelaySchedule.fromJson(
    Map<String, dynamic> json,
  ) {
    return RelaySchedule(
      id: json['id'] as String,
      relayId: json['relayId'] as int,
      relayName: json['relayName'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      weekdays: List<int>.from(
        json['weekdays'] ?? [],
      ),
      turnOn: json['turnOn'] as bool? ?? true,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  RelaySchedule copyWith({
    String? id,
    int? relayId,
    String? relayName,
    int? hour,
    int? minute,
    List<int>? weekdays,
    bool? turnOn,
    bool? enabled,
  }) {
    return RelaySchedule(
      id: id ?? this.id,
      relayId: relayId ?? this.relayId,
      relayName: relayName ?? this.relayName,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      turnOn: turnOn ?? this.turnOn,
      enabled: enabled ?? this.enabled,
    );
  }
}