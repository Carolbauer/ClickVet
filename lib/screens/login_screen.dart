import 'package:app/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  FirebaseAuthService firebaseAuth = FirebaseAuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? emailTextError;
  String? passwordTextError;
  bool isLoading = false;
  bool isVisible = false;

  Future<void> handleLogin() async {
    setState(() {
      isLoading = true;
      emailTextError = null;
      passwordTextError = null;
    });
    try {
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
    } on FirebaseAuthException catch (e) {
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
                  color: Color(0xFF8C7A3E),
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF8C7A3E),
                    width: 1,
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
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: !isVisible,
              decoration: InputDecoration(
                labelText: 'Digite a sua Senha',
                prefixIcon: const Icon(
                  Icons.lock,
                  color: Color(0xFF8C7A3E),
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
                    width: 1,
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
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, insira seu email para recuperar a senha.'),
                      ),
                    );
                    return;
                  }
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Enviamos um link de recuperação para $email.'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao enviar email de recuperação. Tente novamente.'),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Esqueci minha senha?',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFB1913B), Color(0xFF7D6A25)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ],
              ),
              child: ElevatedButton(
                  onPressed: isLoading? null : handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'ENTRAR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                  )
              ),)
            )
          ],
        ),
      ),
    );
  }
}
