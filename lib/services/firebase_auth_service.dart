import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  FirebaseAuth firevaseAuth = FirebaseAuth.instance;
  late UserCredential userCredential;

  Future<UserCredential>makeLogin(String email, String password)async{
    try{
      return userCredential = await firevaseAuth.signInWithEmailAndPassword(email: email, password: password);
    }on FirebaseAuthException catch(e){
      throw FirebaseAuthException(code: e.code);
    }
  }
  Logout(){
    firevaseAuth.signOut();
  }
}