import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/child.dart';

class FirebaseService {

  static final user = FirebaseAuth.instance.currentUser;

  static Stream<List<Child>> getChildren() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('children')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Child.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  static Future<void> addChild(String name) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('children')
        .add({'name': name});
  }

  static Future<Child?> getChildById(String id) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('children')
        .doc(id)
        .get();

    if (!doc.exists) return null;

    return Child.fromFirestore(doc.id, doc.data()!);
  }
}