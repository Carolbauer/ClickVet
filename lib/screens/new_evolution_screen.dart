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

  // Controllers para dialogs
  final _vaccineNameCtrl = TextEditingController();
  final _vaccineDateCtrl = TextEditingController();
  final _vaccineNextDateCtrl = TextEditingController();
  final _vaccineBatchCtrl = TextEditingController();
  final _vaccineVetCtrl = TextEditingController();

  final _medNameCtrl = TextEditingController();
  final _medDosageCtrl = TextEditingController();
  final _medFrequencyCtrl = TextEditingController();
  final _medStartDateCtrl = TextEditingController();
  final _medEndDateCtrl = TextEditingController();

  final _examNameCtrl = TextEditingController();
  final _examDateCtrl = TextEditingController();
  final _examResultCtrl = TextEditingController();
  final _examNotesCtrl = TextEditingController();
  final _examVetCtrl = TextEditingController();

  final _surgeryNameCtrl = TextEditingController();
  final _surgeryDateCtrl = TextEditingController();
  final _surgeryVetCtrl = TextEditingController();
  final _surgeryNotesCtrl = TextEditingController();

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

    _vaccineNameCtrl.dispose();
    _vaccineDateCtrl.dispose();
    _vaccineNextDateCtrl.dispose();
    _vaccineBatchCtrl.dispose();
    _vaccineVetCtrl.dispose();

    _medNameCtrl.dispose();
    _medDosageCtrl.dispose();
    _medFrequencyCtrl.dispose();
    _medStartDateCtrl.dispose();
    _medEndDateCtrl.dispose();

    _examNameCtrl.dispose();
    _examDateCtrl.dispose();
    _examResultCtrl.dispose();
    _examNotesCtrl.dispose();
    _examVetCtrl.dispose();

    _surgeryNameCtrl.dispose();
    _surgeryDateCtrl.dispose();
    _surgeryVetCtrl.dispose();
    _surgeryNotesCtrl.dispose();

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


  String _fmtDateBr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDateForDialog(TextEditingController controller) async {
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
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: initialDate,
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
      controller.text = _fmtDateBr(picked);
    }
  }

  Future<void> _openVaccineDialog() async {
    _vaccineNameCtrl.clear();
    _vaccineDateCtrl.clear();
    _vaccineNextDateCtrl.clear();
    _vaccineBatchCtrl.clear();
    _vaccineVetCtrl.clear();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          titlePadding: const EdgeInsets.only(left: 20, right: 12, top: 18),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Adicionar Vacina',
                  style: TextStyle(
                    color: ClickVetColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registre uma nova vacina aplicada na consulta.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _vaccineNameCtrl,
                  decoration: _fieldDeco('Nome da Vacina *', icon: Icons.vaccines_outlined, hint: 'Ex: V10, Antirrábica...'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _vaccineDateCtrl,
                        readOnly: true,
                        decoration: _fieldDeco('Data de Aplicação *'),
                        onTap: () => _pickDateForDialog(_vaccineDateCtrl),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _vaccineNextDateCtrl,
                        readOnly: true,
                        decoration: _fieldDeco('Próxima Dose'),
                        onTap: () => _pickDateForDialog(_vaccineNextDateCtrl),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _vaccineBatchCtrl,
                  decoration: _fieldDeco('Lote', hint: 'Número do lote'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _vaccineVetCtrl,
                  decoration: _fieldDeco('Veterinário', hint: 'Nome do veterinário'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                final name = _vaccineNameCtrl.text.trim();
                final date = _vaccineDateCtrl.text.trim();
                if (name.isEmpty || date.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe nome da vacina e data de aplicação.')),
                  );
                  return;
                }
                final nextDate = _vaccineNextDateCtrl.text.trim();
                final batch = _vaccineBatchCtrl.text.trim();
                final vet = _vaccineVetCtrl.text.trim();
                final summary = [
                  name,
                  if (date.isNotEmpty) 'Aplicada: $date',
                  if (nextDate.isNotEmpty) 'Próxima: $nextDate',
                  if (batch.isNotEmpty) 'Lote: $batch',
                  if (vet.isNotEmpty) 'Vet: $vet',
                ].join(' • ');
                final current = _vaccinesSummary.isEmpty ? '' : '$_vaccinesSummary\n';
                _vaccinesSummary = '$current$summary';
                Navigator.of(ctx).pop();
                setState(() {});
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openMedicationDialog() async {
    _medNameCtrl.clear();
    _medDosageCtrl.clear();
    _medFrequencyCtrl.clear();
    _medStartDateCtrl.clear();
    _medEndDateCtrl.clear();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          titlePadding: const EdgeInsets.only(left: 20, right: 12, top: 18),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Adicionar Medicamento',
                  style: TextStyle(
                    color: ClickVetColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registre um medicamento prescrito na consulta.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _medNameCtrl,
                  decoration: _fieldDeco('Nome do Medicamento *', icon: Icons.medication_outlined, hint: 'Ex: Amoxicilina, Carprofeno...'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _medDosageCtrl,
                        decoration: _fieldDeco('Dosagem *', hint: 'Ex: 500mg'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _medFrequencyCtrl,
                        decoration: _fieldDeco('Frequência *', hint: 'Ex: 2x ao dia'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _medStartDateCtrl,
                        readOnly: true,
                        decoration: _fieldDeco('Data Início'),
                        onTap: () => _pickDateForDialog(_medStartDateCtrl),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _medEndDateCtrl,
                        readOnly: true,
                        decoration: _fieldDeco('Data Fim'),
                        onTap: () => _pickDateForDialog(_medEndDateCtrl),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                final name = _medNameCtrl.text.trim();
                final dosage = _medDosageCtrl.text.trim();
                final freq = _medFrequencyCtrl.text.trim();
                if (name.isEmpty || dosage.isEmpty || freq.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe nome, dosagem e frequência.')),
                  );
                  return;
                }
                final startDate = _medStartDateCtrl.text.trim();
                final endDate = _medEndDateCtrl.text.trim();
                final summary = [
                  name,
                  'Dosagem: $dosage',
                  'Frequência: $freq',
                  if (startDate.isNotEmpty) 'Início: $startDate',
                  if (endDate.isNotEmpty) 'Fim: $endDate',
                ].where((s) => s.isNotEmpty).join(' • ');
                final current = _prescriptionController.text.isEmpty ? '' : '${_prescriptionController.text}\n';
                _prescriptionController.text = '$current$summary';
                Navigator.of(ctx).pop();
                setState(() {});
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openExamDialog() async {
    _examNameCtrl.clear();
    _examDateCtrl.clear();
    _examResultCtrl.clear();
    _examNotesCtrl.clear();
    _examVetCtrl.clear();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          titlePadding: const EdgeInsets.only(left: 20, right: 12, top: 18),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Adicionar Exame',
                  style: TextStyle(
                    color: ClickVetColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registre um exame solicitado na consulta.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _examNameCtrl,
                  decoration: _fieldDeco('Nome do Exame *', icon: Icons.science_outlined, hint: 'Ex: Hemograma Completo, Ultrassom...'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _examDateCtrl,
                  readOnly: true,
                  decoration: _fieldDeco('Data do Exame *'),
                  onTap: () => _pickDateForDialog(_examDateCtrl),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _examResultCtrl,
                  decoration: _fieldDeco('Resultado', hint: 'Ex: Normal, Alterado...'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _examNotesCtrl,
                  maxLines: 3,
                  decoration: _areaDeco('Observações', hint: 'Detalhes sobre o exame...'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _examVetCtrl,
                  decoration: _fieldDeco('Veterinário Responsável', hint: 'Nome do veterinário'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                final name = _examNameCtrl.text.trim();
                final date = _examDateCtrl.text.trim();
                if (name.isEmpty || date.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe nome do exame e data.')),
                  );
                  return;
                }
                final result = _examResultCtrl.text.trim();
                final notes = _examNotesCtrl.text.trim();
                final vet = _examVetCtrl.text.trim();
                final summary = [
                  name,
                  'Data: $date',
                  if (result.isNotEmpty) 'Resultado: $result',
                  if (notes.isNotEmpty) notes,
                  if (vet.isNotEmpty) 'Vet: $vet',
                ].where((s) => s.isNotEmpty).join(' • ');
                final current = _examsSummary.isEmpty ? '' : '$_examsSummary\n';
                _examsSummary = '$current$summary';
                Navigator.of(ctx).pop();
                setState(() {});
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSurgeryDialog() async {
    _surgeryNameCtrl.clear();
    _surgeryDateCtrl.clear();
    _surgeryVetCtrl.clear();
    _surgeryNotesCtrl.clear();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          titlePadding: const EdgeInsets.only(left: 20, right: 12, top: 18),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Adicionar Cirurgia',
                  style: TextStyle(
                    color: ClickVetColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registre uma cirurgia realizada na consulta.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _surgeryNameCtrl,
                  decoration: _fieldDeco('Nome da Cirurgia *', icon: Icons.monitor_heart_outlined, hint: 'Ex: Castração, Remoção de tumor...'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _surgeryDateCtrl,
                  readOnly: true,
                  decoration: _fieldDeco('Data da Cirurgia *'),
                  onTap: () => _pickDateForDialog(_surgeryDateCtrl),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _surgeryVetCtrl,
                  decoration: _fieldDeco('Veterinário Responsável', hint: 'Nome do veterinário'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _surgeryNotesCtrl,
                  maxLines: 3,
                  decoration: _areaDeco('Observações', hint: 'Detalhes sobre a cirurgia e recuperação...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB2777),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                final name = _surgeryNameCtrl.text.trim();
                final date = _surgeryDateCtrl.text.trim();
                if (name.isEmpty || date.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe nome da cirurgia e data.')),
                  );
                  return;
                }
                final vet = _surgeryVetCtrl.text.trim();
                final notes = _surgeryNotesCtrl.text.trim();
                final summary = [
                  name,
                  'Data: $date',
                  if (vet.isNotEmpty) 'Vet: $vet',
                  if (notes.isNotEmpty) notes,
                ].where((s) => s.isNotEmpty).join(' • ');
                final current = _surgeriesSummary.isEmpty ? '' : '$_surgeriesSummary\n';
                _surgeriesSummary = '$current$summary';
                Navigator.of(ctx).pop();
                setState(() {});
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
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
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: ClickVetColors.gold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _openVaccineDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Adicionar Vacina',
                                  style: TextStyle(
                                    color: ClickVetColors.goldDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (_vaccinesSummary.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
                                ),
                                child: Text(
                                  _vaccinesSummary,
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        icon: Icons.medication_liquid_outlined,
                        title: 'Medicamentos Prescritos',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 44,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: ClickVetColors.gold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _openMedicationDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Adicionar Medicamento',
                                  style: TextStyle(
                                    color: ClickVetColors.goldDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (_prescriptionController.text.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                                ),
                                child: Text(
                                  _prescriptionController.text,
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ),
                            ],
                          ],
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
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: ClickVetColors.gold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _openExamDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Adicionar Exame',
                                  style: TextStyle(
                                    color: ClickVetColors.goldDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (_examsSummary.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.3)),
                                ),
                                child: Text(
                                  _examsSummary,
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
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
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: ClickVetColors.gold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _openSurgeryDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Adicionar Cirurgia',
                                  style: TextStyle(
                                    color: ClickVetColors.goldDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (_surgeriesSummary.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFDB2777).withOpacity(0.3)),
                                ),
                                child: Text(
                                  _surgeriesSummary,
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
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
