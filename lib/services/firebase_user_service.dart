import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser(String uid, Map<String, dynamic> data) async {
    await _db.collection("users").doc(uid).set(data);
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await _db.collection("users").doc(uid).get();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection("users").doc(uid).update(data);
  }
}