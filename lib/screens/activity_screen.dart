import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/activity_record.dart';

class ActivityScreen extends StatefulWidget {
  final String childId;

  const ActivityScreen({
    super.key,
    required this.childId,
  });

  @override
  State<ActivityScreen> createState() =>
      _ActivityScreenState();
}

class _ActivityScreenState
    extends State<ActivityScreen> {

  final user =
      FirebaseAuth.instance.currentUser;

  DateTime currentDate =
  DateTime.now();

  List<ActivityRecord> allRecords = [];
  List<ActivityRecord> filteredRecords =
  [];

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
        .collection('children')
        .doc(widget.childId)
        .collection('activity_records')
        .snapshots()
        .listen((snapshot) {

      allRecords =
          snapshot.docs.map((doc) {
            return ActivityRecord
                .fromFirestore(
              doc.id,
              doc.data(),
            );
          }).toList();

      filterByDate();
    });
  }

  void filterByDate() {
    final format =
    DateFormat('dd.MM.yyyy');

    setState(() {

      filteredRecords =
          allRecords.where((r) {
            return format.format(r.date) ==
                format.format(currentDate);
          }).toList();

      filteredRecords.sort(
            (a, b) =>
            b.time.compareTo(a.time),
      );
    });
  }

  void changeDate(int delta) {
    setState(() {
      currentDate =
          currentDate.add(
            Duration(days: delta),
          );
    });

    filterByDate();
  }

  Future<void> deleteRecord(
      ActivityRecord record,
      ) async {

    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('children')
        .doc(widget.childId)
        .collection('activity_records')
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

    final dateText =
    DateFormat('dd.MM.yyyy')
        .format(currentDate);

    final screenWidth =
        MediaQuery.of(context).size.width;

    final screenHeight =
        MediaQuery.of(context).size.height;

    return Scaffold(

      extendBodyBehindAppBar: true,

      appBar: AppBar(

        title: const Text("Активность"),

        backgroundColor:
        Colors.white.withOpacity(0.15),

        elevation: 0,

        centerTitle: true,

        foregroundColor: Colors.black,
      ),

      body: Container(

        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              "assets/images/img.png",
            ),
            fit: BoxFit.cover,
          ),
        ),

        child: SafeArea(

          child: Column(
            children: [

              SizedBox(
                height: screenHeight * 0.06,
              ),

              // ===== DATE + BUTTON =====

              Padding(

                padding:
                EdgeInsets.symmetric(
                  horizontal:
                  screenWidth * 0.04,
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

                              style:
                              ElevatedButton
                                  .styleFrom(

                                backgroundColor:
                                const Color(
                                  0xFFFAF6C9,
                                ),

                                elevation: 0,

                                padding:
                                EdgeInsets.zero,

                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    15,
                                  ),
                                ),
                              ),

                              onPressed: () =>
                                  changeDate(-1),

                              child: const Icon(
                                Icons.chevron_left,
                                size: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),

                          SizedBox(
                            width:
                            screenWidth *
                                0.025,
                          ),

                          Flexible(
                            child: Text(

                              dateText,

                              overflow:
                              TextOverflow
                                  .ellipsis,

                              style:
                              TextStyle(
                                fontSize:
                                screenWidth *
                                    0.042,

                                fontWeight:
                                FontWeight
                                    .bold,

                                color:
                                Colors.black,
                              ),
                            ),
                          ),

                          SizedBox(
                            width:
                            screenWidth *
                                0.025,
                          ),

                          SizedBox(
                            width: 28,
                            height: 28,

                            child: ElevatedButton(

                              style:
                              ElevatedButton
                                  .styleFrom(

                                backgroundColor:
                                const Color(
                                  0xFFFAF6C9,
                                ),

                                elevation: 0,

                                padding:
                                EdgeInsets.zero,

                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    15,
                                  ),
                                ),
                              ),

                              onPressed: () =>
                                  changeDate(1),

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

                    SizedBox(
                      width:
                      screenWidth * 0.03,
                    ),

                    // ===== BUTTON =====

                    SizedBox(

                      height: 40,

                      child: ElevatedButton(

                        style:
                        ElevatedButton
                            .styleFrom(

                          backgroundColor:
                          const Color(
                            0xFFFAF6C9,
                          ),

                          foregroundColor:
                          const Color(
                            0xFF4B4B4B,
                          ),

                          elevation: 0,

                          padding:
                          EdgeInsets.symmetric(
                            horizontal:
                            screenWidth *
                                0.04,
                          ),

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              24,
                            ),
                          ),
                        ),

                        onPressed:
                        showAddDialog,

                        child: Text(

                          "Добавить",

                          style: TextStyle(
                            fontSize:
                            screenWidth *
                                0.04,

                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: screenHeight * 0.02,
              ),

              // ===== LIST =====

              Expanded(

                child: ListView.builder(

                  padding:
                  EdgeInsets.symmetric(
                    horizontal:
                    screenWidth * 0.03,
                  ),

                  itemCount:
                  filteredRecords.length,

                  itemBuilder:
                      (context, index) {

                    final r =
                    filteredRecords[index];

                    return GestureDetector(

                      onLongPress: () async {

                        final confirm =
                        await showDialog(

                          context: context,

                          builder: (_) =>
                              AlertDialog(

                                title:
                                const Text(
                                  "Удаление",
                                ),

                                content:
                                const Text(
                                  "Удалить запись?",
                                ),

                                actions: [

                                  TextButton(

                                    child:
                                    const Text(
                                      "Нет",
                                    ),

                                    onPressed: () {
                                      Navigator.pop(
                                        context,
                                        false,
                                      );
                                    },
                                  ),

                                  TextButton(

                                    child:
                                    const Text(
                                      "Да",
                                    ),

                                    onPressed: () {
                                      Navigator.pop(
                                        context,
                                        true,
                                      );
                                    },
                                  ),
                                ],
                              ),
                        );

                        if (confirm == true) {
                          await deleteRecord(r);
                        }
                      },

                      child: Container(

                        margin:
                        EdgeInsets.only(
                          bottom:
                          screenHeight *
                              0.01,
                        ),

                        decoration:
                        BoxDecoration(

                          color:
                          Colors.white
                              .withOpacity(
                            0.93,
                          ),

                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),

                          border: Border.all(
                            color:
                            const Color(
                              0xFFE3E3E3,
                            ),
                          ),

                          boxShadow: const [

                            BoxShadow(
                              color:
                              Colors.black12,
                              blurRadius: 6,
                              offset:
                              Offset(0, 2),
                            ),
                          ],
                        ),

                        child: Padding(

                          padding:
                          EdgeInsets.symmetric(
                            horizontal:
                            screenWidth *
                                0.04,

                            vertical:
                            screenHeight *
                                0.017,
                          ),

                          child: Column(

                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                            children: [

                              Row(
                                children: [

                                  Expanded(

                                    child: Text(

                                      r.activityType,

                                      overflow:
                                      TextOverflow
                                          .ellipsis,

                                      style:
                                      TextStyle(
                                        fontSize:
                                        screenWidth *
                                            0.045,

                                        fontWeight:
                                        FontWeight
                                            .bold,

                                        color:
                                        const Color(
                                          0xFF4B4B4B,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    width:
                                    screenWidth *
                                        0.02,
                                  ),

                                  Text(

                                    DateFormat(
                                      'HH:mm',
                                    ).format(
                                      r.time,
                                    ),

                                    style:
                                    TextStyle(
                                      fontSize:
                                      screenWidth *
                                          0.034,

                                      color:
                                      Colors
                                          .black54,

                                      fontWeight:
                                      FontWeight
                                          .w500,
                                    ),
                                  ),
                                ],
                              ),

                              if (r.comment !=
                                  null &&
                                  r.comment!
                                      .isNotEmpty) ...[

                                SizedBox(
                                  height:
                                  screenHeight *
                                      0.008,
                                ),

                                Text(

                                  r.comment!,

                                  style:
                                  TextStyle(
                                    fontSize:
                                    screenWidth *
                                        0.036,

                                    color:
                                    Colors
                                        .black87,

                                    height: 1.3,
                                  ),
                                ),
                              ],
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

    final commentController =
    TextEditingController();

    String? selectedType;

    TimeOfDay time =
    TimeOfDay.now();

    showDialog(

      context: context,

      builder: (_) {

        return AlertDialog(

          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(30),
          ),

          title:
          const Text("Добавить активность"),

          content: StatefulBuilder(

            builder:
                (context, setStateDialog) {

              Widget btn(String text) {

                final isSelected =
                    selectedType == text;

                return Padding(

                  padding:
                  const EdgeInsets.only(
                    right: 8,
                    bottom: 8,
                  ),

                  child: ElevatedButton(

                    style:
                    ElevatedButton.styleFrom(

                      backgroundColor:
                      isSelected
                          ? const Color(
                        0xFFCFFEC7,
                      )
                          : const Color(
                        0xFFFAF6C9,
                      ),

                      elevation: 0,

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          30,
                        ),
                      ),
                    ),

                    onPressed: () {
                      setStateDialog(
                              () =>
                          selectedType =
                              text);
                    },

                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              }

              return Column(

                mainAxisSize:
                MainAxisSize.min,

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  SingleChildScrollView(

                    scrollDirection:
                    Axis.horizontal,

                    child: Row(
                      children: [

                        btn("Массаж"),
                        btn("Прогулка"),
                        btn("Игрушки"),
                        btn("Другое"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller:
                    commentController,

                    decoration:
                    const InputDecoration(
                      hintText:
                      "Введите комментарий",
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [

                      const Text("Время:"),

                      const SizedBox(
                        width: 10,
                      ),

                      ElevatedButton(

                        style:
                        ElevatedButton
                            .styleFrom(

                          backgroundColor:
                          const Color(
                            0xFFFAF6C9,
                          ),

                          elevation: 0,
                        ),

                        onPressed: () async {

                          final picked =
                          await showTimePicker(

                            context: context,

                            initialTime: time,
                          );

                          if (picked != null) {
                            setStateDialog(
                                    () =>
                                time =
                                    picked);
                          }
                        },

                        child: Text(

                          time.format(context),

                          style:
                          const TextStyle(
                            color:
                            Colors.black,
                          ),
                        ),
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

                if (selectedType == null) {

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(

                    const SnackBar(

                      content: Text(
                        "Выберите тип активности",
                      ),
                    ),
                  );

                  return;
                }

                final date = DateTime(
                  currentDate.year,
                  currentDate.month,
                  currentDate.day,
                );

                final dateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );

                final record =
                ActivityRecord(

                  id: '',

                  activityType:
                  selectedType!,

                  comment:
                  commentController
                      .text
                      .isEmpty
                      ? null
                      : commentController
                      .text,

                  time: dateTime,

                  date: date,
                );

                await FirebaseFirestore
                    .instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('children')
                    .doc(widget.childId)
                    .collection(
                  'activity_records',
                )
                    .add(record.toMap());

                Navigator.pop(context);
              },

              child:
              const Text("Сохранить"),
            ),
          ],
        );
      },
    );
  }
}