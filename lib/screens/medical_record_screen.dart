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
                    StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: petDocStream,
                      builder: (context, snap) {
                        if (snap.connectionState ==
                            ConnectionState.waiting) {
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
                        final weight = weightValue == null
                            ? '—'
                            : '$weightValue kg';
                        final tutorName =
                        (m['tutorName'] ?? '—').toString();
                        final age =
                        _ageFrom(m['birthDate'] ?? m['age']);

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
                          text:
                          'Nenhuma alergia cadastrada para este pet.',
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

                    _SectionCard(
                      icon: Icons.history_rounded,
                      iconBg: const Color(0xFFE0EAFF),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Histórico de Consultas',
                      subtitle: 'Nenhuma consulta registrada ainda',
                      children: const [
                        _EmptyText(
                          text:
                          'Nenhuma consulta registrada para este pet.',
                        ),
                        SizedBox(height: 8),
                        // lista de consultas
                      ],
                    ),

                    const SizedBox(height: 12),

                    _SectionCard(
                      icon: Icons.vaccines_outlined,
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Vacinas',
                      subtitle: 'Nenhuma vacina registrada',
                      children: [
                        const _EmptyText(
                          text:
                          'Nenhuma vacina registrada para este pet.',
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
                      subtitle: 'Nenhum medicamento registrado',
                      children: [
                        const _EmptyText(
                          text:
                          'Nenhum medicamento registrado para este pet.',
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
                      subtitle: 'Nenhum exame registrado',
                      children: [
                        const _EmptyText(
                          text:
                          'Nenhum exame registrado para este pet.',
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
                      subtitle: 'Nenhuma cirurgia registrada',
                      children: [
                        const _EmptyText(
                          text:
                          'Nenhuma cirurgia registrada para este pet.',
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
                      subtitle: 'Registre a evolução de peso do pet',
                      children: [
                        const _EmptyText(
                          text:
                          'Ainda não há registros de peso para este pet.',
                        ),
                        const SizedBox(height: 8),
                        _PrimarySectionButton(
                          label: 'Adicionar peso',
                          color: const Color(0xFFA16207),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Fluxo de adicionar peso em desenvolvimento.',
                                ),
                              ),
                            );
                          },
                        ),

                      ],
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: 16,
              bottom: 16,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => NewEvolutionScreen(
                            petId: patient.id,
                            petName: patient.name,
                            petBreed: patient.breed,
                            tutorName: patient.ownerName)),
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

/// ----- WIDGETS AUXILIARES -----

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
        childrenPadding:
        const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
