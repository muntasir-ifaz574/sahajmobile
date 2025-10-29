class Division {
  final String id;
  final String name;

  Division({required this.id, required this.name});

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
