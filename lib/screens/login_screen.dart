import 'package:app/services/firebase_auth_service.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen>{
  FirebaseAuthService firebaseAuth = FirebaseAuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? emailTextError;
  String? passwordTextError;
  bool isLoading = false;
  bool isVisible = false;

  Future<void> handleLogin() async{
    setState(() {
      isLoading = true;
      emailTextError = null;
      passwordTextError = null;
    });
    try{
      var email = emailController.text.trim();
      var password = passwordController.text;
      await firebaseAuth.makeLogin(email, password);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Logged In Successfully!')),
          ),
        ),
      );
    }on Exception catch(e){
      setState(() {
        isLoading = false;
        if(e.toString().contains('user-not-found')){
          emailTextError = 'No user found for that email.';
        }else if(e.toString().contains('wrong-password')){
          passwordTextError = 'Wrong password provided for that user.';
        }else if(e.toString().contains('invalid-email')){
          emailTextError = 'The email address is not valid.';
        }else if(e.toString().contains('too-many-requests')){
          emailTextError = 'Too many requests. Try again later.';
        }else{
          emailTextError = 'An undefined Error happened.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Tela de Login'),
      ),
    );
  }
}