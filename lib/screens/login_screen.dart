import 'package:app/screens/home_screen.dart';
import 'package:app/screens/register_screen.dart';
import 'package:app/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  final firebaseAuth = FirebaseAuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? emailTextError;
  String? passwordTextError;
  bool isLoading = false;
  bool isVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    setState(() {
      isLoading = true;
      emailTextError = null;
      passwordTextError = null;
    });

    try {
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          emailTextError = email.isEmpty ? 'Informe seu e-mail' : null;
          passwordTextError = password.isEmpty ? 'Informe sua senha' : null;
        });
        return;
      }

      await firebaseAuth.makeLogin(email, password);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-email' => 'E-mail inválido.',
        'user-disabled' => 'Usuário desabilitado.',
        'user-not-found' => 'Usuário não encontrado.',
        'wrong-password' => 'Senha incorreta.',
        _ => 'Usuário ou senha inválidos.',
      };
      setState(() {
        emailTextError = msg;
        passwordTextError = msg;
      });
    } catch (_) {
      setState(() {
        emailTextError = 'Falha ao entrar. Tente novamente.';
        passwordTextError = 'Falha ao entrar. Tente novamente.';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  InputDecoration _deco({
    required String label,
    required IconData leading,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(leading, color: const Color(0xFF8C7A3E)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8C7A3E), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6E5F2F), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 560),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Image.asset('assets/images/logo1.png', height: 200),
                const SizedBox(height: 8),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email
                  ],
                  decoration: _deco(
                    label: 'Digite o seu Email',
                    leading: Icons.email,
                  ).copyWith(errorText: emailTextError),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: passwordController,
                  obscureText: !isVisible,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => isLoading ? null : handleLogin(),
                  decoration: _deco(
                    label: 'Digite a sua Senha',
                    leading: Icons.lock,
                    suffix: IconButton(
                      icon: Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF8C7A3E),
                      ),
                      onPressed: () =>
                          setState(() => isVisible = !isVisible),
                    ),
                  ).copyWith(errorText: passwordTextError),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Insira seu e-mail para recuperar a senha.'),
                          ),
                        );
                        return;
                      }
                      try {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(email: email);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Enviamos um link de recuperação para $email.'),
                          ),
                        );
                      } on FirebaseAuthException catch (e) {
                        final msg = e.code == 'user-not-found'
                            ? 'Usuário não encontrado.'
                            : 'Erro ao enviar e-mail de recuperação.';
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );
                      }
                    },
                    child: const Text(
                      'Esqueci minha senha?',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ).copyWith(
                        overlayColor:
                        MaterialStateProperty.resolveWith<Color?>(
                              (states) => states.contains(
                              MaterialState.pressed)
                              ? const Color(0xFF8B6914).withOpacity(0.20)
                              : null,
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
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
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                        child:
                        Container(height: 1, color: Colors.black26)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'ou entre com',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    Expanded(
                        child:
                        Container(height: 1, color: Colors.black26)),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () async {
                      setState(() {
                        emailTextError = null;
                        passwordTextError = null;
                      });

                      setState(() => isLoading = true);
                      try {
                        await firebaseAuth.signInWithGoogle();
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen(),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Erro ao entrar com o Google: $e'),
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Image.asset(
                        'assets/images/google_logo.png',
                        width: 18,
                        height: 18,
                      ),
                    ),
                    label: const Text(
                      'Entrar com Google',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Não possui uma conta?',
                      style: TextStyle(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Cadastre-se',
                        style: TextStyle(
                          color: Color(0xFF8C7A3E),
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
