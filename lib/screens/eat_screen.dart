import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EatRecord {
  final String id;
  final String title;
  final DateTime time;
  final String childId;

  EatRecord({
    required this.id,
    required this.title,
    required this.time,
    required this.childId,
  });

  factory EatRecord.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['time'];

    if (timestamp == null) {
      throw Exception("Record without time");
    }

    return EatRecord(
      id: id,
      title: data['title'] ?? '',
      childId: data['childId'] ?? '',
      time: (timestamp as Timestamp).toDate(),
    );
  }
}

class EatScreen extends StatefulWidget {
  final String childId;

  const EatScreen({super.key, required this.childId});

  @override
  State<EatScreen> createState() => _EatScreenState();
}

class _EatScreenState extends State<EatScreen> {
  final user = FirebaseAuth.instance.currentUser;

  DateTime currentDate = DateTime.now();

  List<EatRecord> allRecords = [];
  List<EatRecord> filteredRecords = [];

  StreamSubscription? sub;

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
        .collection('eat_records')
        .snapshots()
        .listen((snapshot) {
      allRecords = snapshot.docs.map((doc) {
        try {
          return EatRecord.fromFirestore(doc.id, doc.data());
        } catch (_) {
          return null;
        }
      }).whereType<EatRecord>().toList();

      filterByDate();
    });
  }

  void filterByDate() {
    final selected = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    setState(() {
      filteredRecords = allRecords.where((r) {
        if (r.childId != widget.childId) return false;

        final recordDate = DateTime(
          r.time.year,
          r.time.month,
          r.time.day,
        );

        return recordDate == selected;
      }).toList();

      filteredRecords.sort((a, b) => b.time.compareTo(a.time));
    });
  }

  void changeDate(int delta) {
    setState(() {
      currentDate = currentDate.add(Duration(days: delta));
    });

    filterByDate();
  }

  Future<void> deleteRecord(EatRecord record) async {
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('eat_records')
        .doc(record.id)
        .delete();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd.MM.yyyy').format(currentDate);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: const Text("Питание"),
        backgroundColor: Colors.white.withOpacity(0.15),
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/img.png"),
            fit: BoxFit.cover,
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [

              SizedBox(height: screenHeight * 0.06),

              // ===== DATE + BUTTON =====
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                ),

                child: Row(
                  children: [

                    // ===== DATE =====
                    Expanded(
                      child: Row(
                        children: [

                          SizedBox(
                            width: 28,
                            height: 28,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(0xFFF8E1F3),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(15),
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

                          SizedBox(width: screenWidth * 0.025),

                          Flexible(
                            child: Text(
                              dateText,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: screenWidth * 0.042,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),

                          SizedBox(width: screenWidth * 0.025),

                          SizedBox(
                            width: 28,
                            height: 28,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(0xFFF8E1F3),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(15),
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
                    ),

                    SizedBox(width: screenWidth * 0.03),

                    // ===== ADD BUTTON =====
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFFF8E1F3),
                          foregroundColor:
                          const Color(0xFF4B4B4B),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: showAddDialog,
                        child: Text(
                          "Добавить",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.015),

              // ===== LIST =====
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                  ),

                  itemCount: filteredRecords.length,

                  itemBuilder: (context, index) {
                    final r = filteredRecords[index];

                    return GestureDetector(
                      onLongPress: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Удаление"),
                            content:
                            const Text("Удалить запись?"),
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

                      child: Container(
                        margin: EdgeInsets.only(
                          bottom: screenHeight * 0.01,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.93),

                          borderRadius:
                          BorderRadius.circular(18),

                          border: Border.all(
                            color: const Color(0xFFE3E3E3),
                          ),

                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),

                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.017,
                          ),

                          child: Row(
                            children: [

                              // ===== TEXT =====
                              Expanded(
                                child: Text(
                                  r.title,

                                  overflow: TextOverflow.ellipsis,

                                  style: TextStyle(
                                    fontSize:
                                    screenWidth * 0.04,
                                    fontWeight:
                                    FontWeight.normal,
                                    color: const Color(
                                        0xFF4B4B4B),
                                  ),
                                ),
                              ),

                              SizedBox(width: screenWidth * 0.03),

                              // ===== TIME =====
                              Text(
                                DateFormat('HH:mm')
                                    .format(r.time),

                                style: TextStyle(
                                  fontSize:
                                  screenWidth * 0.034,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  // ===== ADD =====

  void showAddDialog() {
    final controller = TextEditingController();

    TimeOfDay time = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          title: const Text("Добавить запись"),

          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Введите запись",
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Text("Время: "),

                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: time,
                          );

                          if (picked != null) {
                            setStateDialog(() => time = picked);
                          }
                        },

                        child: Text(time.format(context)),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          actions: [
            TextButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;

                final dateTime = DateTime(
                  currentDate.year,
                  currentDate.month,
                  currentDate.day,
                  time.hour,
                  time.minute,
                );

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('eat_records')
                    .add({
                  'title': controller.text.trim(),
                  'time': dateTime,
                  'childId': widget.childId,
                });

                Navigator.pop(context);
              },

              child: const Text("Сохранить"),
            ),
          ],
        );
      },
    );
  }
}