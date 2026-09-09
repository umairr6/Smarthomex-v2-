class Device {
  final String id;
  String name;
  String ipAddress;
  bool isOnline;
  int relayCount;

  Device({
    required this.id,
    required this.name,
    required this.ipAddress,
    this.isOnline = false,
    this.relayCount = 4,
  });

  /// Convert Device to JSON for local storage/API use
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'isOnline': isOnline,
      'relayCount': relayCount,
    };
  }

  /// Create Device from JSON
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      ipAddress: json['ipAddress'] as String,
      isOnline: json['isOnline'] as bool? ?? false,
      relayCount: json['relayCount'] as int? ?? 4,
    );
  }

  /// Create a copy with selected changes
  Device copyWith({
    String? id,
    String? name,
    String? ipAddress,
    bool? isOnline,
    int? relayCount,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      isOnline: isOnline ?? this.isOnline,
      relayCount: relayCount ?? this.relayCount,
    );
  }
}