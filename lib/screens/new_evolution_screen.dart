import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/vet_scaffold.dart';
import 'package:app/widgets/app_drawer.dart';

class NewEvolutionScreen extends StatefulWidget {
  const NewEvolutionScreen({
    super.key,
    required this.petId,
    required this.petName,
    required this.petBreed,
    required this.tutorName,
  });

  final String petId;
  final String petName;
  final String petBreed;
  final String tutorName;

  @override
  State<NewEvolutionScreen> createState() => _NewEvolutionScreenState();
}

class _NewEvolutionScreenState extends State<NewEvolutionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  final _weightController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _respRateController = TextEditingController();

  final _chiefComplaintController = TextEditingController();
  final _anamnesisController = TextEditingController();
  final _physicalExamController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _notesController = TextEditingController();

  final _returnDateController = TextEditingController();

  String _vaccinesSummary = '';
  String _examsSummary = '';
  String _surgeriesSummary = '';

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _weightController.dispose();
    _temperatureController.dispose();
    _heartRateController.dispose();
    _respRateController.dispose();
    _chiefComplaintController.dispose();
    _anamnesisController.dispose();
    _physicalExamController.dispose();
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    _returnDateController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDeco(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: ClickVetColors.goldDark) : null,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  InputDecoration _areaDeco(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
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
      contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime initialDate = DateTime.now();

    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          initialDate = DateTime(year, month, day);
        }
      } catch (_) {

      }
    }

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: initialDate,
    );

    if (picked != null) {
      controller.text =
      '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }


  Future<void> _pickTime(TextEditingController controller) async {
    final now = TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx!).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text =
      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showSoon(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _editSimpleSummary({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSaved,
  }) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Digite aqui...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      onSaved(result);
      setState(() {});
    }
  }

  Future<void> _saveEvolution() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vet = FirebaseAuth.instance.currentUser;
    if (vet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final evolutionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(vet.uid)
          .collection('pets')
          .doc(widget.petId)
          .collection('evolutions');

      await evolutionsRef.add({
        'date': _dateController.text.trim(),
        'time': _timeController.text.trim(),
        'weight': _weightController.text.trim(),
        'temperature': _temperatureController.text.trim(),
        'heartRate': _heartRateController.text.trim(),
        'respRate': _respRateController.text.trim(),
        'chiefComplaint': _chiefComplaintController.text.trim(),
        'anamnesis': _anamnesisController.text.trim(),
        'physicalExam': _physicalExamController.text.trim(),
        'diagnosis': _diagnosisController.text.trim(),
        'prescription': _prescriptionController.text.trim(),
        'notes': _notesController.text.trim(),
        'returnDate': _returnDateController.text.trim(),
        'vaccinesSummary': _vaccinesSummary.trim(),
        'examsSummary': _examsSummary.trim(),
        'surgeriesSummary': _surgeriesSummary.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evolução salva com sucesso!')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar evolução: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VetScaffold(
      selectedKey: DrawerItemKey.agenda,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text(
          'Nova Evolução',
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
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Container(
        color: ClickVetColors.bg,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [ClickVetColors.goldLight, ClickVetColors.gold],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Paciente:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.petName} - ${widget.petBreed}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tutor: ${widget.tutorName}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _SectionCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'Data e Hora',
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dateController,
                                readOnly: true,
                                decoration: _fieldDeco('Data'),
                                onTap: () => _pickDate(_dateController),
                                validator: (v) =>
                                (v == null || v.isEmpty) ? 'Informe a data' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _timeController,
                                readOnly: true,
                                decoration: _fieldDeco('Horário'),
                                onTap: () => _pickTime(_timeController),
                                validator: (v) =>
                                (v == null || v.isEmpty) ? 'Informe o horário' : null,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        icon: Icons.monitor_heart_outlined,
                        title: 'Sinais Vitais',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _weightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: _fieldDeco('Peso (kg)', icon: Icons.pets),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _temperatureController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: _fieldDeco('Temperatura (°C)', icon: Icons.thermostat_outlined),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _heartRateController,
                                    keyboardType: TextInputType.number,
                                    decoration: _fieldDeco('Freq. Cardíaca (bpm)'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _respRateController,
                                    keyboardType: TextInputType.number,
                                    decoration: _fieldDeco('Freq. Respiratória (rpm)'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        icon: Icons.info_outline,
                        title: 'Queixa Principal',
                        child: TextFormField(
                          controller: _chiefComplaintController,
                          maxLines: 3,
                          decoration: _areaDeco('Queixa Principal', hint: 'Descreva o motivo da consulta...'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        icon: Icons.description_outlined,
                        title: 'Anamnese',
                        child: TextFormField(
                          controller: _anamnesisController,
                          maxLines: 3,
                          decoration: _areaDeco('Anamnese', hint: 'Histórico e evolução dos sintomas...'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        icon: Icons.favorite_border,
                        title: 'Exame Físico',
                        child: TextFormField(
                          controller: _physicalExamController,
                          maxLines: 3,
                          decoration: _areaDeco('Exame Físico', hint: 'Achados do exame físico...'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'Diagnóstico',
                        child: TextFormField(
                          controller: _diagnosisController,
                          maxLines: 2,
                          decoration: _areaDeco('Diagnóstico', hint: 'Diagnóstico clínico...'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        icon: Icons.medication_outlined,
                        title: 'Prescrição e Tratamento',
                        child: TextFormField(
                          controller: _prescriptionController,
                          maxLines: 3,
                          decoration: _areaDeco(
                            'Prescrição e Tratamento',
                            hint: 'Medicamentos, dosagens e instruções...',
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        icon: Icons.notes_outlined,
                        title: 'Observações Gerais',
                        child: TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: _areaDeco('Observações Gerais', hint: 'Observações adicionais...'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        icon: Icons.event_repeat_outlined,
                        title: 'Retorno',
                        child: TextFormField(
                          controller: _returnDateController,
                          readOnly: true,
                          decoration: _fieldDeco('Data do retorno (opcional)'),
                          onTap: () => _pickDate(_returnDateController),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        icon: Icons.vaccines_outlined,
                        title: 'Vacinas Aplicadas',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: ClickVetColors.gold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => _editSimpleSummary(
                                  title: 'Vacinas aplicadas',
                                  initialValue: _vaccinesSummary,
                                  onSaved: (value) => _vaccinesSummary = value,
                                ),
                                child: const Text(
                                  '+  Adicionar Vacina',
                                  style: TextStyle(
                                    color: ClickVetColors.goldDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (_vaccinesSummary.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _vaccinesSummary,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        icon: Icons.medication_liquid_outlined,
                        title: 'Medicamentos Prescritos',
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: ClickVetColors.gold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => _showSoon('Em breve: adicionar medicamento'),
                            child: const Text(
                              '+  Adicionar Medicamento',
                              style: TextStyle(
                                color: ClickVetColors.goldDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        icon: Icons.science_outlined,
                        title: 'Exames Solicitados',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: ClickVetColors.gold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => _editSimpleSummary(
                                  title: 'Exames solicitados',
                                  initialValue: _examsSummary,
                                  onSaved: (value) => _examsSummary = value,
                                ),
                                child: const Text(
                                  '+  Adicionar Exame',
                                  style: TextStyle(
                                    color: ClickVetColors.goldDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (_examsSummary.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _examsSummary,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        icon: Icons.monitor_heart_outlined,
                        title: 'Cirurgias Realizadas',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: ClickVetColors.gold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => _editSimpleSummary(
                                  title: 'Cirurgias realizadas',
                                  initialValue: _surgeriesSummary,
                                  onSaved: (value) => _surgeriesSummary = value,
                                ),
                                child: const Text(
                                  '+  Adicionar Cirurgia',
                                  style: TextStyle(
                                    color: ClickVetColors.goldDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (_surgeriesSummary.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _surgeriesSummary,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: ClickVetColors.gold, width: 1.6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [ClickVetColors.goldLight, ClickVetColors.gold],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
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
                                onPressed: _isSaving ? null : _saveEvolution,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(
                                  _isSaving ? 'Salvando...' : 'Salvar Evolução',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ClickVetColors.gold, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: ClickVetColors.goldDark),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: ClickVetColors.goldDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
