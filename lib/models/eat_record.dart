import 'package:cloud_firestore/cloud_firestore.dart';

class EatRecord {
  final String id;
  final String title;
  final DateTime time;
  final DateTime date; // 🔥 ДОБАВИЛИ
  final String childId;

  EatRecord({
    required this.id,
    required this.title,
    required this.time,
    required this.date, // 🔥
    required this.childId,
  });

  factory EatRecord.fromFirestore(String id, Map<String, dynamic> data) {
    return EatRecord(
      id: id,
      title: data['title'] ?? '',
      childId: data['childId'] ?? '',
      time: (data['time'] as Timestamp).toDate(),
      date: (data['date'] as Timestamp).toDate(), // 🔥
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'time': time,
      'date': date, // 🔥
      'childId': childId,
    };
  }
}