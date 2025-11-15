import 'dart:io';
import 'package:app/screens/register_tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/vet_scaffold.dart';
import 'package:app/widgets/app_drawer.dart';

class RegisterPetScreen extends StatefulWidget {
  const RegisterPetScreen({super.key});
  static const routeName = '/register-pet';

  @override
  State<RegisterPetScreen> createState() => _RegisterPetScreenState();
}

class _RegisterPetScreenState extends State<RegisterPetScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _weightController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _microchipController = TextEditingController();

  String? _selectedTutorId;
  String? _selectedTutorName;
  String? _selectedGender;

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _weightController.dispose();
    _birthDateController.dispose();
    _microchipController.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: ClickVetColors.gold) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ClickVetColors.gold, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ClickVetColors.goldDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _imageFile = picked);
    }
  }

  Future<void> _savePet() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vet = FirebaseAuth.instance.currentUser;
    if (vet == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
      );
      return;
    }

    if (_selectedTutorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tutor responsável.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final petsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(vet.uid)
          .collection('pets');

      final data = {
        'name': _nameController.text.trim(),
        'tutorId': _selectedTutorId,
        'tutorName': _selectedTutorName,
        'species': _speciesController.text.trim(),
        'breed': _breedController.text.trim(),
        'gender': _selectedGender,
        'color': _colorController.text.trim(),
        'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
        'birthDate': _birthDateController.text.trim(),
        'microchip': _microchipController.text.trim().isEmpty
            ? null
            : _microchipController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'photoPath': _imageFile?.path,
      };

      await petsRef.add(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet cadastrado com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar pet: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VetScaffold(
      selectedKey: DrawerItemKey.petRegister,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text(
          'Cadastro do Pet',
          style: TextStyle(color: ClickVetColors.gold),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: ClickVetColors.goldDark),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: ClickVetColors.goldDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Preencha os dados do animal',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),

              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor:
                        ClickVetColors.gold.withOpacity(0.15),
                        backgroundImage: _imageFile != null
                            ? FileImage(File(_imageFile!.path))
                            : null,
                        child: _imageFile == null
                            ? const Icon(Icons.pets,
                            color: ClickVetColors.goldDark, size: 32)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_camera_outlined,
                          color: ClickVetColors.goldDark),
                      label: const Text(
                        'Adicionar foto do pet',
                        style: TextStyle(color: ClickVetColors.goldDark),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('tutors')
                    .orderBy('name')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(minHeight: 2),
                    );
                  }

                  final docs = snap.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nenhum tutor cadastrado. Cadastre um tutor antes de vincular o pet.',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const RegisterTutorScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Cadastrar Tutor',
                              style: TextStyle(
                                color: ClickVetColors.goldDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedTutorId,
                        items: docs.map((d) {
                          final data = d.data();
                          final name =
                          (data['name'] ?? 'Sem nome').toString();
                          return DropdownMenuItem(
                            value: d.id,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTutorId = value;
                            if (value != null) {
                              final doc = docs
                                  .firstWhere((d) => d.id == value);
                              _selectedTutorName =
                                  (doc.data()['name'] ?? '').toString();
                            } else {
                              _selectedTutorName = null;
                            }
                          });
                        },
                        decoration: _deco('Tutor responsável'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

              TextFormField(
                controller: _nameController,
                decoration: _deco('Nome do Pet', icon: Icons.favorite_border),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o nome do pet' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _speciesController,
                decoration: _deco('Espécie'),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _breedController,
                decoration: _deco('Raça', icon: Icons.pets_outlined),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                  DropdownMenuItem(value: 'Fêmea', child: Text('Fêmea')),
                ],
                onChanged: (v) => setState(() => _selectedGender = v),
                decoration: _deco('Sexo'),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _colorController,
                decoration: _deco('Cor', icon: Icons.palette_outlined),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _weightController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: _deco('Peso (kg)',
                    icon: Icons.monitor_weight_outlined),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _birthDateController,
                decoration: _deco(
                    'Data de nascimento (opcional)',
                    icon: Icons.cake_outlined),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _microchipController,
                decoration: _deco(
                  'Número do Microchip (opcional)',
                  icon: Icons.credit_card_outlined,
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ClickVetColors.goldLight,
                        ClickVetColors.gold,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'CADASTRAR PET',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Tutor não cadastrado?',
                    style: TextStyle(color: Colors.black54),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterTutorScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Cadastrar Tutor',
                      style: TextStyle(
                        color: Color(0xFF8C7A3E),
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
