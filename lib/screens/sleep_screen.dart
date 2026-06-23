import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/sleep_record.dart';

class SleepScreen extends StatefulWidget {
  final String childId;

  const SleepScreen({super.key, required this.childId});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  final user = FirebaseAuth.instance.currentUser;

  DateTime currentDate = DateTime.now();

  List<SleepRecord> allRecords = [];
  List<SleepRecord> filteredRecords = [];

  StreamSubscription? sub;

  Timer? timer;
  DateTime? startTime;
  Duration currentDuration = Duration.zero;
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    listenRecords();
  }

  void listenRecords() {
    if (user == null) return;

    sub?.cancel();

    sub = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('children')
        .doc(widget.childId)
        .collection('sleep')
        .snapshots()
        .listen((snapshot) {
      allRecords = snapshot.docs.map((doc) {
        return SleepRecord.fromFirestore(doc.id, doc.data());
      }).toList();

      filterByDate();
    });
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void filterByDate() {
    setState(() {
      filteredRecords = allRecords
          .where((r) => isSameDay(r.startTime, currentDate))
          .toList();

      filteredRecords.sort((a, b) => b.startTime.compareTo(a.startTime));
    });
  }

  void changeDate(int delta) {
    setState(() {
      currentDate = currentDate.add(Duration(days: delta));
    });
    filterByDate();
  }

  void startTimer() {
    if (isRunning) return;

    startTime = DateTime.now();
    isRunning = true;

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        currentDuration = DateTime.now().difference(startTime!);
      });
    });
  }

  Future<void> stopTimer() async {
    if (!isRunning || startTime == null) return;

    timer?.cancel();

    final end = DateTime.now();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('children')
        .doc(widget.childId)
        .collection('sleep')
        .add({
      'startTime': startTime!.millisecondsSinceEpoch,
      'endTime': end.millisecondsSinceEpoch,
      'date': currentDate.toIso8601String(),
    });

    setState(() {
      isRunning = false;
      startTime = null;
      currentDuration = Duration.zero;
    });

    filterByDate();
  }

  String formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  Widget card(SleepRecord r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // 👈 уменьшили расстояние
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E3E3)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              r.timeRange,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF4B4B4B),
              ),
            ),
          ),
          Text(
            r.duration,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd.MM.yyyy').format(currentDate);

    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: const Text("Сон"),
        backgroundColor: Colors.white.withOpacity(0.15),
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
      ),

      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/img.png"),
            fit: BoxFit.cover,
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [

              const SizedBox(height: 18),

              // ===== TIMER (уменьшен обратно) =====
              Container(
                margin: const EdgeInsets.only(bottom: 22),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFCADFF4),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  formatDuration(currentDuration),
                  style: const TextStyle(
                    fontSize: 16, // 👈 НОРМ РАЗМЕР
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B4B4B),
                  ),
                ),
              ),

              // ===== DATE + BUTTON =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 30,
                          height: 26,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCADFF4),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () => changeDate(-1),
                            child: const Icon(
                              Icons.chevron_left,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        Text(
                          dateText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 16),

                        SizedBox(
                          width: 30,
                          height: 26,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCADFF4),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () => changeDate(1),
                            child: const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCADFF4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        if (!isRunning) {
                          startTimer();
                        } else {
                          stopTimer();
                        }
                      },
                      child: Text(isRunning ? "Стоп" : "Добавить"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ===== LIST =====
              // ===== LIST =====
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredRecords.length,

                  itemBuilder: (context, index) {
                    final r = filteredRecords[index];

                    return GestureDetector(

                      onLongPress: () async {

                        final confirm = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Удаление"),
                            content: const Text("Удалить запись?"),

                            actions: [

                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text("Нет"),
                              ),

                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text("Да"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await deleteRecord(r);
                        }
                      },

                      child: card(r),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> deleteRecord(SleepRecord record) async {
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('children')
        .doc(widget.childId)
        .collection('sleep')
        .doc(record.id)
        .delete();
  }

  @override
  void dispose() {
    timer?.cancel();
    sub?.cancel();
    super.dispose();
  }
}