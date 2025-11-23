import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/clickvet_colors.dart';
import '../widgets/vet_scaffold.dart';
import '../widgets/app_drawer.dart';

class NewScheduleScreen extends StatefulWidget {
  const NewScheduleScreen({super.key});
  static const routeName = '/new-schedule';

  @override
  State<NewScheduleScreen> createState() => _NewScheduleScreenState();
}

class _NewScheduleScreenState extends State<NewScheduleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _petSearchCtrl = TextEditingController();
  final _petSearchFocus = FocusNode();
  String _petQuery = '';
  bool _showPetList = false;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _tipoConsulta;
  String? _vetId;
  bool _reminder = false;
  bool _isSaving = false;

  final List<TextEditingController> _proceduresCtrls = [];

  DocumentSnapshot<Map<String, dynamic>>? _selectedPet;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _petSearchCtrl.dispose();
    _petSearchFocus.dispose();
    for (final c in _proceduresCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _petsStream(String vetUid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(vetUid)
        .collection('pets')
        .orderBy('name')
        .snapshots();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (_, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ClickVetColors.gold,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (_, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ClickVetColors.gold,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _addProcedure() {
    setState(() {
      _proceduresCtrls.add(TextEditingController());
    });
  }

  void _removeProcedure(int i) {
    setState(() {
      _proceduresCtrls[i].dispose();
      _proceduresCtrls.removeAt(i);
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um paciente.')),
      );
      return;
    }

    final vet = FirebaseAuth.instance.currentUser;
    if (vet == null) return;

    setState(() => _isSaving = true);

    try {
      final petData = _selectedPet!.data()!;

      final petId = _selectedPet!.id;
      final petName = (petData['name'] ?? '').toString();
      final petBreed = (petData['breed'] ?? '').toString();

      final tutorId = (petData['tutorId'] ?? petData['tutor_id'] ?? '').toString();
      final tutorName = (petData['tutorName'] ?? petData['tutor_name'] ?? '').toString();

      final procedures = _proceduresCtrls
          .map((c) => c.text.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      final date = _selectedDate!;
      final time = _selectedTime!;
      final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

      final payload = {
        'petId': petId,
        'petName': petName,
        'petBreed': petBreed,
        'tutorId': tutorId,
        'tutorName': tutorName,
        'date': Timestamp.fromDate(dateTime),
        'time': _fmtTime(time),
        'tipoConsulta': _tipoConsulta,
        'vetId': _vetId ?? vet.uid,
        'vetName': null, // opcional, se quiser gravar o nome do vet logado
        'procedures': procedures,
        'reminder': _reminder,
        'status': 'Pendente',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(vet.uid)
          .collection('appointments')
          .add(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consulta agendada com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao agendar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _deco(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: ClickVetColors.gold) : null,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ClickVetColors.gold, width: 1.6),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ClickVetColors.goldDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vet = FirebaseAuth.instance.currentUser;
    if (vet == null) {
      return const Scaffold(
        backgroundColor: ClickVetColors.bg,
        body: Center(child: Text('Sessão expirada.')),
      );
    }

    return VetScaffold(
      selectedKey: DrawerItemKey.newSchedule,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text(
          'Novo Agendamento',
          style: TextStyle(color: ClickVetColors.gold, fontWeight: FontWeight.w700),
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ClickVetColors.goldDark),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _petsStream(vet.uid),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];

            final filteredPets = docs.where((d) {
              if (_petQuery.isEmpty) return true;
              final m = d.data();
              final petName = (m['name'] ?? '').toString().toLowerCase();
              final tutorName = (m['tutorName'] ?? m['tutor_name'] ?? '').toString().toLowerCase();
              return petName.contains(_petQuery) || tutorName.contains(_petQuery);
            }).toList();

            return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      TextField(
                      controller: _petSearchCtrl,
                      focusNode: _petSearchFocus,
                      onChanged: (v) {
                        setState(() {
                          _petQuery = v.trim().toLowerCase();
                          _showPetList = true;
                        });
                      },
                      onTap: () {
                        setState(() => _showPetList = true);
                      },
                      decoration: _deco(
                        'Selecionar Paciente',
                        icon: Icons.search,
                        hint: 'Buscar pacientes...',
                      ),
                    ),

                    if (_showPetList && _petQuery.isNotEmpty) ...[
                const SizedBox(height: 8),
            Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: ClickVetColors.gold, width: 1.4),
            borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
            shrinkWrap: true,
            itemCount: filteredPets.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
            final d = filteredPets[i];
            final m = d.data();
            final petName = m['name'] ?? '—';
            final breed = m['breed'] ?? '—';
            final tutorName = m['tutorName'] ?? m['tutor_name'] ?? '—';

            return ListTile(
            title: Text(petName),
            subtitle: Text('$breed • Tutor: $tutorName'),
            onTap: () {
            setState(() {
            _selectedPet = d;
            _petSearchCtrl.text = petName.toString();
            _petQuery = '';
            _showPetList = false;
            });
            FocusScope.of(context).unfocus();
            },
            );
            },
            ),
            ),
            ],

            const SizedBox(height: 12),
                        if (_selectedPet != null) ...[
                          Builder(
                            builder: (context) {
                              final m = _selectedPet!.data()!;
                              final tutorName = m['tutorName'] ?? m['tutor_name'] ?? '—';

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: ClickVetColors.gold, width: 1.4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.pets, color: ClickVetColors.goldDark),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m['name'] ?? '—',
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                          Text(m['breed'] ?? '—'),
                                          Text(
                                            'Tutor: $tutorName',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

            Row(
            children: [
            Expanded(
            child: InkWell(
            onTap: _pickDate,
            child: InputDecorator(
            decoration: _deco('Data', icon: Icons.calendar_month),
            child: Text(_selectedDate != null
            ? _fmtDate(_selectedDate!)
                : 'Selecionar'),
            ),
            ),
            ),
            const SizedBox(width: 12),
            Expanded(
            child: InkWell(
            onTap: _pickTime,
            child: InputDecorator(
            decoration: _deco('Horário', icon: Icons.access_time),
            child: Text(_selectedTime != null
            ? _fmtTime(_selectedTime!)
                : 'Selecionar'),
            ),
            ),
            ),
            ],
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
            value: _tipoConsulta,
            decoration: _deco('Tipo de Consulta', icon: Icons.article_outlined),
            items: const [
            DropdownMenuItem(value: 'rotina', child: Text('Consulta de Rotina')),
            DropdownMenuItem(value: 'vacinacao', child: Text('Vacinação')),
            DropdownMenuItem(value: 'emergencia', child: Text('Emergência')),
            DropdownMenuItem(value: 'exame', child: Text('Exame')),
            DropdownMenuItem(value: 'cirurgia', child: Text('Cirurgia')),
            DropdownMenuItem(value: 'retorno', child: Text('Retorno')),
            ],
            onChanged: (v) => setState(() => _tipoConsulta = v),
            validator: (v) => (v == null || v.isEmpty)
            ? 'Selecione o tipo de Atendimento'
                : null,
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
            value: _vetId ?? vet.uid,
            decoration: _deco('Veterinário', icon: Icons.person_outline),
            items: [
            DropdownMenuItem(
            value: vet.uid,
            child: const Text('Veterinário logado'),
            ),
            ],
            onChanged: (v) => setState(() => _vetId = v),
            ),

            const SizedBox(height: 16),

            Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: ClickVetColors.gold, width: 1.4),
            borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Row(
            children: const [
            Icon(Icons.add_box_outlined, color: ClickVetColors.goldDark),
            SizedBox(width: 8),
            Text('Procedimentos',
            style: TextStyle(fontWeight: FontWeight.w700)),
            ],
            ),
            const SizedBox(height: 8),

            for (int i = 0; i < _proceduresCtrls.length; i++) ...[
            Row(
            children: [
            Expanded(
            child: TextFormField(
            controller: _proceduresCtrls[i],
            decoration: _deco('Procedimento ${i + 1}'),
            ),
            ),
            const SizedBox(width: 6),
            IconButton(
            onPressed: () => _removeProcedure(i),
            icon: const Icon(Icons.delete_outline,
            color: Colors.redAccent),
            ),
            ],
            ),
            const SizedBox(height: 8),
            ],

            OutlinedButton.icon(
            onPressed: _addProcedure,
            icon: const Icon(Icons.add, color: ClickVetColors.goldDark),
            label: const Text('Adicionar Procedimento',
            style: TextStyle(color: ClickVetColors.goldDark)),
            style: OutlinedButton.styleFrom(
            side: const BorderSide(color: ClickVetColors.gold),
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            ),
            ),
            ),
            ],
            ),
            ),

            const SizedBox(height: 16),

            Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: ClickVetColors.gold, width: 1.4),
            borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
            children: [
            Checkbox(
            value: _reminder,
            onChanged: (v) => setState(() => _reminder = v ?? false),
            activeColor: ClickVetColors.gold,
            ),
            const Expanded(
            child: Text('Lembrete por SMS/WhatsApp'),
            )
            ],
            ),
            ),

            const SizedBox(height: 20),

            Row(
            children: [
            Expanded(
            child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              backgroundColor: ClickVetColors.white,
            side: const BorderSide(color: ClickVetColors.gold),
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size.fromHeight(52),
            ),
            child: const Text(
            'Cancelar',
            style: TextStyle(color: ClickVetColors.goldDark),
            ),
            ),
            ),
            const SizedBox(width: 12),
            Expanded(
            child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
            backgroundColor: ClickVetColors.gold,
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size.fromHeight(52),
            ),
            child: _isSaving
            ? const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            )
                : const Text(
            'Agendar',
            style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            ),
            ),
            ),
            ),
            ],
            ),
            ],
            ),
            ),
            );
          },
        ),
      ),
    );
  }
}
