import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SleepRecord {
  final String id;
  final DateTime startTime;
  final DateTime endTime;

  SleepRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
  });

  factory SleepRecord.fromFirestore(String id, Map<String, dynamic> data) {
    return SleepRecord(
      id: id,
      startTime: DateTime.fromMillisecondsSinceEpoch(data['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(data['endTime']),
    );
  }

  String get duration {
    final d = endTime.difference(startTime);
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  String get timeRange {
    return "${DateFormat('HH:mm').format(startTime)} - "
        "${DateFormat('HH:mm').format(endTime)}";
  }
}