import 'dart:io';
import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/vet_scaffold.dart';
import 'package:app/widgets/app_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditPetScreen extends StatefulWidget {
  const EditPetScreen({super.key, required this.petId});

  final String petId;

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _microchipController = TextEditingController();

  final _medicalHistoryController = TextEditingController();
  final _vaccinationsController = TextEditingController();
  final _medicationsController = TextEditingController();

  String? _selectedGender;
  String? _tutorName;

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String? _existingPhotoPath;

  @override
  void initState() {
    super.initState();
    _loadPet();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _microchipController.dispose();
    _medicalHistoryController.dispose();
    _vaccinationsController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  Future<void> _loadPet() async {
    final vet = FirebaseAuth.instance.currentUser;
    if (vet == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(vet.uid)
          .collection('pets')
          .doc(widget.petId)
          .get();

      if (!doc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet não encontrado.')),
        );
        Navigator.pop(context);
        return;
      }

      final data = doc.data() ?? {};

      _nameController.text = (data['name'] ?? '').toString();
      _speciesController.text = (data['species'] ?? '').toString();
      _breedController.text = (data['breed'] ?? '').toString();
      _birthDateController.text = (data['birthDate'] ?? '').toString();
      _colorController.text = (data['color'] ?? '').toString();
      _microchipController.text = (data['microchip'] ?? '').toString();
      _weightController.text =
      data['weight'] != null ? data['weight'].toString() : '';

      _selectedGender = (data['gender'] ?? '').toString().isEmpty
          ? null
          : data['gender'].toString();

      _tutorName = (data['tutorName'] ?? '').toString();

      _medicalHistoryController.text =
          (data['medicalHistory'] ?? '').toString();
      _vaccinationsController.text =
          (data['vaccinations'] ?? '').toString();
      _medicationsController.text =
          (data['medications'] ?? '').toString();

      _existingPhotoPath = (data['photoPath'] ?? '').toString();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar pet: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _deco(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: ClickVetColors.gold) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ClickVetColors.gold, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ClickVetColors.goldDark, width: 2),
      ),
      contentPadding:
      const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _imageFile = picked;
      });
    }
  }

  void _removePhoto() {
    setState(() {
      _imageFile = null;
      _existingPhotoPath = null;
    });
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

    setState(() => _isSaving = true);

    try {
      final petsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(vet.uid)
          .collection('pets')
          .doc(widget.petId);

      final data = {
        'name': _nameController.text.trim(),
        'species': _speciesController.text.trim(),
        'breed': _breedController.text.trim(),
        'birthDate': _birthDateController.text.trim(),
        'gender': _selectedGender,
        'color': _colorController.text.trim(),
        'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
        'microchip': _microchipController.text.trim().isEmpty
            ? null
            : _microchipController.text.trim(),
        'tutorName': _tutorName,
        'medicalHistory': _medicalHistoryController.text.trim(),
        'vaccinations': _vaccinationsController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'photoPath': _imageFile != null ? _imageFile!.path : _existingPhotoPath,
      };

      await petsRef.update(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet atualizado com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar alterações: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: ClickVetColors.bg,
        body: Center(
          child: CircularProgressIndicator(
            valueColor:
            AlwaysStoppedAnimation<Color>(ClickVetColors.goldDark),
          ),
        ),
      );
    }

    return VetScaffold(
      selectedKey: DrawerItemKey.patients,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text(
          'Editar Pet',
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
                'Atualize os dados do animal',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ClickVetColors.gold,
                    width: 1.8,
                  ),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.pets,
                            color: ClickVetColors.goldDark, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Foto do Pet',
                          style: TextStyle(
                            color: ClickVetColors.goldDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 52,
                                backgroundColor:
                                ClickVetColors.gold.withOpacity(0.15),
                                backgroundImage: _imageFile != null
                                    ? FileImage(File(_imageFile!.path))
                                    : (_existingPhotoPath != null &&
                                    _existingPhotoPath!.isNotEmpty)
                                    ? FileImage(File(_existingPhotoPath!))
                                    : null,
                                child: (_imageFile == null &&
                                    (_existingPhotoPath == null ||
                                        _existingPhotoPath!.isEmpty))
                                    ? const Icon(Icons.pets,
                                    color: ClickVetColors.goldDark,
                                    size: 32)
                                    : null,
                              ),
                              if (_imageFile != null ||
                                  (_existingPhotoPath != null &&
                                      _existingPhotoPath!.isNotEmpty))
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: GestureDetector(
                                    onTap: _removePhoto,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              color: ClickVetColors.goldDark,
                            ),
                            label: Text(
                              _imageFile != null ||
                                  (_existingPhotoPath != null &&
                                      _existingPhotoPath!.isNotEmpty)
                                  ? 'Alterar Foto'
                                  : 'Adicionar Foto do Pet',
                              style: const TextStyle(
                                  color: ClickVetColors.goldDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ClickVetColors.gold,
                    width: 1.8,
                  ),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline,
                            color: ClickVetColors.goldDark, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Informações Básicas',
                          style: TextStyle(
                            color: ClickVetColors.goldDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration:
                      _deco('Nome do Pet *', icon: Icons.favorite_border),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o nome do pet'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _speciesController,
                      decoration: _deco('Espécie *'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe a espécie'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _breedController,
                      decoration:
                      _deco('Raça *', icon: Icons.pets_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe a raça'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _birthDateController,
                      decoration: _deco(
                        'Data de nascimento',
                        icon: Icons.cake_outlined,
                        hint: 'Ex.: 15/03/2021',
                      ),
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      items: const [
                        DropdownMenuItem(
                            value: 'Macho', child: Text('Macho')),
                        DropdownMenuItem(
                            value: 'Fêmea', child: Text('Fêmea')),
                      ],
                      onChanged: (v) => setState(() => _selectedGender = v),
                      decoration: _deco('Sexo'),
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
                      controller: _colorController,
                      decoration:
                      _deco('Cor / Pelagem', icon: Icons.palette_outlined),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _microchipController,
                      decoration: _deco(
                        'Número do Microchip (opcional)',
                        icon: Icons.credit_card_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ClickVetColors.gold,
                    width: 1.8,
                  ),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tutor',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: _deco('Nome do Tutor'),
                      controller:
                      TextEditingController(text: _tutorName ?? '—'),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Para alterar o tutor, cadastre um novo pet com o tutor desejado.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ClickVetColors.gold,
                    width: 1.8,
                  ),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Histórico Médico',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _medicalHistoryController,
                      maxLines: 4,
                      decoration: _deco(
                        'Histórico Médico',
                        hint: 'Doenças prévias, cirurgias, alergias...',
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _vaccinationsController,
                      maxLines: 3,
                      decoration: _deco(
                        'Vacinas',
                        hint: 'Histórico de vacinação...',
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _medicationsController,
                      maxLines: 3,
                      decoration: _deco(
                        'Medicações',
                        hint: 'Medicações em uso ou histórico...',
                      ),
                    ),
                  ],
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
                    onPressed: _isSaving ? null : _savePet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    )
                        : const Text(
                      'SALVAR ALTERAÇÕES',
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

              OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ClickVetColors.gold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: ClickVetColors.goldDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
