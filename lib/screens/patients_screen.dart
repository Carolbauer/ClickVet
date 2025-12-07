import 'package:app/screens/edit_pet_screen.dart';
import 'package:app/screens/home_screen.dart';
import 'package:app/screens/medical_record_screen.dart';
import 'package:app/screens/new_schedule_screen.dart';
import 'package:app/screens/register_pet_screen.dart';
import 'package:app/screens/register_tutor_screen.dart';
import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/vet_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_drawer.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _petsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pets')
        .orderBy('name')
        .snapshots();
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '—';
    if (v is Timestamp) {
      final d = v.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return v.toString();
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
      selectedKey: DrawerItemKey.patients,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text(
          'Pacientes',
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
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar pacientes...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: ClickVetColors.gold,
                  ),
                  filled: true,
                  fillColor: ClickVetColors.bg,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: ClickVetColors.gold,
                      width: 1.8,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: ClickVetColors.goldDark,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _petsStream(vet.uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snap.hasError) {
                    return Center(
                      child:
                      Text('Erro ao carregar pacientes: ${snap.error}'),
                    );
                  }

                  final docs = snap.data?.docs ?? [];
                  final query = _searchController.text.trim().toLowerCase();

                  final patients = docs.map<_Patient>((d) {
                    final m = d.data();
                    return _Patient(
                      rawDoc: d,
                      id: d.id,
                      name: (m['name'] ?? '—').toString(),
                      breed: (m['breed'] ?? '—').toString(),
                      species: (m['species'] ?? '').toString(),
                      age: _ageFrom(m['birthDate'] ?? m['age']),
                      owner: (m['tutorName'] ?? '—').toString(),
                      phone: (m['tutorPhone'] ??
                          m['ownerPhone'] ??
                          m['phone'] ??
                          '')
                          .toString(),
                      status: (m['status'] ?? '').toString(),
                      lastVisit: _fmtDate(m['lastVisit']),
                      nextVaccine: _fmtDate(m['nextVaccine']),
                    );
                  }).toList();

                  final filtered = patients.where((p) {
                    if (query.isEmpty) return true;
                    return p.name.toLowerCase().contains(query) ||
                        p.owner.toLowerCase().contains(query) ||
                        p.breed.toLowerCase().contains(query);
                  }).toList();

                  final total = patients.length;
                  final healthy =
                      patients.where((p) => p.status == 'Saudável').length;
                  final inTreatment =
                      patients.where((p) => p.status == 'Em Tratamento').length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _StatBox(value: '$total', label: 'Total'),
                            const SizedBox(width: 8),
                            _StatBox(
                              value: '$healthy',
                              label: 'Saudáveis',
                              valueColor: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            _StatBox(
                              value: '$inTreatment',
                              label: 'Tratamento',
                              valueColor: Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        ClickVetColors.goldLight,
                                        ClickVetColors.gold,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const RegisterTutorScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.groups_outlined,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Cadastrar Tutor',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        ClickVetColors.goldLight,
                                        ClickVetColors.gold,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const RegisterPetScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.pets,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Cadastrar Pet',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (filtered.isEmpty)
                          const _EmptyPatients()
                        else
                          Column(
                            children: [
                              for (final p in filtered) ...[
                                _PatientCard(patient: p),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _Patient {
  final DocumentSnapshot<Map<String, dynamic>> rawDoc;
  final String id;
  final String name;
  final String breed;
  final String species;
  final String age;
  final String owner;
  final String phone;
  final String status;
  final String lastVisit;
  final String nextVaccine;

  const _Patient({
    required this.rawDoc,
    required this.id,
    required this.name,
    required this.breed,
    required this.species,
    required this.age,
    required this.owner,
    required this.phone,
    required this.status,
    required this.lastVisit,
    required this.nextVaccine,
  });
}

/// ------- WIDGETS AUXILIARES -------

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ClickVetColors.gold, width: 1.6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: valueColor ?? ClickVetColors.gold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: ClickVetColors.goldDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient});

  final _Patient patient;

  Color _statusBg(String s) {
    if (s == 'Saudável') return const Color(0xFFE6F9EC);
    if (s == 'Em Tratamento') return const Color(0xFFFFF4D6);
    return const Color(0xFFE5E7EB);
  }

  Color _statusText(String s) {
    if (s == 'Saudável') return const Color(0xFF166534);
    if (s == 'Em Tratamento') return const Color(0xFF92400E);
    return const Color(0xFF4B5563);
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/55$clean');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  Future<void> _openCall(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('tel:$clean');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o discador.')),
      );
    }
  }

  void _contactTutor(BuildContext context) {
    final phone = patient.phone.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutor sem telefone cadastrado.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Contato do tutor',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ClickVetColors.goldDark,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  phone,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openWhatsApp(context, phone);
                        },
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openCall(context, phone);
                        },
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Ligar'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: ClickVetColors.gold, width: 1.4),
                          foregroundColor: ClickVetColors.goldDark,
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
    );
  }

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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ClickVetColors.gold.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              color: ClickVetColors.gold,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            patient.age.isEmpty || patient.age == '—'
                                ? patient.breed
                                : '${patient.breed} • ${patient.age}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (patient.status.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusBg(patient.status),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          patient.status,
                          style: TextStyle(
                            color: _statusText(patient.status),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: ClickVetColors.goldDark),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        patient.owner,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                if (patient.phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone,
                          size: 16, color: ClickVetColors.goldDark),
                      const SizedBox(width: 4),
                      Text(
                        patient.phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Última visita:',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.black54)),
                          Text(patient.lastVisit,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Próxima vacina:',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.black54)),
                          Text(patient.nextVaccine,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewScheduleScreen(
                                initialPet: patient.rawDoc,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: ClickVetColors.gold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: ClickVetColors.goldDark,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Agendar',
                              style: TextStyle(
                                color: ClickVetColors.goldDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MedicalRecordScreen(petId: patient.id),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: ClickVetColors.gold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                        ),
                        child: const Text(
                          'Prontuário',
                          style:
                          TextStyle(color: ClickVetColors.goldDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 42,
                      child: OutlinedButton(
                        onPressed: () => _contactTutor(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: ClickVetColors.gold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                        child: const Icon(
                          Icons.phone,
                          size: 18,
                          color: ClickVetColors.goldDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 42,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditPetScreen(petId: patient.id),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: ClickVetColors.gold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: ClickVetColors.goldDark,
                        ),
                      ),
                    ),
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

class _EmptyPatients extends StatelessWidget {
  const _EmptyPatients();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: const [
          Icon(Icons.favorite_border,
              size: 64, color: ClickVetColors.gold),
          SizedBox(height: 8),
          Text(
            'Nenhum paciente encontrado',
            style: TextStyle(
              color: ClickVetColors.goldDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tente ajustar os termos de busca.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
