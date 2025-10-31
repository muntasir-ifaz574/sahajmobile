class UnionModel {
  final String id;
  final String name;

  UnionModel({required this.id, required this.name});

  factory UnionModel.fromJson(Map<String, dynamic> json) {
    return UnionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
