class Thana {
  final String id;
  final String name;

  Thana({required this.id, required this.name});

  factory Thana.fromJson(Map<String, dynamic> json) {
    return Thana(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
