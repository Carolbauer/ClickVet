import 'package:app/screens/new_evolution_screen.dart';
import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/vet_scaffold.dart';
import 'package:app/widgets/app_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MedicalRecordScreen extends StatefulWidget {
  final String petId;

  const MedicalRecordScreen({
    super.key,
    required this.petId,
  });

  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  // --- CONTROLLERS / ESTADO DO POPUP DE ALERGIA ---
  final TextEditingController _allergyNameCtrl = TextEditingController();
  final TextEditingController _allergyNotesCtrl = TextEditingController();
  String _allergySeverity = 'Moderada';
  bool _savingAllergy = false;

  // --- CONTROLLERS / ESTADO DO POPUP DE VACINA ---
  final TextEditingController _vaccineNameCtrl = TextEditingController();
  final TextEditingController _vaccineBatchCtrl = TextEditingController();
  final TextEditingController _vaccineVetCtrl = TextEditingController();
  DateTime? _vaccineDate;
  DateTime? _vaccineNextDate;
  bool _savingVaccine = false;

  // --- CONTROLLERS / ESTADO DO POPUP DE MEDICAMENTO ---
  final TextEditingController _medNameCtrl = TextEditingController();
  final TextEditingController _medDosageCtrl = TextEditingController();
  final TextEditingController _medFrequencyCtrl = TextEditingController();
  DateTime? _medStartDate;
  DateTime? _medEndDate;
  bool _savingMedication = false;

  // --- CONTROLLERS / ESTADO DO POPUP DE EXAME ---
  final TextEditingController _examNameCtrl = TextEditingController();
  final TextEditingController _examResultCtrl = TextEditingController();
  final TextEditingController _examNotesCtrl = TextEditingController();
  final TextEditingController _examVetCtrl = TextEditingController();
  DateTime? _examDate;
  bool _savingExam = false;

  // --- CONTROLLERS / ESTADO DO POPUP DE CIRURGIA ---
  final TextEditingController _surgeryNameCtrl = TextEditingController();
  final TextEditingController _surgeryDescriptionCtrl = TextEditingController();
  final TextEditingController _surgeryVetCtrl = TextEditingController();
  DateTime? _surgeryDate;
  bool _savingSurgery = false;

  // --- CONTROLLERS / ESTADO DO POPUP DE PESO ---
  final TextEditingController _weightCtrl = TextEditingController();
  DateTime? _weightDate;
  bool _savingWeight = false;

  @override
  void dispose() {
    _allergyNameCtrl.dispose();
    _allergyNotesCtrl.dispose();
    _vaccineNameCtrl.dispose();
    _vaccineBatchCtrl.dispose();
    _vaccineVetCtrl.dispose();

    _medNameCtrl.dispose();
    _medDosageCtrl.dispose();
    _medFrequencyCtrl.dispose();

    _examNameCtrl.dispose();
    _examResultCtrl.dispose();
    _examNotesCtrl.dispose();
    _examVetCtrl.dispose();

    _surgeryNameCtrl.dispose();
    _surgeryDescriptionCtrl.dispose();
    _surgeryVetCtrl.dispose();

    _weightCtrl.dispose();

    super.dispose();
  }

  String _ageFrom(dynamic v) {
    if (v == null) return '—';
    if (v is String && v.isNotEmpty && !v.contains('-')) {
      return v;
    }
    if (v is Timestamp) {
      final birth = v.toDate();
      final now = DateTime.now();
      int years = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        years--;
      }
      if (years < 0) years = 0;
      if (years == 0) return 'Filhote';
      if (years == 1) return '1 ano';
      return '$years anos';
    }
    return v.toString();
  }

  String _fmtDateBr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<DateTime?> _pickDate(BuildContext context, {DateTime? initial}) async {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
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
  }

  // --------- DIALOG DE ALERGIA ---------
  Future<void> _openAllergyDialog({
    required String vetUid,
  }) async {
    _allergyNameCtrl.clear();
    _allergyNotesCtrl.clear();
    _allergySeverity = 'Moderada';
    setState(() {});

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              titlePadding:
              const EdgeInsets.only(left: 20, right: 12, top: 18),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Adicionar Nova Alergia',
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
                      'Registre uma nova alergia no prontuário do pet.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Nome da Alergia *',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _allergyNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ex: Frango, Dipirona...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Gravidade *',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: ClickVetColors.gold,
                          width: 2,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _allergySeverity,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'Leve',
                              child: Text('Leve'),
                            ),
                            DropdownMenuItem(
                              value: 'Moderada',
                              child: Text('Moderada'),
                            ),
                            DropdownMenuItem(
                              value: 'Alta',
                              child: Text('Alta'),
                            ),
                            DropdownMenuItem(
                              value: 'Grave',
                              child: Text('Grave'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setLocalState(() {
                              _allergySeverity = v;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Observações',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _allergyNotesCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Descreva os sintomas ou reações...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(
                  right: 16, left: 16, bottom: 12, top: 4),
              actions: [
                TextButton(
                  onPressed: _savingAllergy
                      ? null
                      : () {
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _savingAllergy
                      ? null
                      : () async {
                    final name = _allergyNameCtrl.text.trim();
                    final notes = _allergyNotesCtrl.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Informe o nome da alergia.'),
                        ),
                      );
                      return;
                    }

                    try {
                      setLocalState(() {
                        _savingAllergy = true;
                      });

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(vetUid)
                          .collection('pets')
                          .doc(widget.petId)
                          .collection('allergies')
                          .add({
                        'name': name,
                        'severity': _allergySeverity,
                        'notes': notes,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (!mounted) return;
                      Navigator.of(ctx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Alergia salva com sucesso!'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                          Text('Erro ao salvar alergia: $e'),
                        ),
                      );
                    } finally {
                      setLocalState(() {
                        _savingAllergy = false;
                      });
                    }
                  },
                  child: _savingAllergy
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Salvar Alergia'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --------- DIALOG DE VACINA ---------
  Future<void> _openVaccineDialog({
    required String vetUid,
  }) async {
    _vaccineNameCtrl.clear();
    _vaccineBatchCtrl.clear();
    _vaccineVetCtrl.clear();
    _vaccineDate = null;
    _vaccineNextDate = null;
    setState(() {});

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            Future<void> pickDate(bool isNext) async {
              final picked = await _pickDate(ctx,
                  initial: isNext ? _vaccineNextDate : _vaccineDate);
              if (picked != null) {
                setLocalState(() {
                  if (isNext) {
                    _vaccineNextDate = picked;
                  } else {
                    _vaccineDate = picked;
                  }
                });
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              titlePadding:
              const EdgeInsets.only(left: 20, right: 12, top: 18),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Adicionar Nova Vacina',
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
                      'Registre uma nova vacina aplicada no pet.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Nome da Vacina *',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _vaccineNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ex: V10, Antirrábica...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data de Aplicação *',
                                style: TextStyle(
                                  color: ClickVetColors.goldDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => pickDate(false),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: ClickVetColors.gold,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: ClickVetColors.gold,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _vaccineDate == null
                                        ? 'Selecionar'
                                        : _fmtDateBr(_vaccineDate!),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _vaccineDate == null
                                          ? Colors.black45
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Próxima Dose',
                                style: TextStyle(
                                  color: ClickVetColors.goldDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => pickDate(true),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: ClickVetColors.gold,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: ClickVetColors.gold,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _vaccineNextDate == null
                                        ? 'Opcional'
                                        : _fmtDateBr(_vaccineNextDate!),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _vaccineNextDate == null
                                          ? Colors.black45
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Lote',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _vaccineBatchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Número do lote',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Veterinário',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _vaccineVetCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nome do veterinário',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(
                  right: 16, left: 16, bottom: 12, top: 4),
              actions: [
                TextButton(
                  onPressed: _savingVaccine
                      ? null
                      : () {
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _savingVaccine
                      ? null
                      : () async {
                    final name = _vaccineNameCtrl.text.trim();
                    if (name.isEmpty || _vaccineDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Informe nome da vacina e data de aplicação.'),
                        ),
                      );
                      return;
                    }

                    final batch = _vaccineBatchCtrl.text.trim();
                    final vetName = _vaccineVetCtrl.text.trim();

                    try {
                      setLocalState(() {
                        _savingVaccine = true;
                      });

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(vetUid)
                          .collection('pets')
                          .doc(widget.petId)
                          .collection('vaccines')
                          .add({
                        'name': name,
                        'date': Timestamp.fromDate(_vaccineDate!),
                        'dateStr': _fmtDateBr(_vaccineDate!),
                        'nextDate': _vaccineNextDate == null
                            ? null
                            : Timestamp.fromDate(_vaccineNextDate!),
                        'nextDateStr': _vaccineNextDate == null
                            ? ''
                            : _fmtDateBr(_vaccineNextDate!),
                        'batch': batch,
                        'veterinarian': vetName,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (!mounted) return;
                      Navigator.of(ctx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vacina salva com sucesso!'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao salvar vacina: $e'),
                        ),
                      );
                    } finally {
                      setLocalState(() {
                        _savingVaccine = false;
                      });
                    }
                  },
                  child: _savingVaccine
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Salvar Vacina'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --------- DIALOG DE MEDICAMENTO ---------
  Future<void> _openMedicationDialog({
    required String vetUid,
  }) async {
    _medNameCtrl.clear();
    _medDosageCtrl.clear();
    _medFrequencyCtrl.clear();
    _medStartDate = null;
    _medEndDate = null;
    setState(() {});

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            Future<void> pickDate(bool isEnd) async {
              final picked = await _pickDate(
                ctx,
                initial: isEnd ? _medEndDate : _medStartDate,
              );
              if (picked != null) {
                setLocalState(() {
                  if (isEnd) {
                    _medEndDate = picked;
                  } else {
                    _medStartDate = picked;
                  }
                });
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              titlePadding:
              const EdgeInsets.only(left: 20, right: 12, top: 18),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Adicionar Novo Medicamento',
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
                      'Registre um medicamento prescrito para o pet.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Nome do Medicamento *',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _medNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ex: Amoxicilina, Carprofeno...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dosagem *',
                                style: TextStyle(
                                  color: ClickVetColors.goldDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _medDosageCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Ex: 500mg',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: ClickVetColors.gold,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: ClickVetColors.gold,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: ClickVetColors.goldDark,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Frequência *',
                                style: TextStyle(
                                  color: ClickVetColors.goldDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _medFrequencyCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Ex: 2x ao dia',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: ClickVetColors.gold,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: ClickVetColors.gold,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: ClickVetColors.goldDark,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data Início',
                                style: TextStyle(
                                  color: ClickVetColors.goldDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => pickDate(false),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: ClickVetColors.gold,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: ClickVetColors.gold,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _medStartDate == null
                                        ? 'Opcional'
                                        : _fmtDateBr(_medStartDate!),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _medStartDate == null
                                          ? Colors.black45
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data Fim',
                                style: TextStyle(
                                  color: ClickVetColors.goldDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => pickDate(true),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: ClickVetColors.gold,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: ClickVetColors.gold,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _medEndDate == null
                                        ? 'Opcional'
                                        : _fmtDateBr(_medEndDate!),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _medEndDate == null
                                          ? Colors.black45
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(
                  right: 16, left: 16, bottom: 12, top: 4),
              actions: [
                TextButton(
                  onPressed: _savingMedication
                      ? null
                      : () {
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _savingMedication
                      ? null
                      : () async {
                    final name = _medNameCtrl.text.trim();
                    final dosage = _medDosageCtrl.text.trim();
                    final freq = _medFrequencyCtrl.text.trim();

                    if (name.isEmpty || dosage.isEmpty || freq.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Informe nome, dosagem e frequência do medicamento.'),
                        ),
                      );
                      return;
                    }

                    try {
                      setLocalState(() {
                        _savingMedication = true;
                      });

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(vetUid)
                          .collection('pets')
                          .doc(widget.petId)
                          .collection('medications')
                          .add({
                        'name': name,
                        'dosage': dosage,
                        'frequency': freq,
                        'startDate': _medStartDate == null
                            ? null
                            : Timestamp.fromDate(_medStartDate!),
                        'startDateStr': _medStartDate == null
                            ? ''
                            : _fmtDateBr(_medStartDate!),
                        'endDate': _medEndDate == null
                            ? null
                            : Timestamp.fromDate(_medEndDate!),
                        'endDateStr': _medEndDate == null
                            ? ''
                            : _fmtDateBr(_medEndDate!),
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (!mounted) return;
                      Navigator.of(ctx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                          Text('Medicamento salvo com sucesso!'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                          Text('Erro ao salvar medicamento: $e'),
                        ),
                      );
                    } finally {
                      setLocalState(() {
                        _savingMedication = false;
                      });
                    }
                  },
                  child: _savingMedication
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Salvar Medicamento'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // --------- DIALOG DE EXAME ---------
  Future<void> _openExamDialog({
    required String vetUid,
  }) async {
    _examNameCtrl.clear();
    _examResultCtrl.clear();
    _examNotesCtrl.clear();
    _examVetCtrl.clear();
    _examDate = null;
    setState(() {});

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            Future<void> pickExamDate() async {
              final picked = await _pickDate(ctx, initial: _examDate);
              if (picked != null) {
                setLocalState(() {
                  _examDate = picked;
                });
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              titlePadding:
              const EdgeInsets.only(left: 20, right: 12, top: 18),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Adicionar Novo Exame',
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
                      'Registre um novo exame realizado para o pet.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Nome do Exame *',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _examNameCtrl,
                      decoration: InputDecoration(
                        hintText:
                        'Ex: Hemograma Completo, Ultrassom Abdominal...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Data do Exame *',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: pickExamDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: ClickVetColors.gold,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: ClickVetColors.gold,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          _examDate == null
                              ? 'Selecionar'
                              : _fmtDateBr(_examDate!),
                          style: TextStyle(
                            fontSize: 13,
                            color: _examDate == null
                                ? Colors.black45
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Resultado *',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _examResultCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ex: Normal, Alterado...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Observações',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _examNotesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Detalhes sobre o exame...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Veterinário Responsável',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _examVetCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nome do veterinário',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(
                right: 16,
                left: 16,
                bottom: 12,
                top: 4,
              ),
              actions: [
                TextButton(
                  onPressed: _savingExam
                      ? null
                      : () {
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _savingExam
                      ? null
                      : () async {
                    final name = _examNameCtrl.text.trim();
                    final result = _examResultCtrl.text.trim();
                    final notes = _examNotesCtrl.text.trim();
                    final vetName = _examVetCtrl.text.trim();

                    if (name.isEmpty ||
                        _examDate == null ||
                        result.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Informe nome do exame, data e resultado.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      setLocalState(() {
                        _savingExam = true;
                      });

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(vetUid)
                          .collection('pets')
                          .doc(widget.petId)
                          .collection('exams')
                          .add({
                        'name': name,
                        'date': Timestamp.fromDate(_examDate!),
                        'dateStr': _fmtDateBr(_examDate!),
                        'result': result,
                        'notes': notes,
                        'veterinarian': vetName,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (!mounted) return;
                      Navigator.of(ctx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Exame salvo com sucesso!'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao salvar exame: $e'),
                        ),
                      );
                    } finally {
                      setLocalState(() {
                        _savingExam = false;
                      });
                    }
                  },
                  child: _savingExam
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Salvar Exame'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --------- DIALOG DE CIRURGIA ---------
  Future<void> _openSurgeryDialog({
    required String vetUid,
  }) async {
    _surgeryNameCtrl.clear();
    _surgeryDescriptionCtrl.clear();
    _surgeryVetCtrl.clear();
    _surgeryDate = null;
    setState(() {});

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            Future<void> pickSurgeryDate() async {
              final picked = await _pickDate(ctx, initial: _surgeryDate);
              if (picked != null) {
                setLocalState(() {
                  _surgeryDate = picked;
                });
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              titlePadding:
                  const EdgeInsets.only(left: 20, right: 12, top: 18),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Adicionar Nova Cirurgia',
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
                      'Registre uma nova cirurgia realizada no pet.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Nome da Cirurgia *',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _surgeryNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ex: Castração, Ovariohisterectomia...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Data da Cirurgia *',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: pickSurgeryDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: ClickVetColors.gold,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: ClickVetColors.gold,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          _surgeryDate == null
                              ? 'Selecionar'
                              : _fmtDateBr(_surgeryDate!),
                          style: TextStyle(
                            fontSize: 13,
                            color: _surgeryDate == null
                                ? Colors.black45
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Descrição',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _surgeryDescriptionCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Detalhes sobre a cirurgia...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Veterinário Responsável',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _surgeryVetCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nome do veterinário',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(
                right: 16,
                left: 16,
                bottom: 12,
                top: 4,
              ),
              actions: [
                TextButton(
                  onPressed: _savingSurgery
                      ? null
                      : () {
                          Navigator.of(ctx).pop();
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDB2777),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _savingSurgery
                      ? null
                      : () async {
                          final name = _surgeryNameCtrl.text.trim();
                          final description =
                              _surgeryDescriptionCtrl.text.trim();
                          final vetName = _surgeryVetCtrl.text.trim();

                          if (name.isEmpty || _surgeryDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Informe nome da cirurgia e data.',
                                ),
                              ),
                            );
                            return;
                          }

                          try {
                            setLocalState(() {
                              _savingSurgery = true;
                            });

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(vetUid)
                                .collection('pets')
                                .doc(widget.petId)
                                .collection('surgeries')
                                .add({
                              'name': name,
                              'date': Timestamp.fromDate(_surgeryDate!),
                              'dateStr': _fmtDateBr(_surgeryDate!),
                              'description': description,
                              'veterinarian': vetName,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (!mounted) return;
                            Navigator.of(ctx).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cirurgia salva com sucesso!'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao salvar cirurgia: $e'),
                              ),
                            );
                          } finally {
                            setLocalState(() {
                              _savingSurgery = false;
                            });
                          }
                        },
                  child: _savingSurgery
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Salvar Cirurgia'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --------- DIALOG DE EVOLUÇÃO DE PESO ---------
  Future<void> _openWeightDialog({
    required String vetUid,
  }) async {
    _weightCtrl.clear();
    _weightDate = null;
    setState(() {});

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            Future<void> pickWeightDate() async {
              final picked = await _pickDate(ctx, initial: _weightDate);
              if (picked != null) {
                setLocalState(() {
                  _weightDate = picked;
                });
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              titlePadding:
                  const EdgeInsets.only(left: 20, right: 12, top: 18),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Registrar Peso',
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
                      'Registre o peso atual do pet.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Peso (kg) *',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ex: 5.5, 12.3...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ClickVetColors.goldDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Data da Medição *',
                      style: TextStyle(
                        color: ClickVetColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: pickWeightDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: ClickVetColors.gold,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: ClickVetColors.gold,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          _weightDate == null
                              ? 'Selecionar'
                              : _fmtDateBr(_weightDate!),
                          style: TextStyle(
                            fontSize: 13,
                            color: _weightDate == null
                                ? Colors.black45
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(
                right: 16,
                left: 16,
                bottom: 12,
                top: 4,
              ),
              actions: [
                TextButton(
                  onPressed: _savingWeight
                      ? null
                      : () {
                          Navigator.of(ctx).pop();
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA16207),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _savingWeight
                      ? null
                      : () async {
                          final weightText = _weightCtrl.text.trim();
                          if (weightText.isEmpty || _weightDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Informe o peso e a data da medição.',
                                ),
                              ),
                            );
                            return;
                          }

                          final weight = double.tryParse(weightText);
                          if (weight == null || weight <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Informe um peso válido.'),
                              ),
                            );
                            return;
                          }

                          try {
                            setLocalState(() {
                              _savingWeight = true;
                            });

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(vetUid)
                                .collection('pets')
                                .doc(widget.petId)
                                .collection('weight_records')
                                .add({
                              'weight': weight,
                              'date': Timestamp.fromDate(_weightDate!),
                              'dateStr': _fmtDateBr(_weightDate!),
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (!mounted) return;
                            Navigator.of(ctx).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Peso registrado com sucesso!'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao registrar peso: $e'),
                              ),
                            );
                          } finally {
                            setLocalState(() {
                              _savingWeight = false;
                            });
                          }
                        },
                  child: _savingWeight
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Registrar Peso'),
                ),
              ],
            );
          },
        );
      },
    );
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

    final petDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(vet.uid)
        .collection('pets')
        .doc(widget.petId)
        .snapshots();

    final evolutionsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(vet.uid)
        .collection('pets')
        .doc(widget.petId)
        .collection('evolutions')
        .orderBy('createdAt', descending: true)
        .snapshots();

    final allergiesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(vet.uid)
        .collection('pets')
        .doc(widget.petId)
        .collection('allergies')
        .orderBy('createdAt', descending: true)
        .snapshots();

    final vaccinesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(vet.uid)
        .collection('pets')
        .doc(widget.petId)
        .collection('vaccines')
        .orderBy('date', descending: true)
        .snapshots();

    final medicationsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(vet.uid)
        .collection('pets')
        .doc(widget.petId)
        .collection('medications')
        .orderBy('createdAt', descending: true)
        .snapshots();

    final examsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(vet.uid)
        .collection('pets')
        .doc(widget.petId)
        .collection('exams')
        .orderBy('date', descending: true)
        .snapshots();

    final surgeriesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(vet.uid)
        .collection('pets')
        .doc(widget.petId)
        .collection('surgeries')
        .orderBy('date', descending: true)
        .snapshots();

    final weightRecordsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(vet.uid)
        .collection('pets')
        .doc(widget.petId)
        .collection('weight_records')
        .orderBy('date', descending: true)
        .snapshots();


    return VetScaffold(
      selectedKey: DrawerItemKey.patients,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text(
          'Prontuário',
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
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                child: Column(
                  children: [

                    // CABEÇALHO PET
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: petDocStream,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snap.hasError) {
                          return _ErrorCard(
                            message:
                            'Erro ao carregar dados do pet: ${snap.error}',
                          );
                        }

                        if (!snap.hasData || !snap.data!.exists) {
                          return const _ErrorCard(
                            message:
                            'Pet não encontrado. Verifique e tente novamente.',
                          );
                        }

                        final m = snap.data!.data()!;
                        final name = (m['name'] ?? '—').toString();
                        final breed = (m['breed'] ?? '—').toString();
                        final gender = (m['gender'] ?? '').toString();
                        final color = (m['color'] ?? '').toString();
                        final weightValue = m['weight'];
                        final weight =
                        weightValue == null ? '—' : '$weightValue kg';
                        final tutorName = (m['tutorName'] ?? '—').toString();
                        final age = _ageFrom(m['birthDate'] ?? m['age']);

                        return _PetHeaderCard(
                          name: name,
                          breed: breed,
                          gender: gender,
                          color: color,
                          age: age,
                          weight: weight,
                          tutorName: tutorName,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ALERGIAS
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: allergiesStream,
                      builder: (context, snap) {
                        if (snap.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snap.hasError) {
                          return _ErrorCard(
                            message:
                            'Erro ao carregar alergias: ${snap.error}',
                          );
                        }

                        final docs = snap.data?.docs ?? [];

                        return _SectionCard(
                          icon: Icons.report_gmailerrorred_outlined,
                          iconBg: const Color(0xFFFFE4E6),
                          iconColor: const Color(0xFFDC2626),
                          title: 'Alergias',
                          subtitle: docs.isEmpty
                              ? 'Nenhuma alergia registrada ainda'
                              : '${docs.length} registrada(s)',
                          children: [
                            if (docs.isEmpty)
                              const _EmptyText(
                                text:
                                'Nenhuma alergia cadastrada para este pet.',
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics:
                                const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data();
                                  final name =
                                  (data['name'] ?? '—').toString();
                                  final severity =
                                  (data['severity'] ?? '—').toString();
                                  final notes =
                                  (data['notes'] ?? '').toString();

                                  return _AllergyItem(
                                    name: name,
                                    severity: severity,
                                    notes: notes,
                                  );
                                },
                              ),
                            const SizedBox(height: 8),
                            _PrimarySectionButton(
                              label: 'Adicionar alergia',
                              color: const Color(0xFFDC2626),
                              onPressed: () {
                                _openAllergyDialog(vetUid: vet.uid);
                              },
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // VACINAS
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: vaccinesStream,
                      builder: (context, snap) {
                        if (snap.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snap.hasError) {
                          return _ErrorCard(
                            message:
                            'Erro ao carregar vacinas: ${snap.error}',
                          );
                        }

                        final docs = snap.data?.docs ?? [];

                        return _SectionCard(
                          icon: Icons.vaccines_outlined,
                          iconBg: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF16A34A),
                          title: 'Vacinas',
                          subtitle: docs.isEmpty
                              ? 'Nenhuma vacina registrado ainda'
                              : '${docs.length} registrada(s)',
                          children: [
                            if (docs.isEmpty)
                              const _EmptyText(
                                text:
                                'Nenhuma vacina registrada para este pet.',
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics:
                                const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data();
                                  final name =
                                  (data['name'] ?? '—').toString();
                                  final dateStr =
                                  (data['dateStr'] ?? '').toString();
                                  final nextDateStr =
                                  (data['nextDateStr'] ?? '')
                                      .toString();
                                  final batch =
                                  (data['batch'] ?? '').toString();
                                  final vetName =
                                  (data['veterinarian'] ?? '')
                                      .toString();

                                  return _VaccineItem(
                                    name: name,
                                    date: dateStr,
                                    nextDate: nextDateStr,
                                    batch: batch,
                                    vetName: vetName,
                                  );
                                },
                              ),
                            const SizedBox(height: 8),
                            _PrimarySectionButton(
                              label: 'Adicionar vacina',
                              color: const Color(0xFF16A34A),
                              onPressed: () {
                                _openVaccineDialog(vetUid: vet.uid);
                              },
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // MEDICAMENTOS (coleção própria)
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: medicationsStream,
                      builder: (context, snap) {
                        if (snap.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snap.hasError) {
                          return _ErrorCard(
                            message:
                            'Erro ao carregar medicamentos: ${snap.error}',
                          );
                        }

                        final docs = snap.data?.docs ?? [];

                        return _SectionCard(
                          icon: Icons.medication_outlined,
                          iconBg: const Color(0xFFEDE9FE),
                          iconColor: const Color(0xFF7C3AED),
                          title: 'Medicamentos',
                          subtitle: docs.isEmpty
                              ? 'Nenhum medicamento registrado ainda'
                              : '${docs.length} registrado(s)',
                          children: [
                            if (docs.isEmpty)
                              const _EmptyText(
                                text:
                                'Nenhum medicamento registrado para este pet.',
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics:
                                const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data();
                                  final name =
                                  (data['name'] ?? '—').toString();
                                  final dosage =
                                  (data['dosage'] ?? '').toString();
                                  final freq =
                                  (data['frequency'] ?? '').toString();
                                  final startStr =
                                  (data['startDateStr'] ?? '')
                                      .toString();
                                  final endStr =
                                  (data['endDateStr'] ?? '').toString();

                                  return _MedicationItem(
                                    name: name,
                                    dosage: dosage,
                                    frequency: freq,
                                    startDate: startStr,
                                    endDate: endStr,
                                  );
                                },
                              ),
                            const SizedBox(height: 8),
                            _PrimarySectionButton(
                              label: 'Adicionar medicamento',
                              color: const Color(0xFF7C3AED),
                              onPressed: () {
                                _openMedicationDialog(vetUid: vet.uid);
                              },
                            ),
                          ],
                        );
                      },
                    ),



                    const SizedBox(height: 12),

                    // EVOLUÇÕES / HISTÓRICO
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: evolutionsStream,
                      builder: (context, snap) {
                        if (snap.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snap.hasError) {
                          return _ErrorCard(
                            message:
                            'Erro ao carregar evoluções: ${snap.error}',
                          );
                        }

                        final docs = snap.data?.docs ?? [];
                        final evolutions =
                        docs.map((d) => d.data()).toList();

                        final evolWithExams = evolutions.where((e) {
                          final s = ((e['examsSummary'] ?? '') as String)
                              .trim();
                          return s.isNotEmpty;
                        }).toList();

                        final evolWithSurgeries = evolutions.where((e) {
                          final s =
                              ((e['surgeriesSummary'] ?? '') as String?)
                                  ?.trim() ??
                                  '';
                          return s.isNotEmpty;
                        }).toList();

                        final evolWithWeight = evolutions.where((e) {
                          final w = e['weight'];
                          if (w == null) return false;
                          return w.toString().trim().isNotEmpty;
                        }).toList();

                        return Column(
                          children: [
                            _SectionCard(
                              icon: Icons.history_rounded,
                              iconBg: const Color(0xFFE0EAFF),
                              iconColor: const Color(0xFF2563EB),
                              title: 'Histórico de Consultas',
                              subtitle:
                              'Acompanhe as consultas e evoluções deste pet',
                              children: [
                                if (evolutions.isEmpty)
                                  const _EmptyText(
                                    text:
                                    'Nenhuma consulta registrada para este pet.',
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    itemCount: evolutions.length,
                                    separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final data = evolutions[index];

                                      final date =
                                      (data['date'] ?? '') as String;
                                      final time =
                                      (data['time'] ?? '') as String;
                                      final chiefComplaint =
                                      (data['chiefComplaint'] ??
                                          'Sem queixa principal')
                                      as String;
                                      final diagnosis =
                                      (data['diagnosis'] ??
                                          'Sem diagnóstico informado')
                                      as String;
                                      final rawWeight = data['weight'];
                                      final weight = rawWeight == null
                                          ? ''
                                          : rawWeight.toString();
                                      final prescription =
                                      (data['prescription'] ?? '')
                                      as String;
                                      final examsSummary =
                                      (data['examsSummary'] ?? '')
                                      as String;
                                      final surgeriesSummary =
                                      (data['surgeriesSummary'] ?? '')
                                      as String;

                                      return _EvolutionItem(
                                        date: date,
                                        time: time,
                                        chiefComplaint: chiefComplaint,
                                        diagnosis: diagnosis,
                                        weight: weight,
                                        hasMeds:
                                        prescription.trim().isNotEmpty,
                                        hasExams:
                                        examsSummary.trim().isNotEmpty,
                                        hasVaccines: false,
                                        hasSurgeries: surgeriesSummary
                                            .trim()
                                            .isNotEmpty,
                                      );
                                    },
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // EXAMES - Stream separado
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: examsStream,
                              builder: (context, snap) {
                                if (snap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (snap.hasError) {
                                  return _ErrorCard(
                                    message:
                                        'Erro ao carregar exames: ${snap.error}',
                                  );
                                }

                                final docs = snap.data?.docs ?? [];

                                // Combinar exames do stream com os das evoluções
                                final allExams = <Map<String, dynamic>>[];
                                for (var doc in docs) {
                                  final data = doc.data();
                                  allExams.add({
                                    'name': data['name'] ?? '',
                                    'result': data['result'] ?? '',
                                    'dateStr': data['dateStr'] ?? '',
                                    'notes': data['notes'] ?? '',
                                  });
                                }
                                for (var evol in evolWithExams) {
                                  final date = (evol['date'] ?? '') as String;
                                  final summary = (evol['examsSummary'] ?? '') as String;
                                  if (summary.trim().isNotEmpty) {
                                    allExams.add({
                                      'name': summary,
                                      'result': '',
                                      'dateStr': date,
                                      'notes': '',
                                    });
                                  }
                                }
                                // Ordenar por data (mais recente primeiro)
                                allExams.sort((a, b) {
                                  final dateA = a['dateStr'] as String;
                                  final dateB = b['dateStr'] as String;
                                  return dateB.compareTo(dateA);
                                });

                                return _SectionCard(
                                  icon: Icons.description_outlined,
                                  iconBg: const Color(0xFFFFEDD5),
                                  iconColor: const Color(0xFFEA580C),
                                  title: 'Exames',
                                  subtitle: allExams.isEmpty
                                      ? 'Nenhum exame registrado ainda'
                                      : '${allExams.length} registrado(s)',
                                  children: [
                                    if (allExams.isEmpty)
                                      const _EmptyText(
                                        text:
                                            'Nenhum exame registrado para este pet.',
                                      )
                                    else
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: allExams.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 6),
                                        itemBuilder: (context, index) {
                                          final data = allExams[index];
                                          final name = (data['name'] ?? '—').toString();
                                          final result = (data['result'] ?? '').toString();
                                          final dateStr = (data['dateStr'] ?? '').toString();
                                          final notes = (data['notes'] ?? '').toString();

                                          return _ExamItem(
                                            name: name,
                                            result: result,
                                            date: dateStr,
                                            notes: notes,
                                          );
                                        },
                                      ),
                                    const SizedBox(height: 8),
                                    _PrimarySectionButton(
                                      label: 'Adicionar exame',
                                      color: const Color(0xFFEA580C),
                                      onPressed: () {
                                        _openExamDialog(vetUid: vet.uid);
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),


                            const SizedBox(height: 12),

                            // CIRURGIAS - Stream separado
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: surgeriesStream,
                              builder: (context, snap) {
                                if (snap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (snap.hasError) {
                                  return _ErrorCard(
                                    message:
                                        'Erro ao carregar cirurgias: ${snap.error}',
                                  );
                                }

                                final docs = snap.data?.docs ?? [];

                                // Combinar cirurgias do stream com as das evoluções
                                final allSurgeries = <Map<String, dynamic>>[];
                                for (var doc in docs) {
                                  allSurgeries.add(doc.data());
                                }
                                for (var evol in evolWithSurgeries) {
                                  final date = (evol['date'] ?? '') as String;
                                  final summary = (evol['surgeriesSummary'] ?? '') as String;
                                  if (summary.trim().isNotEmpty) {
                                    allSurgeries.add({
                                      'name': summary,
                                      'dateStr': date,
                                      'description': '',
                                    });
                                  }
                                }

                                return _SectionCard(
                                  icon: Icons.monitor_heart_outlined,
                                  iconBg: const Color(0xFFFFE4E6),
                                  iconColor: const Color(0xFFDB2777),
                                  title: 'Cirurgias',
                                  subtitle: allSurgeries.isEmpty
                                      ? 'Nenhuma cirurgia registrada ainda'
                                      : '${allSurgeries.length} registrada(s)',
                                  children: [
                                    if (allSurgeries.isEmpty)
                                      const _EmptyText(
                                        text:
                                            'Nenhuma cirurgia registrada para este pet.',
                                      )
                                    else
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: allSurgeries.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 6),
                                        itemBuilder: (context, index) {
                                          final data = allSurgeries[index];
                                          final name = (data['name'] ?? '—').toString();
                                          final dateStr = (data['dateStr'] ?? '').toString();
                                          final description = (data['description'] ?? '').toString();

                                          return _SurgeryItem(
                                            name: name,
                                            date: dateStr,
                                            description: description,
                                          );
                                        },
                                      ),
                                    const SizedBox(height: 8),
                                    _PrimarySectionButton(
                                      label: 'Adicionar cirurgia',
                                      color: const Color(0xFFDB2777),
                                      onPressed: () {
                                        _openSurgeryDialog(vetUid: vet.uid);
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            // EVOLUÇÃO DE PESO - Stream separado
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: weightRecordsStream,
                              builder: (context, snap) {
                                if (snap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (snap.hasError) {
                                  return _ErrorCard(
                                    message:
                                        'Erro ao carregar registros de peso: ${snap.error}',
                                  );
                                }

                                final docs = snap.data?.docs ?? [];

                                // Combinar pesos do stream com os das evoluções
                                final allWeights = <Map<String, dynamic>>[];
                                for (var doc in docs) {
                                  final data = doc.data();
                                  allWeights.add({
                                    'weight': data['weight'],
                                    'dateStr': data['dateStr'] ?? '',
                                  });
                                }
                                for (var evol in evolWithWeight) {
                                  final date = (evol['date'] ?? '') as String;
                                  final weight = evol['weight'];
                                  allWeights.add({
                                    'weight': weight,
                                    'dateStr': date,
                                  });
                                }
                                // Ordenar por data (mais recente primeiro)
                                allWeights.sort((a, b) {
                                  final dateA = a['dateStr'] as String;
                                  final dateB = b['dateStr'] as String;
                                  return dateB.compareTo(dateA);
                                });

                                return _SectionCard(
                                  icon: Icons.trending_up_rounded,
                                  iconBg: const Color(0xFFFEF9C3),
                                  iconColor: const Color(0xFFA16207),
                                  title: 'Evolução de Peso',
                                  subtitle: allWeights.isEmpty
                                      ? 'Nenhum registro de peso ainda'
                                      : '${allWeights.length} registro(s)',
                                  children: [
                                    if (allWeights.isEmpty)
                                      const _EmptyText(
                                        text:
                                            'Ainda não há registros de peso para este pet.',
                                      )
                                    else
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: allWeights.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 6),
                                        itemBuilder: (context, index) {
                                          final data = allWeights[index];
                                          final weight = data['weight'].toString();
                                          final date = (data['dateStr'] ?? '').toString();

                                          return _RegistryItem(
                                            icon: Icons.monitor_weight_outlined,
                                            title: '$weight kg',
                                            date: date,
                                          );
                                        },
                                      ),
                                    const SizedBox(height: 8),
                                    _PrimarySectionButton(
                                      label: 'Registrar peso',
                                      color: const Color(0xFFA16207),
                                      onPressed: () {
                                        _openWeightDialog(vetUid: vet.uid);
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // FAB Nova Evolução
            Positioned(
              right: 16,
              bottom: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () async {
                    // Buscar dados do pet para passar para a tela de evolução
                    final petDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(vet.uid)
                        .collection('pets')
                        .doc(widget.petId)
                        .get();
                    final petData = petDoc.data();
                    if (petData != null && mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NewEvolutionScreen(
                            petId: widget.petId,
                            petName: (petData['name'] ?? '').toString(),
                            petBreed: (petData['breed'] ?? '').toString(),
                            tutorName: (petData['tutorName'] ?? '').toString(),
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ClickVetColors.goldLight,
                          ClickVetColors.gold,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 30,
                    ),
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

/// ---------- WIDGETS AUXILIARES ----------

class _PetHeaderCard extends StatelessWidget {
  const _PetHeaderCard({
    required this.name,
    required this.breed,
    required this.gender,
    required this.color,
    required this.age,
    required this.weight,
    required this.tutorName,
  });

  final String name;
  final String breed;
  final String gender;
  final String color;
  final String age;
  final String weight;
  final String tutorName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ClickVetColors.gold, width: 1.6),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ClickVetColors.gold.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets,
              color: ClickVetColors.gold,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$breed • $age',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _InfoChip(label: 'Sexo', value: gender),
                    _InfoChip(label: 'Cor', value: color),
                    _InfoChip(label: 'Peso', value: weight),
                    _InfoChip(label: 'Tutor', value: tutorName),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ClickVetColors.goldDark,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(
            color: ClickVetColors.gold,
            width: 1.4,
          ),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(
            color: ClickVetColors.gold,
            width: 1.4,
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: ClickVetColors.goldDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
        children: children,
      ),
    );
  }
}

class _PrimarySectionButton extends StatelessWidget {
  const _PrimarySectionButton({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.add,
          size: 18,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black54,
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDC2626)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB91C1C),
          fontSize: 13,
        ),
      ),
    );
  }
}

class _EvolutionItem extends StatelessWidget {
  const _EvolutionItem({
    required this.date,
    required this.time,
    required this.chiefComplaint,
    required this.diagnosis,
    required this.weight,
    required this.hasMeds,
    required this.hasExams,
    required this.hasVaccines,
    required this.hasSurgeries,
  });

  final String date;
  final String time;
  final String chiefComplaint;
  final String diagnosis;

  final String weight;
  final bool hasMeds;
  final bool hasExams;
  final bool hasVaccines;
  final bool hasSurgeries;

  @override
  Widget build(BuildContext context) {
    final hasDate = date.isNotEmpty;
    final hasTime = time.isNotEmpty;
    final hasWeight = weight.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ClickVetColors.gold.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDate || hasTime)
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: ClickVetColors.goldDark,
                ),
                const SizedBox(width: 4),
                Text(
                  [
                    if (hasDate) date,
                    if (hasTime) time,
                  ].join(' • '),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ClickVetColors.goldDark,
                  ),
                ),
              ],
            ),
          if (hasDate || hasTime) const SizedBox(height: 6),
          Text(
            chiefComplaint,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            diagnosis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (hasWeight)
                _ChipTag(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Peso: $weight kg',
                ),
              if (hasMeds)
                const _ChipTag(
                  icon: Icons.medication_outlined,
                  label: 'Medicamentos prescritos',
                ),
              if (hasExams)
                const _ChipTag(
                  icon: Icons.science_outlined,
                  label: 'Exames solicitados',
                ),
              if (hasVaccines)
                const _ChipTag(
                  icon: Icons.vaccines_outlined,
                  label: 'Vacinas aplicadas',
                ),
              if (hasSurgeries)
                const _ChipTag(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Cirurgias registradas',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipTag extends StatelessWidget {
  const _ChipTag({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ClickVetColors.gold.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ClickVetColors.goldDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistryItem extends StatelessWidget {
  const _RegistryItem({
    required this.icon,
    required this.title,
    required this.date,
  });

  final IconData icon;
  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ClickVetColors.gold.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ClickVetColors.goldDark),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                if (date.isNotEmpty) const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergyItem extends StatelessWidget {
  const _AllergyItem({
    required this.name,
    required this.severity,
    required this.notes,
  });

  final String name;
  final String severity;
  final String notes;

  Color _severityColor() {
    switch (severity.toLowerCase()) {
      case 'leve':
        return const Color(0xFF16A34A);
      case 'moderada':
        return const Color(0xFFF97316);
      case 'alta':
        return const Color(0xFFDC2626);
      case 'grave':
        return const Color(0xFFB91C1C);
      default:
        return ClickVetColors.goldDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFDC2626),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color, width: 1),
                ),
                child: Text(
                  severity,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (notes.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              notes,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VaccineItem extends StatelessWidget {
  const _VaccineItem({
    required this.name,
    required this.date,
    required this.nextDate,
    required this.batch,
    required this.vetName,
  });

  final String name;
  final String date;
  final String nextDate;
  final String batch;
  final String vetName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF16A34A).withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.vaccines_outlined,
                size: 18,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (date.isNotEmpty)
            Text(
              'Aplicada em: $date',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
          if (nextDate.isNotEmpty)
            Text(
              'Próxima dose: $nextDate',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
          if (batch.trim().isNotEmpty)
            Text(
              'Lote: $batch',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
          if (vetName.trim().isNotEmpty)
            Text(
              'Veterinário: $vetName',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}

class _MedicationItem extends StatelessWidget {
  const _MedicationItem({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    required this.endDate,
  });

  final String name;
  final String dosage;
  final String frequency;
  final String startDate;
  final String endDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7C3AED).withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medication_outlined,
                size: 18,
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (dosage.isNotEmpty)
            Text(
              'Dosagem: $dosage',
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          if (frequency.isNotEmpty)
            Text(
              'Frequência: $frequency',
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          if (startDate.isNotEmpty)
            Text(
              'Início: $startDate',
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          if (endDate.isNotEmpty)
            Text(
              'Fim: $endDate',
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
        ],
      ),
    );
  }
}

class _SurgeryItem extends StatelessWidget {
  const _SurgeryItem({
    required this.name,
    required this.date,
    required this.description,
  });

  final String name;
  final String date;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFDB2777).withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monitor_heart_outlined,
                size: 18,
                color: Color(0xFFDB2777),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Data: $date',
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ],
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExamItem extends StatelessWidget {
  const _ExamItem({
    required this.name,
    required this.result,
    required this.date,
    required this.notes,
  });

  final String name;
  final String result;
  final String date;
  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEA580C).withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.science_outlined,
                size: 18,
                color: Color(0xFFEA580C),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Data: $date',
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ],
          if (result.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Resultado: $result',
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ],
          if (notes.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              notes,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }
}
