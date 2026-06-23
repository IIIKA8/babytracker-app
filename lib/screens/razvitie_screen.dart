import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:babytracker/models/growth_record.dart';

class RazvitieScreen extends StatefulWidget {
  final String childId;

  const RazvitieScreen({super.key, required this.childId});

  @override
  State<RazvitieScreen> createState() => _RazvitieScreenState();
}

class _RazvitieScreenState extends State<RazvitieScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final dateFormat = DateFormat('dd.MM.yyyy');

  bool? isBoy;

  List<GrowthRecord> records = [];
  DateTime? birthDate;

  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    listenRecords();
    loadBirthDate();
  }

  // ================= DATA =================

  void listenRecords() {
    if (user == null) return;

    sub?.cancel();

    sub = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('children')
        .doc(widget.childId)
        .collection('growthRecords')
        .snapshots()
        .listen((snapshot) {
      final list = snapshot.docs.map((doc) {
        return GrowthRecord.fromDoc(doc.id, doc.data());
      }).toList();

      list.sort((a, b) => a.date.compareTo(b.date));

      setState(() => records = list);
    });
  }

  Future<void> loadBirthDate() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('children')
        .doc(widget.childId)
        .get();

    final data = doc.data();

    if (data != null) {
      if (data['birthDate'] != null) {
        birthDate = DateTime.parse(data['birthDate']);
      }

      isBoy = data['isBoy'];

      setState(() {});
    }
  }

  // ================= WHO =================

  Map<String, double>? getWHO(int age, bool isBoy) {
    if (age <= 3) {
      return {
        'weight': isBoy ? 5.7 : 5.2,
        'height': isBoy ? 60 : 58,
      };
    }

    if (age <= 6) {
      return {
        'weight': isBoy ? 7.8 : 7.2,
        'height': isBoy ? 67 : 65,
      };
    }

    if (age <= 9) {
      return {
        'weight': isBoy ? 9.2 : 8.6,
        'height': isBoy ? 72 : 70,
      };
    }

    if (age <= 12) {
      return {
        'weight': isBoy ? 10.2 : 9.5,
        'height': isBoy ? 76 : 74,
      };
    }

    if (age <= 18) {
      return {
        'weight': isBoy ? 11.5 : 10.8,
        'height': isBoy ? 82 : 80.5,
      };
    }

    if (age <= 24) {
      return {
        'weight': isBoy ? 12.7 : 12.1,
        'height': isBoy ? 87.5 : 86,
      };
    }

    return null;
  }

  String compare(double actual, double std, String name) {
    final diff = ((actual - std) / std) * 100;

    if (diff.abs() < 5) return "$name норма";

    if (diff > 0) {
      return "$name выше на ${diff.abs().toStringAsFixed(1)}%";
    }

    return "$name ниже на ${diff.abs().toStringAsFixed(1)}%";
  }

  // ================= AGE =================

  int calculateAgeMonths(DateTime birth, DateTime current) {
    int months =
        (current.year - birth.year) * 12 +
            (current.month - birth.month);

    if (current.day < birth.day) {
      months--;
    }

    return months < 0 ? 0 : months;
  }

  // ================= CARD =================

  Widget card(
      String text,
      double fontSize,
      double padding,
      double radius,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: padding * 0.7),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.93),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE3E3E3)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: const Color(0xFF4B4B4B),
        ),
      ),
    );
  }

  // ================= ADD =================

  Future<void> showAddDialog() async {
    final weight = TextEditingController();
    final height = TextEditingController();

    DateTime selected = DateTime.now();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Добавить запись"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: selected,
                    );

                    if (picked != null) {
                      setStateDialog(() => selected = picked);
                    }
                  },
                  child: Text(dateFormat.format(selected)),
                ),
                TextField(
                  controller: weight,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Вес"),
                ),
                TextField(
                  controller: height,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Рост"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Отмена"),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('children')
                      .doc(widget.childId)
                      .collection('growthRecords')
                      .add({
                    'date': Timestamp.fromDate(selected),
                    'weight': double.parse(weight.text),
                    'height': double.parse(height.text),
                    'isBoy': isBoy ?? true,
                    'ageMonths': birthDate == null
                        ? 0
                        : calculateAgeMonths(birthDate!, selected),
                    'createdAt': Timestamp.now(),
                  });

                  Navigator.pop(context);
                },
                child: const Text("Сохранить"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= DELETE =================

  Future<void> deleteLast() async {
    if (records.isEmpty) return;

    final last = records.last;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('children')
        .doc(widget.childId)
        .collection('growthRecords')
        .doc(last.id)
        .delete();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    final horizontal = screenW * 0.04;
    final cardPadding = screenW * 0.035;
    final radius = screenW * 0.045;

    final last = records.isNotEmpty ? records.last : null;

    String stats = "";
    String whoText = "";

    if (records.length > 1) {
      final prev = records[records.length - 2];

      final days = last!.date.difference(prev.date).inDays;

      stats =
      "За $days дней\n"
          "Вес: ${(last.weight - prev.weight).toStringAsFixed(2)} кг\n"
          "Рост: ${(last.height - prev.height).toStringAsFixed(1)} см";
    }

    if (last != null) {
      final boy = isBoy ?? last.isBoy;

      final age = birthDate != null
          ? calculateAgeMonths(birthDate!, last.date)
          : last.ageMonths;

      final who = getWHO(age, boy);

      if (who != null) {
        whoText =
        "${compare(last.weight, who['weight']!, "Вес")}\n"
            "${compare(last.height, who['height']!, "Рост")}";
      } else {
        whoText = "ВОЗ данные отсутствуют для возраста $age мес";
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Развитие"),
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
              SizedBox(height: screenH * 0.02),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: showAddDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCFE8E4),
                          foregroundColor: const Color(0xFF4B4B4B),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text("Добавить"),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenH * 0.025),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  children: [
                    card(
                      last == null
                          ? "Нет данных"
                          : "${last.weight} кг / ${last.height} см",
                      16,
                      cardPadding,
                      radius,
                    ),
                    card(
                      stats.isEmpty ? "Нет статистики" : stats,
                      16,
                      cardPadding,
                      radius,
                    ),
                    card(
                      whoText.isEmpty ? "Нет сравнения ВОЗ" : whoText,
                      16,
                      cardPadding,
                      radius,
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenH * 0.01),

              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: deleteLast,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8E1F3),
                    ),
                    child: const Text("Удалить запись"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}