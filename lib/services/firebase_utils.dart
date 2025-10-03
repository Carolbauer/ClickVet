import 'package:firebase_auth/firebase_auth.dart';

class FirebaseUtils {
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<UserCredential> register(String email, String password) async {
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}