class Relay {
  final int id;
  String name;
  bool isOn;
  String icon;

  Relay({
    required this.id,
    required this.name,
    this.isOn = false,
    this.icon = 'light',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isOn': isOn,
      'icon': icon,
    };
  }

  factory Relay.fromJson(Map<String, dynamic> json) {
    return Relay(
      id: json['id'] as int,
      name: json['name'] as String,
      isOn: json['isOn'] as bool? ?? false,
      icon: json['icon'] as String? ?? 'light',
    );
  }

  Relay copyWith({
    int? id,
    String? name,
    bool? isOn,
    String? icon,
  }) {
    return Relay(
      id: id ?? this.id,
      name: name ?? this.name,
      isOn: isOn ?? this.isOn,
      icon: icon ?? this.icon,
    );
  }
}