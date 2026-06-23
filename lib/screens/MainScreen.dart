import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:babytracker/screens/activity_screen.dart';
import 'package:babytracker/screens/razvitie_screen.dart';
import 'package:babytracker/screens/eat_screen.dart';
import 'package:babytracker/screens/sleep_screen.dart';

import 'package:babytracker/services/audio_service.dart';

import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  User? get user => FirebaseAuth.instance.currentUser;

  String? selectedChildId;
  String childName = "Выберите ребёнка";

  final audioService = AudioService();
  StreamSubscription? timerSub;

  final ValueNotifier<String> timerNotifier =
  ValueNotifier("∞");

  final List<String> tracks = [
    "assets/audio/white.mp3",
    "assets/audio/rain.mp3",
    "assets/audio/brown.mp3",
    "assets/audio/pink.mp3",
    "assets/audio/veter.mp3",
  ];

  final Map<String, String> trackNames = {
    "assets/audio/white.mp3": "Белый шум",
    "assets/audio/rain.mp3": "Дождь",
    "assets/audio/brown.mp3": "Коричневый шум",
    "assets/audio/pink.mp3": "Розовый шум",
    "assets/audio/veter.mp3": "Ветер",
  };

  String selectedTrack = "assets/audio/white.mp3";
  bool isPlaying = false;
  bool audioLoading = false;
  Duration? selectedTimer;

  @override
  void initState() {
    super.initState();
    loadChild();
    audioService.init();
    audioService.prepare(selectedTrack);
    timerSub = audioService.timerStream.listen(_onTimerTick);
  }

  void _onTimerTick(Duration remaining) {
    if (selectedTimer == null) {
      timerNotifier.value = '∞';
      return;
    }

    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    timerNotifier.value = '$h:$m:$s';

    if (remaining.inSeconds <= 0 && isPlaying) {
      _stopPlayback(resetTimer: true);
    }
  }

  Future<void> _stopPlayback({bool resetTimer = false}) async {
    await audioService.pause();
    audioService.pauseCountdown();

    if (resetTimer && selectedTimer != null) {
      audioService.setTimerDuration(selectedTimer);
    }

    if (!mounted) return;
    setState(() {
      isPlaying = false;
      audioLoading = false;
    });
  }

  // ================= CHILD =================

  Future<void> loadChild() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('selected_child_id');

    if (id == null || user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('children')
        .doc(id)
        .get();

    if (!mounted) return;

    if (doc.exists) {
      setState(() {
        selectedChildId = id;
        childName = doc['name'];
      });
    }
  }

  Future<void> selectChild(String id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_child_id', id);

    setState(() {
      selectedChildId = id;
      childName = name;
    });
  }

  Future<void> deleteChild(String childId, String childName) async {
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid);
    final childRef = userRef.collection('children').doc(childId);

    for (final sub in ['sleep', 'growthRecords', 'activity_records']) {
      final snap = await childRef.collection(sub).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    final eatSnap = await userRef
        .collection('eat_records')
        .where('childId', isEqualTo: childId)
        .get();
    for (final doc in eatSnap.docs) {
      await doc.reference.delete();
    }

    await childRef.delete();

    if (selectedChildId == childId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_child_id');

      if (!mounted) return;

      setState(() {
        selectedChildId = null;
        this.childName = "Выберите ребёнка";
      });
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ребёнок «$childName» удалён')),
    );
  }

  Future<void> confirmDeleteChild(String childId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удаление'),
        content: Text('Удалить «$name» и все записи?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteChild(childId, name);
    }
  }

  // ================= AUDIO =================

  Future<void> toggleMusic() async {
    if (audioLoading) {
      await audioService.stop();
      audioService.pauseCountdown();

      if (!mounted) return;

      setState(() {
        audioLoading = false;
        isPlaying = false;
      });
      return;
    }

    if (isPlaying) {
      await _stopPlayback();
      return;
    }

    setState(() {
      audioLoading = true;
      isPlaying = true;
    });

    try {
      await audioService.play(selectedTrack);

      if (selectedTimer != null) {
        if (audioService.remaining == null ||
            audioService.remaining!.inSeconds <= 0) {
          audioService.setTimerDuration(selectedTimer);
        }
        audioService.startCountdown();
      } else {
        timerNotifier.value = '∞';
      }

      if (!mounted) return;

      setState(() => audioLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isPlaying = false;
        audioLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось запустить звук')),
      );
    }
  }

  Future<void> selectTrack(String track) async {
    if (track == selectedTrack) return;

    setState(() {
      selectedTrack = track;
      audioLoading = true;
    });

    try {
      if (isPlaying) {
        await audioService.play(track);
      } else {
        await audioService.prepare(track);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить трек')),
        );
      }
    } finally {
      if (mounted) setState(() => audioLoading = false);
    }
  }

  Future<void> selectTimer(Duration? duration) async {
    selectedTimer = duration;

    if (duration == null) {
      audioService.stopTimer();
      timerNotifier.value = '∞';
      return;
    }

    audioService.setTimerDuration(duration);

    if (isPlaying) {
      audioService.startCountdown();
    }
  }



  // ================= NAV =================

  void openScreen(String s) {
    if (selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Выберите ребёнка")),
      );
      return;
    }

    Widget page;

    switch (s) {
      case "activity":
        page = ActivityScreen(childId: selectedChildId!);
        break;
      case "razvitie":
        page = RazvitieScreen(childId: selectedChildId!);
        break;
      case "eat":
        page = EatScreen(childId: selectedChildId!);
        break;
      case "sleep":
        page = SleepScreen(childId: selectedChildId!);
        break;
      default:
        return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  void dispose() {
    timerSub?.cancel();
    timerNotifier.dispose();
    audioService.dispose();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // BACKGROUND
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/img.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                const SizedBox(height: 30),

                // CHILD SELECT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.child_care),
                      onPressed: showChildrenDialog,
                    ),

                    Text(
                      childName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        await audioService.stop();
                        await FirebaseAuth.instance.signOut();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 75),

                // AUDIO BAR (НЕ ТРОГАЕМ ЛОГИКУ)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: 87,
                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(14),

                    border: Border.all(
                      color: const Color(0xFFE3E3E3),
                      width: 1.2,
                    ),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: toggleMusic,
                        icon: Icon(
                          (isPlaying || audioLoading)
                              ? Icons.stop
                              : Icons.play_arrow,
                        ),
                      ),

                      PopupMenuButton<int>(
                        onSelected: (value) async {

                          if (value == -1) {
                            await selectTimer(null);
                            return;
                          }

                          if (value == 30) {
                            await selectTimer(
                              const Duration(minutes: 30),
                            );
                          }

                          if (value == 60) {
                            await selectTimer(
                              const Duration(hours: 1),
                            );
                          }

                          if (value == 180) {
                            await selectTimer(
                              const Duration(hours: 3),
                            );
                          }
                        },

                        itemBuilder: (context) => const [

                          PopupMenuItem(
                            value: 30,
                            child: Text("30 минут"),
                          ),

                          PopupMenuItem(
                            value: 60,
                            child: Text("1 час"),
                          ),

                          PopupMenuItem(
                            value: 180,
                            child: Text("3 часа"),
                          ),

                          PopupMenuItem(
                            value: -1,
                            child: Text("Без таймера"),
                          ),
                        ],

                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),

                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                            ),

                            borderRadius: BorderRadius.circular(10),
                          ),

                          child: ValueListenableBuilder(
                            valueListenable: timerNotifier,

                            builder: (_, v, __) {
                              return Text(
                                v,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B4B4B),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: PopupMenuButton<String>(
                          enabled: true,
                          onSelected: selectTrack,
                          itemBuilder: (context) => tracks
                              .map(
                                (t) => PopupMenuItem(
                                  value: t,
                                  child: Text(trackNames[t] ?? t),
                                ),
                              )
                              .toList(),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  trackNames[selectedTrack] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF4B4B4B),
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 110),

                // GRID (КАК В JAVA XML — 2x2)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                      children: [

                        menu(
                          "assets/icons/activity.jpg",
                          "Активность",
                          "Игры, прогулки",
                          const Color(0xFFFAF6C9),
                              () => openScreen("activity"),
                        ),

                        menu(
                          "assets/icons/razvitie.jpg",
                          "Развитие",
                          "Рост и вес",
                          const Color(0xFFCFE8E4),
                              () => openScreen("razvitie"),
                        ),

                        menu(
                          "assets/icons/eat.jpg",
                          "Питание",
                          "Кормление",
                          const Color(0xFFF8E1F3),
                              () => openScreen("eat"),
                        ),

                        menu(
                          "assets/icons/sleep.jpg",
                          "Сон",
                          "Дневной и ночной",
                          const Color(0xFFCADFF4),
                              () => openScreen("sleep"),
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget menu(
      String iconPath,
      String title,
      String subtitle,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Image.asset(
              iconPath,
              width: 55,
              height: 55,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B4B4B),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== CHILD DIALOG (НЕ УБИРАЕМ ФУНКЦИЮ) =====
  void showChildrenDialog() {
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('children')
              .snapshots(),

          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView(
              children: [

                ...docs.map((doc) {
                  final name = doc['name'] as String? ?? 'Без имени';

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: () => confirmDeleteChild(doc.id, name),
                    child: ListTile(
                      title: Text(name),
                      onTap: () async {
                        await selectChild(doc.id, name);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.add),

                  title: const Text(
                    "Добавить ребёнка",
                  ),

                  onTap: () {
                    Navigator.pop(context);
                    showAddChildDialog();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showAddChildDialog() {
    final controller = TextEditingController();

    DateTime? birthDate;
    bool isBoy = true;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Добавить ребёнка"),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ===== ИМЯ =====
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Введите имя",
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== ДАТА РОЖДЕНИЯ =====
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDate: birthDate ?? DateTime.now(),
                      );

                      if (picked != null) {
                        setStateDialog(() {
                          birthDate = picked;
                        });
                      }
                    },
                    child: Text(
                      birthDate == null
                          ? "Выберите дату рождения"
                          : DateFormat('dd.MM.yyyy').format(birthDate!),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== ПОЛ =====
                  Row(
                    children: [

                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              isBoy = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isBoy
                                  ? const Color(0xFFCFE8E4)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: const Center(
                              child: Text("М"),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              isBoy = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isBoy
                                  ? const Color(0xFFCFE8E4)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: const Center(
                              child: Text("Ж"),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Отмена"),
                ),

                TextButton(
                  onPressed: () async {
                    final name = controller.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Введите имя")),
                      );
                      return;
                    }

                    if (birthDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Выберите дату рождения")),
                      );
                      return;
                    }

                    if (user == null) return;

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .collection('children')
                        .add({
                      'name': name,
                      'isBoy': isBoy,
                      'birthDate': birthDate!.toIso8601String(),
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Добавить"),
                ),
              ],
            );
          },
        );
      },
    );
  }


}