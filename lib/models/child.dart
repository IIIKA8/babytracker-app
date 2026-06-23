class Child {
  final String id;
  final String name;

  Child({required this.id, required this.name});

  factory Child.fromFirestore(String id, Map<String, dynamic> data) {
    return Child(
      id: id,
      name: data['name'] ?? '',
    );
  }
}