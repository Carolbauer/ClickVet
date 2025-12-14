import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  late UserCredential userCredential;

  Future<UserCredential> makeLogin(String email, String password) async {
    try {
      return userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  Future<void> logout() async {
    await firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Login com Google cancelado pelo usuário');
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await firebaseAuth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        final usersRef = FirebaseFirestore.instance.collection('users');

        await usersRef.doc(user.uid).set(
          {
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'phone': user.phoneNumber ?? '',
            'photoUrl': user.photoURL ?? '',
            'type': 'PF',
            'crmv': '',
            'doc': '',
            'responsibleCpf': null,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'FirebaseAuthException em signInWithGoogle: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, st) {
      debugPrint('Erro genérico em signInWithGoogle: $e\n$st');
      rethrow;
    }
  }
}
