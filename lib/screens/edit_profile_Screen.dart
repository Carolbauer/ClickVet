import 'dart:io';

import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/app_drawer.dart';
import 'package:app/widgets/vet_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const routeName = '/edit-profile';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = true;
  String? _error;

  bool _isIndividual = true;
  bool _showPasswordSection = false;

  final _crmvController = TextEditingController();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  String? _errorCurrentPass;
  String? _errorNewPass;
  String? _errorConfirmPass;

  String? _photoUrl;
  XFile? _pickedImage;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _crmvController.dispose();
    _nameController.dispose();
    _cpfController.dispose();
    _cnpjController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Usuário não autenticado.';
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Dados de perfil não encontrados.';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final type = (data['type'] ?? 'PF') as String;
      final isPF = type == 'PF';

      _isIndividual = isPF;
      _crmvController.text = (data['crmv'] ?? '') as String;
      _nameController.text = (data['name'] ?? '') as String;
      _emailController.text = (data['email'] ?? '') as String;
      _phoneController.text = (data['phone'] ?? '') as String;

      final docField = (data['doc'] ?? '') as String;
      final respCpf = (data['responsibleCpf'] ?? '') as String;
      _cpfController.text = isPF ? docField : respCpf;
      _cnpjController.text = isPF ? '' : docField;

      _photoUrl = data['photoUrl'] as String?;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar dados. Tente novamente.';
        _isLoading = false;
      });
      debugPrint('Erro _loadData: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 600,
      );
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível selecionar a imagem.'),
        ),
      );
    }
  }

  bool _validatePassword() {
    String? eCurr;
    String? eNew;
    String? eConf;

    if (_showPasswordSection) {
      if (_currentPassController.text.isEmpty) {
        eCurr = 'Senha atual é obrigatória';
      }
      if (_newPassController.text.isEmpty) {
        eNew = 'Nova senha é obrigatória';
      } else if (_newPassController.text.length < 6) {
        eNew = 'A senha deve ter pelo menos 6 caracteres';
      }
      if (_newPassController.text != _confirmPassController.text) {
        eConf = 'As senhas não coincidem';
      }
    }

    setState(() {
      _errorCurrentPass = eCurr;
      _errorNewPass = eNew;
      _errorConfirmPass = eConf;
    });

    return eCurr == null && eNew == null && eConf == null;
  }

  Future<String?> _uploadPhotoIfNeeded(String uid) async {
    if (_pickedImage == null) return _photoUrl;

    try {
      final file = File(_pickedImage!.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('$uid.jpg');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Erro ao subir foto: $e');
      if (!mounted) return _photoUrl;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao enviar foto. Tente novamente.'),
        ),
      );
      return _photoUrl;
    }
  }

  Future<void> _handleSave() async {
    if (!_validatePassword()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = user.uid;

      final newPhotoUrl = await _uploadPhotoIfNeeded(uid);
      _photoUrl = newPhotoUrl;

      final docData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'crmv': _crmvController.text.trim(),
        'email': _emailController.text.trim(),
        'type': _isIndividual ? 'PF' : 'PJ',
        'doc': _isIndividual
            ? _cpfController.text.trim()
            : _cnpjController.text.trim(),
        'responsibleCpf':
        _isIndividual ? null : _cpfController.text.trim(),
        'photoUrl': _photoUrl,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(docData);

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Erro ao salvar perfil: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar perfil. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipoLabel = _isIndividual ? 'Pessoa Física' : 'Pessoa Jurídica';

    Widget content;

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(color: ClickVetColors.gold),
      );
    } else if (_error != null) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(
                color: ClickVetColors.goldDark,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: ClickVetColors.gold,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    } else {

      Widget avatarChild;
      if (_pickedImage != null) {
        avatarChild = ClipOval(
          child: Image.file(
            File(_pickedImage!.path),
            fit: BoxFit.cover,
            width: 96,
            height: 96,
          ),
        );
      } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
        avatarChild = ClipOval(
          child: Image.network(
            _photoUrl!,
            fit: BoxFit.cover,
            width: 96,
            height: 96,
            errorBuilder: (_, __, ___) {
              return const Icon(
                Icons.person,
                color: Colors.white,
                size: 46,
              );
            },
          ),
        );
      } else {
        avatarChild = const Icon(
          Icons.person,
          color: Colors.white,
          size: 46,
        );
      }

      content = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFD4AF37), ClickVetColors.gold],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: avatarChild,
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pickImage,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.photo_camera_outlined,
                                size: 18,
                                color: ClickVetColors.goldDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ClickVetColors.gold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tipoLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _CardBase(
              title: 'Informações Profissionais',
              child: Column(
                children: [
                  _LabeledField(
                    label: 'CRMV',
                    icon: Icons.badge_outlined,
                    controller: _crmvController,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _CardBase(
              title: 'Informações Pessoais',
              child: Column(
                children: [
                  _LabeledField(
                    label: 'Nome Completo',
                    icon: Icons.person_outline,
                    controller: _nameController,
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: _isIndividual ? 'CPF' : 'CNPJ',
                    icon: Icons.credit_card,
                    controller:
                    _isIndividual ? _cpfController : _cnpjController,
                  ),
                  if (!_isIndividual) ...[
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'CPF do Responsável',
                      icon: Icons.person_outline,
                      controller: _cpfController,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            _CardBase(
              title: 'Contato',
              child: Column(
                children: [
                  _LabeledField(
                    label: 'Email',
                    icon: Icons.mail_outline,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: 'Telefone',
                    icon: Icons.phone,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _CardBase(
              title: 'Alterar Senha',
              trailing: TextButton(
                onPressed: () {
                  setState(() {
                    _showPasswordSection = !_showPasswordSection;
                    if (!_showPasswordSection) {
                      _currentPassController.clear();
                      _newPassController.clear();
                      _confirmPassController.clear();
                      _errorCurrentPass = null;
                      _errorNewPass = null;
                      _errorConfirmPass = null;
                    }
                  });
                },
                child: Text(
                  _showPasswordSection ? 'Cancelar' : 'Alterar',
                  style: const TextStyle(
                    color: ClickVetColors.goldDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              child: AnimatedCrossFade(
                crossFadeState: _showPasswordSection
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
                firstChild: Column(
                  children: [
                    _PasswordField(
                      label: 'Senha Atual',
                      controller: _currentPassController,
                      errorText: _errorCurrentPass,
                    ),
                    const SizedBox(height: 12),
                    _PasswordField(
                      label: 'Nova Senha',
                      controller: _newPassController,
                      errorText: _errorNewPass,
                    ),
                    const SizedBox(height: 12),
                    _PasswordField(
                      label: 'Confirmar Nova Senha',
                      controller: _confirmPassController,
                      errorText: _errorConfirmPass,
                    ),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), ClickVetColors.gold],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      offset: Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _handleSave();
                  },
                  icon: const Icon(
                    Icons.save_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'SALVAR ALTERAÇÕES',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: ClickVetColors.gold,
                    width: 1.6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: ClickVetColors.goldDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return VetScaffold(
      selectedKey: DrawerItemKey.profile,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: ClickVetColors.gold,
            fontWeight: FontWeight.w700,
          ),
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: ClickVetColors.goldDark,
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1.3,
            color: ClickVetColors.gold,
          ),
        ),
      ),
      body: Container(color: ClickVetColors.bg, child: content),
    );
  }
}


class _CardBase extends StatelessWidget {
  const _CardBase({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClickVetColors.gold, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ClickVetColors.goldDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: ClickVetColors.goldDark),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(
                color: ClickVetColors.gold,
                width: 1.4,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(
                color: ClickVetColors.goldDark,
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final borderColor =
    errorText == null ? ClickVetColors.gold : Colors.red.shade400;
    final focusedBorderColor =
    errorText == null ? ClickVetColors.goldDark : Colors.red.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: ClickVetColors.goldDark,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: borderColor,
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: focusedBorderColor,
                width: 1.6,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
