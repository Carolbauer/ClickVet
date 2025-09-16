import 'package:app/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    }on FirebaseAuthException catch(e){
      setState(() {
        emailTextError = "Usuário ou senha inválidos";
        passwordTextError = "Usuário ou senha inválidos";

      });

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('assets/images/logo1.png', height: 200),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Digite o seu Email',
                prefixIcon: const Icon(
                  Icons.email,
                  color: Color(0xFF8C7A3E)
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF8C7A3E),
                      width: 1
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF6E5F2F),
                      width: 2,
                  ),
                ),
                errorText: emailTextError,
              ),
            ),
             SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: !isVisible,
              decoration: InputDecoration(
                labelText: 'Digite a sua Senha',
                prefixIcon: const Icon(
                  Icons.lock,
                  color: Color(0xFF8C7A3E)
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF8C7A3E),
                  ),
                  onPressed: () {
                    setState(() {
                      isVisible = !isVisible;
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF8C7A3E),
                      width: 1
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF6E5F2F),
                      width: 2,
                  ),
                ),
                errorText: passwordTextError,
              ),
            )
          ],
        ),
      ),
    );

  }
}