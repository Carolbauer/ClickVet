import 'package:app/screens/new_evolution_screen.dart';
import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/vet_scaffold.dart';
import 'package:app/widgets/app_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MedicalRecordScreen extends StatelessWidget {
  final String petId;

  const MedicalRecordScreen({
    super.key,
    required this.petId,
  });

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
        .doc(petId)
        .snapshots();

    final evolutionsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(vet.uid)
        .collection('pets')
        .doc(petId)
        .collection('evolutions')
        .orderBy('createdAt', descending: true)
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

                        patient.id = petId;
                        patient.name = name;
                        patient.breed = breed;
                        patient.ownerName = tutorName;

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

                    _SectionCard(
                      icon: Icons.report_gmailerrorred_outlined,
                      iconBg: const Color(0xFFFFE4E6),
                      iconColor: const Color(0xFFDC2626),
                      title: 'Alergias',
                      subtitle: 'Nenhuma alergia registrada ainda',
                      children: [
                        const _EmptyText(
                          text: 'Nenhuma alergia cadastrada para este pet.',
                        ),
                        const SizedBox(height: 8),
                        _PrimarySectionButton(
                          label: 'Adicionar alergia',
                          color: const Color(0xFFDC2626),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Fluxo de adicionar alergia em desenvolvimento.',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: evolutionsStream,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
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

                        final evolWithVaccines = evolutions.where((e) {
                          final s =
                          ((e['vaccinesSummary'] ?? '') as String).trim();
                          return s.isNotEmpty;
                        }).toList();

                        final evolWithExams = evolutions.where((e) {
                          final s =
                          ((e['examsSummary'] ?? '') as String).trim();
                          return s.isNotEmpty;
                        }).toList();

                        final evolWithMeds = evolutions.where((e) {
                          final s =
                          ((e['prescription'] ?? '') as String).trim();
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
                                      final vaccinesSummary =
                                      (data['vaccinesSummary'] ?? '')
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
                                        hasVaccines:
                                        vaccinesSummary.trim().isNotEmpty,
                                        hasSurgeries:
                                        surgeriesSummary.trim().isNotEmpty,
                                      );
                                    },
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            _SectionCard(
                              icon: Icons.vaccines_outlined,
                              iconBg: const Color(0xFFDCFCE7),
                              iconColor: const Color(0xFF16A34A),
                              title: 'Vacinas',
                              subtitle:
                              'Vacinas aplicadas em consultas deste pet',
                              children: [
                                if (evolWithVaccines.isEmpty)
                                  const _EmptyText(
                                    text:
                                    'Nenhuma vacina registrada para este pet.',
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    itemCount: evolWithVaccines.length,
                                    separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final data = evolWithVaccines[index];
                                      final date =
                                      (data['date'] ?? '') as String;
                                      final vaccinesSummary =
                                      (data['vaccinesSummary'] ?? '')
                                      as String;

                                      return _RegistryItem(
                                        icon: Icons.vaccines_outlined,
                                        title: vaccinesSummary,
                                        date: date,
                                      );
                                    },
                                  ),
                                const SizedBox(height: 8),
                                _PrimarySectionButton(
                                  label: 'Adicionar vacina',
                                  color: const Color(0xFF16A34A),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Fluxo de adicionar vacina em desenvolvimento.',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            _SectionCard(
                              icon: Icons.medication_outlined,
                              iconBg: const Color(0xFFEDE9FE),
                              iconColor: const Color(0xFF7C3AED),
                              title: 'Medicamentos',
                              subtitle:
                              'Medicamentos prescritos nas evoluções',
                              children: [
                                if (evolWithMeds.isEmpty)
                                  const _EmptyText(
                                    text:
                                    'Nenhum medicamento registrado para este pet.',
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    itemCount: evolWithMeds.length,
                                    separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final data = evolWithMeds[index];
                                      final date =
                                      (data['date'] ?? '') as String;
                                      final prescription =
                                      (data['prescription'] ?? '')
                                      as String;

                                      return _RegistryItem(
                                        icon: Icons.medication_outlined,
                                        title: prescription,
                                        date: date,
                                      );
                                    },
                                  ),
                                const SizedBox(height: 8),
                                _PrimarySectionButton(
                                  label: 'Adicionar medicamento',
                                  color: const Color(0xFF7C3AED),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Fluxo de adicionar medicamento em desenvolvimento.',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            _SectionCard(
                              icon: Icons.description_outlined,
                              iconBg: const Color(0xFFFFEDD5),
                              iconColor: const Color(0xFFEA580C),
                              title: 'Exames',
                              subtitle: 'Exames solicitados nas evoluções',
                              children: [
                                if (evolWithExams.isEmpty)
                                  const _EmptyText(
                                    text:
                                    'Nenhum exame registrado para este pet.',
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    itemCount: evolWithExams.length,
                                    separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final data = evolWithExams[index];
                                      final date =
                                      (data['date'] ?? '') as String;
                                      final examsSummary =
                                      (data['examsSummary'] ?? '')
                                      as String;

                                      return _RegistryItem(
                                        icon: Icons.science_outlined,
                                        title: examsSummary,
                                        date: date,
                                      );
                                    },
                                  ),
                                const SizedBox(height: 8),
                                _PrimarySectionButton(
                                  label: 'Adicionar exame',
                                  color: const Color(0xFFEA580C),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Fluxo de adicionar exame em desenvolvimento.',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            _SectionCard(
                              icon: Icons.monitor_heart_outlined,
                              iconBg: const Color(0xFFFFE4E6),
                              iconColor: const Color(0xFFDB2777),
                              title: 'Cirurgias',
                              subtitle: 'Cirurgias registradas nas evoluções',
                              children: [
                                if (evolWithSurgeries.isEmpty)
                                  const _EmptyText(
                                    text:
                                    'Nenhuma cirurgia registrado para este pet.',
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    itemCount: evolWithSurgeries.length,
                                    separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final data = evolWithSurgeries[index];
                                      final date =
                                      (data['date'] ?? '') as String;
                                      final surgeriesSummary =
                                      (data['surgeriesSummary'] ?? '')
                                      as String;

                                      return _RegistryItem(
                                        icon: Icons.monitor_heart_outlined,
                                        title: surgeriesSummary,
                                        date: date,
                                      );
                                    },
                                  ),
                                const SizedBox(height: 8),
                                _PrimarySectionButton(
                                  label: 'Adicionar cirurgia',
                                  color: const Color(0xFFDB2777),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Fluxo de adicionar cirurgia em desenvolvimento.',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            _SectionCard(
                              icon: Icons.trending_up_rounded,
                              iconBg: const Color(0xFFFEF9C3),
                              iconColor: const Color(0xFFA16207),
                              title: 'Evolução de Peso',
                              subtitle:
                              'Registros de peso nas consultas do pet',
                              children: [
                                if (evolWithWeight.isEmpty)
                                  const _EmptyText(
                                    text:
                                    'Ainda não há registros de peso para este pet.',
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    itemCount: evolWithWeight.length,
                                    separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final data = evolWithWeight[index];
                                      final date =
                                      (data['date'] ?? '') as String;
                                      final weight =
                                      data['weight'].toString();

                                      return _RegistryItem(
                                        icon: Icons.monitor_weight_outlined,
                                        title: '$weight kg',
                                        date: date,
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NewEvolutionScreen(
                          petId: patient.id,
                          petName: patient.name,
                          petBreed: patient.breed,
                          tutorName: patient.ownerName,
                        ),
                      ),
                    );
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

class patient {
  static String id = '';
  static String name = '';
  static String breed = '';
  static String ownerName = '';
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
