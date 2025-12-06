import 'dart:convert';

import 'package:app/widgets/app_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/clickvet_colors.dart';
import '../widgets/vet_scaffold.dart';

class EditTutorScreen extends StatefulWidget {
  final String tutorId;

  const EditTutorScreen({
    super.key,
    required this.tutorId,
  });

  @override
  State<EditTutorScreen> createState() => _EditTutorScreenState();
}

class _EditTutorScreenState extends State<EditTutorScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _rgController = TextEditingController();
  final _birthDateController = TextEditingController();

  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _cepController = TextEditingController();
  final _addressController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTutor();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _rgController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    _addressController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTutor() async {
    try {
      final vet = FirebaseAuth.instance.currentUser;
      if (vet == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
        );
        Navigator.of(context).pop();
        return;
      }

      debugPrint('Editando tutor: ${widget.tutorId}');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(vet.uid)
          .collection('tutors')
          .doc(widget.tutorId)
          .get();

      debugPrint('Tutor encontrado? ${doc.exists}');

      if (!doc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tutor não encontrado.')),
        );
        Navigator.of(context).pop();
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      debugPrint('Dados do tutor: $data');

      _nameController.text = (data['name'] ?? '').toString();
      _cpfController.text = (data['cpf'] ?? data['doc'] ?? '').toString();
      _phoneController.text = (data['phone'] ?? '').toString();
      _emailController.text = (data['email'] ?? '').toString();

      _rgController.text = (data['rg'] ?? '').toString();
      _birthDateController.text = (data['birthDate'] ?? '').toString();

      _cepController.text = (data['cep'] ?? '').toString();
      _addressController.text = (data['address'] ?? '').toString();
      _numberController.text = (data['number'] ?? '').toString();
      _complementController.text = (data['complement'] ?? '').toString();
      _neighborhoodController.text = (data['neighborhood'] ?? '').toString();
      _cityController.text = (data['city'] ?? '').toString();
      _stateController.text = (data['state'] ?? '').toString();

      _notesController.text = (data['notes'] ?? '').toString();
      _altPhoneController.text =
          (data['alternativePhone'] ?? '').toString();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar tutor: $e')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final vet = FirebaseAuth.instance.currentUser;
      if (vet == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
        );
        Navigator.of(context).pop();
        return;
      }

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(vet.uid)
          .collection('tutors')
          .doc(widget.tutorId);

      await docRef.update({
        'name': _nameController.text.trim(),

        'cpf': _cpfController.text.trim(),
        'doc': _cpfController.text.trim(),

        'phone': _phoneController.text.trim(),
        'alternativePhone': _altPhoneController.text.trim(),
        'email': _emailController.text.trim(),

        'cep': _cepController.text.trim(),
        'address': _addressController.text.trim(),
        'number': _numberController.text.trim(),
        'complement': _complementController.text.trim(),
        'neighborhood': _neighborhoodController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),

        'rg': _rgController.text.trim(),
        'birthDate': _birthDateController.text.trim(),
        'notes': _notesController.text.trim(),

        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutor atualizado com sucesso!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar tutor: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _buscarCEP() async {
    final cep = _cepController.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) return;

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['erro'] == true) return;

        setState(() {
          _addressController.text = (data['logradouro'] ?? '').toString();
          _neighborhoodController.text = (data['bairro'] ?? '').toString();
          _cityController.text = (data['localidade'] ?? '').toString();
          _stateController.text = (data['uf'] ?? '').toString();
        });
      }
    } catch (_) {

    }
  }

  @override
  Widget build(BuildContext context) {
    final vet = FirebaseAuth.instance.currentUser;
    if (vet == null) {
      return const Scaffold(
        backgroundColor: ClickVetColors.bg,
        body: Center(
          child: Text('Sessão expirada. Faça login novamente.'),
        ),
      );
    }

    return VetScaffold(
      selectedKey: DrawerItemKey.tutors,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text(
          'Editar Tutor',
          style: TextStyle(
            color: ClickVetColors.goldDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ClickVetColors.goldDark,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: ClickVetColors.bg,
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: ClickVetColors.gold,
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildPersonalCard(),
                const SizedBox(height: 16),
                _buildContactCard(),
                const SizedBox(height: 16),
                _buildAddressCard(),
                const SizedBox(height: 16),
                _buildNotesCard(),
                const SizedBox(height: 24),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ClickVetColors.gold, width: 1.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: ClickVetColors.goldDark),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: ClickVetColors.goldDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      counterText: '',
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: ClickVetColors.gold,
          width: 1.8,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: ClickVetColors.goldDark,
          width: 2,
        ),
      ),
    );
  }

  Widget _textField(
      String label,
      TextEditingController controller, {
        String? hint,
        String? Function(String?)? validator,
        TextInputType? keyboard,
        int? maxLength,
        VoidCallback? onEditingComplete,
      }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ClickVetColors.goldDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboard,
            maxLength: maxLength,
            onEditingComplete: onEditingComplete,
            decoration: _inputDecoration(hint: hint),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.person_outline, 'Informações Pessoais'),
          _textField(
            'Nome Completo *',
            _nameController,
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
          ),
          _textField(
            'CPF *',
            _cpfController,
            hint: '000.000.000-00',
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Informe o CPF' : null,
          ),
          _textField(
            'RG',
            _rgController,
            hint: '00.000.000-0',
          ),
          _textField(
            'Data de Nascimento',
            _birthDateController,
            hint: 'AAAA-MM-DD',
            keyboard: TextInputType.datetime,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.phone_outlined, 'Contato'),
          _textField(
            'Telefone Principal *',
            _phoneController,
            hint: '(00) 00000-0000',
            keyboard: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Informe o telefone principal'
                : null,
          ),
          _textField(
            'Telefone Alternativo',
            _altPhoneController,
            hint: '(00) 0000-0000',
            keyboard: TextInputType.phone,
          ),
          _textField(
            'E-mail *',
            _emailController,
            hint: 'email@exemplo.com',
            keyboard: TextInputType.emailAddress,
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Informe o e-mail' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.location_on_outlined, 'Endereço'),
          _textField(
            'CEP',
            _cepController,
            hint: '00000-000',
            keyboard: TextInputType.number,
            onEditingComplete: _buscarCEP,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Digite o CEP para preencher automaticamente.',
              style: TextStyle(
                fontSize: 12,
                color: ClickVetColors.goldDark,
              ),
            ),
          ),
          _textField(
            'Logradouro *',
            _addressController,
            hint: 'Rua, Avenida, etc.',
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Informe o logradouro'
                : null,
          ),
          _textField(
            'Número *',
            _numberController,
            hint: '123',
            keyboard: TextInputType.number,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Informe o número'
                : null,
          ),
          _textField(
            'Complemento',
            _complementController,
            hint: 'Apto, Bloco, etc.',
          ),
          _textField(
            'Bairro *',
            _neighborhoodController,
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Informe o bairro' : null,
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _textField(
                  'Cidade *',
                  _cityController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe a cidade'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(
                  'UF *',
                  _stateController,
                  maxLength: 2,
                  hint: 'SP',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe a UF'
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.notes_outlined, 'Observações'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: _inputDecoration(
              hint: 'Preferências de atendimento, informações adicionais...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: ClickVetColors.gold,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              'Salvar Alterações',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: ClickVetColors.gold),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
    );
  }
}
