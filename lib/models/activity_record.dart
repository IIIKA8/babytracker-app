import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityRecord {
  String id;
  String activityType;
  String? comment;
  DateTime time;
  DateTime date;

  ActivityRecord({
    required this.id,
    required this.activityType,
    this.comment,
    required this.time,
    required this.date,
  });

  factory ActivityRecord.fromFirestore(
      String id, Map<String, dynamic> data) {
    return ActivityRecord(
      id: id,
      activityType: data['activityType'] ?? '',
      comment: data['comment'],
      time: (data['time'] as Timestamp).toDate(),
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityType': activityType,
      'comment': comment,
      'time': time,
      'date': date,
    };
  }
}