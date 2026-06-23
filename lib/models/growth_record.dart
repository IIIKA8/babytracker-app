import 'package:cloud_firestore/cloud_firestore.dart';

class GrowthRecord {
  final String id;
  final DateTime date;
  final double weight;
  final double height;
  final int ageMonths;
  final bool isBoy;

  GrowthRecord({
    required this.id,
    required this.date,
    required this.weight,
    required this.height,
    required this.ageMonths,
    required this.isBoy,
  });

  factory GrowthRecord.fromDoc(String id, Map<String, dynamic> data) {
    final rawDate = data['date'];

    DateTime date;

    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      date = DateTime.parse(rawDate);
    } else {
      date = DateTime.now();
    }

    return GrowthRecord(
      id: id,
      date: date,
      weight: (data['weight'] ?? 0).toDouble(),
      height: (data['height'] ?? 0).toDouble(),
      ageMonths: (data['ageMonths'] ?? 0).toInt(),
      isBoy: data['isBoy'] ?? true,
    );
  }
}