import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterTutorScreen extends StatefulWidget {
  const RegisterTutorScreen({super.key});

  @override
  State<RegisterTutorScreen> createState() => _RegisterTutorScreenState();
}

class _RegisterTutorScreenState extends State<RegisterTutorScreen> {
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _cepController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _cepController.dispose();
    super.dispose();
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
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kGold, width: 1.2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kGoldDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Future<void> _handleSaveTutor() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vet = FirebaseAuth.instance.currentUser;
    if (vet == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final data = {
        'name': _nameController.text.trim(),
        'cpf': _cpfController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'cep': _cepController.text.trim(),
        'registeredBy': vet.uid,
        'registeredAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(vet.uid)
          .collection('tutors')
          .add(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutor cadastrado com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar tutor: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const kCreme = Color(0xFFF7F2E6);
    const kGold = Color(0xFF8C7A3E);
    const kGoldDark = Color(0xFF6E5F2F);

    return Scaffold(
      backgroundColor: kCreme,
      appBar: AppBar(
        title: const Text('Cadastro do Tutor'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: kCreme,
        foregroundColor: kGoldDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 24, bottom: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset('assets/images/logo1.png', height: 80),
                      const SizedBox(height: 12),
                      const Text(
                        'Preencha os dados do responsável pelo pet',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 20),

                      // Nome
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: _deco('Nome Completo', icon: Icons.person),
                        validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 16),

                      // CPF
                      TextFormField(
                        controller: _cpfController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _deco('CPF', icon: Icons.badge_outlined),
                        validator: (v) =>
                        (v == null || v.trim().length < 11) ? 'CPF inválido' : null,
                      ),
                      const SizedBox(height: 16),

                      // E-mail
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _deco('E-mail', icon: Icons.email),
                        validator: (v) =>
                        (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Telefone
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _deco('Telefone', icon: Icons.phone),
                        validator: (v) =>
                        (v == null || v.trim().length < 8) ? 'Telefone inválido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Endereço
                      TextFormField(
                        controller: _addressController,
                        textInputAction: TextInputAction.next,
                        decoration: _deco('Endereço', icon: Icons.location_on_outlined),
                      ),
                      const SizedBox(height: 16),

                      // Cidade
                      TextFormField(
                        controller: _cityController,
                        textInputAction: TextInputAction.next,
                        decoration: _deco('Cidade', icon: Icons.location_city),
                      ),
                      const SizedBox(height: 16),

                      // CEP
                      TextFormField(
                        controller: _cepController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _deco('CEP', icon: Icons.map_outlined),
                      ),
                      const SizedBox(height: 20),

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
                            onPressed: isLoading ? null : _handleSaveTutor,
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
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Text(
                              'CADASTRAR TUTOR',
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
                          'Voltar',
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
      ),
    );
  }
}
