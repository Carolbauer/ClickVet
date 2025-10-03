import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/services/firebase_utils.dart';
import 'package:app/services/firebase_user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isIndividual = true;
  bool isLoading = false;

  final firebaseUtils = FirebaseUtils();
  final userService = UserService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _crmvController = TextEditingController();
  final _emailController = TextEditingController();
  final _docController = TextEditingController();
  final _respCpfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _crmvController.dispose();
    _emailController.dispose();
    _docController.dispose();
    _respCpfController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final pass  = _passwordController.text;
    final pass2 = _confirmPasswordController.text;


    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe e-mail e senha.')),
      );
      return;
    }
    if (pass != pass2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não conferem.')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final cred = await firebaseUtils.register(email, pass);
      final uid = cred.user!.uid;

      final data = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'crmv': _crmvController.text.trim(),
        'email': email,
        'type': isIndividual ? 'PF' : 'PJ',
        'doc': _docController.text.trim(),
        'responsibleCpf': isIndividual ? null : _respCpfController.text.trim(),
        'createdAt': DateTime.now(),
      };
      await userService.createUser(uid, data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro concluído!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  InputDecoration _deco(String label, {IconData? icon}) {
    const kGold = Color(0xFF8C7A3E);
    const kGoldDark = Color(0xFF6E5F2F);
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: kGold) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kGold, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kGoldDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    const kGold = Color(0xFF8C7A3E);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro do veterinário"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child:SingleChildScrollView(
        padding: const EdgeInsets.only(top: 24, bottom: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/logo1.png', height: 80),
                  const SizedBox(height: 15),
                  const Text(
                    "Crie sua conta",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: isIndividual,
                        activeColor: kGold,
                        onChanged: (v) => setState(() => isIndividual = v!),
                      ),
                      Text(
                        "Pessoa Física",
                        style: TextStyle(
                          fontWeight: isIndividual ? FontWeight.bold : FontWeight.normal,
                          color: isIndividual ? kGold : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Radio<bool>(
                        value: false,
                        groupValue: isIndividual,
                        activeColor: kGold,
                        onChanged: (v) => setState(() => isIndividual = v!),
                      ),
                      Text(
                        "Pessoa Jurídica",
                        style: TextStyle(
                          fontWeight: !isIndividual ? FontWeight.bold : FontWeight.normal,
                          color: !isIndividual ? kGold : Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: _deco("Nome Completo", icon: Icons.person),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _deco("Telefone", icon: Icons.phone),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _crmvController,
                    textInputAction: TextInputAction.next,
                    decoration: _deco("Número do CRMV", icon: Icons.badge_outlined),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _deco("Email", icon: Icons.email),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _docController,
                    keyboardType: TextInputType.number,
                    textInputAction: isIndividual ? TextInputAction.next : TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _deco(isIndividual ? "CPF" : "CNPJ", icon: Icons.credit_card),
                  ),
                  const SizedBox(height: 16),

                  if (!isIndividual) ...[
                    TextField(
                      controller: _respCpfController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _deco("CPF do responsável", icon: Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    decoration: _deco("Senha", icon: Icons.lock),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: _deco("Confirmar Senha", icon: Icons.lock),
                  ),
                  const SizedBox(height: 16),

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
                        onPressed: isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                            : const Text(
                          'CADASTRAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Já tem uma conta? Entrar',
                      style: TextStyle(
                        color: Colors.black54,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ),
      ),
    );
  }
}
