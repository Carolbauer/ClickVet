import 'package:app/screens/edit_tutor_screen.dart';
import 'package:app/screens/medical_record_screen.dart';
import 'package:app/widgets/app_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app/screens/register_tutor_screen.dart';
import 'package:app/screens/home_screen.dart';
import '../theme/clickvet_colors.dart';
import '../widgets/vet_scaffold.dart';

class TutorListScreen extends StatefulWidget {
  const TutorListScreen({super.key});

  @override
  State<TutorListScreen> createState() => _TutorListScreenState();
}

class _TutorListScreenState extends State<TutorListScreen> {
  final _search = TextEditingController();

  String _query = '';
  int _currentPage = 1;
  final int _perPage = 5;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tutors')
        .orderBy('name')
        .snapshots();
  }

  String _fmtDate(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return '—';
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;
    
    final uri = Uri.parse('https://wa.me/55$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  Future<void> _openCall(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;
    
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o discador.')),
      );
    }
  }

  void _contactTutor(BuildContext context, String phone) {
    final cleanPhone = phone.trim();

    if (cleanPhone.isEmpty) {
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
                  cleanPhone,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openWhatsApp(context, cleanPhone);
                        },
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                          _openCall(context, cleanPhone);
                        },
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Ligar'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: ClickVetColors.gold, width: 1.4),
                          foregroundColor: ClickVetColors.goldDark,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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

  Future<void> _showTutorPets(BuildContext context, String vetUid, String tutorId, String tutorName) async {
    // Query sem orderBy para evitar necessidade de índice composto
    // Ordenaremos no cliente
    final petsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(vetUid)
        .collection('pets')
        .where('tutorId', isEqualTo: tutorId)
        .snapshots();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: petsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final allDocs = snap.data?.docs ?? [];
                // Ordenar por nome no cliente
                final docs = List.from(allDocs)
                  ..sort((a, b) {
                    final nameA = (a.data()['name'] ?? '').toString().toLowerCase();
                    final nameB = (b.data()['name'] ?? '').toString().toLowerCase();
                    return nameA.compareTo(nameB);
                  });

                return Container(
                  decoration: const BoxDecoration(
                    color: ClickVetColors.bg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pets de $tutorName',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: ClickVetColors.goldDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${docs.length} ${docs.length == 1 ? "pet cadastrado" : "pets cadastrados"}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: docs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.pets_outlined,
                                      size: 64,
                                      color: ClickVetColors.gold,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Nenhum pet cadastrado',
                                      style: TextStyle(
                                        color: ClickVetColors.goldDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final petData = docs[index].data();
                                  final petId = docs[index].id;
                                  final petName = (petData['name'] ?? '—').toString();
                                  final breed = (petData['breed'] ?? '—').toString();
                                  final species = (petData['species'] ?? '').toString();

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: ClickVetColors.gold,
                                        width: 1.6,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: ClickVetColors.gold.withOpacity(0.08),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.pets,
                                            color: ClickVetColors.gold,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                petName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$breed${species.isNotEmpty ? ' • $species' : ''}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 18,
                                            color: ClickVetColors.goldDark,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => MedicalRecordScreen(
                                                  petId: petId,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
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

    return VetScaffold(
      selectedKey: DrawerItemKey.tutors,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text(
          'Tutores',
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
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              TextField(
                controller: _search,
                onChanged: (value) {
                  setState(() {
                    _query = value.trim().toLowerCase();
                    _currentPage = 1;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar tutores...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: ClickVetColors.gold,
                  ),
                  filled: true,
                  fillColor: Colors.white,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 48,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ClickVetColors.goldLight, ClickVetColors.gold],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterTutorScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Novo Tutor',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _stream(vet.uid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snap.hasError) {
                      return Center(child: Text('Erro: ${snap.error}'));
                    }

                    final docs = snap.data?.docs ?? [];

                    final filtered = docs.where((d) {
                      if (_query.isEmpty) return true;
                      final m = d.data();
                      return (m['name'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(_query) ||
                          (m['cpf'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(_query) ||
                          (m['phone'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(_query) ||
                          (m['email'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(_query) ||
                          (m['city'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(_query);
                    }).toList();

                    final totalTutors = filtered.length;
                    
                    // Buscar todos os pets para calcular contagem em tempo real
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(vet.uid)
                          .collection('pets')
                          .snapshots(),
                      builder: (petsContext, petsSnap) {
                        final allPets = petsSnap.data?.docs ?? [];
                        
                        // Calcular total de pets e pets por tutor em tempo real
                        final totalPets = allPets.length;
                        
                        // Criar mapa de tutorId -> contagem de pets
                        final petsByTutor = <String, int>{};
                        for (final petDoc in allPets) {
                          final tutorId = (petDoc.data()['tutorId'] ?? '').toString();
                          if (tutorId.isNotEmpty) {
                            petsByTutor[tutorId] = (petsByTutor[tutorId] ?? 0) + 1;
                          }
                        }

                    int totalPages =
                    (filtered.length / _perPage).ceil().clamp(1, 999);
                    if (totalPages == 0) totalPages = 1;

                    if (_currentPage > totalPages) {
                      _currentPage = totalPages;
                    }

                    final start = ((_currentPage - 1) * _perPage)
                        .clamp(0, filtered.length);
                    final end =
                    (start + _perPage).clamp(start, filtered.length);
                    final pageDocs = filtered.sublist(start, end);

                    return Column(
                      children: [
                        Row(
                          children: [
                            _StatBox(value: '$totalTutors', label: 'Total'),
                            const SizedBox(width: 10),
                            _StatBox(
                              value: '$totalPets',
                              label: 'Pets',
                              color: Colors.green,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Expanded(
                          child: pageDocs.isEmpty
                              ? const _EmptyState()
                              : ListView.separated(
                            itemCount: pageDocs.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final m = pageDocs[i].data();

                              final tutorId = pageDocs[i].id;
                              // Usar contagem em tempo real ou 0 se não houver pets
                              final realPetsCount = petsByTutor[tutorId] ?? 0;
                              
                              return _TutorCard(
                                tutorId: tutorId,
                                name: m['name'] ?? '—',
                                cpf: m['cpf'] ?? '—',
                                phone: m['phone'] ?? '—',
                                email: m['email'] ?? '—',
                                address:
                                '${m['address'] ?? '—'}, ${m['city'] ?? ''}',
                                petsCount: realPetsCount,
                                registerDate:
                                _fmtDate(m['registeredAt']),
                                onPets: () {
                                  _showTutorPets(context, vet.uid, tutorId, m['name'] ?? 'Tutor');
                                },
                                onEdit: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EditTutorScreen(
                                        tutorId: tutorId,
                                      ),
                                    ),
                                  );
                                },
                                onCall: () {
                                  _contactTutor(context, m['phone'] ?? '');
                                },
                              );
                            },
                          ),
                        ),

                        if (filtered.length > _perPage) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PageBtn(
                                icon: Icons.chevron_left,
                                enabled: _currentPage > 1,
                                onTap: () {
                                  setState(() => _currentPage--);
                                },
                              ),
                              for (int p = 1; p <= totalPages; p++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  child: _PageNumber(
                                    selected: _currentPage == p,
                                    label: '$p',
                                    onTap: () {
                                      setState(() => _currentPage = p);
                                    },
                                  ),
                                ),
                              _PageBtn(
                                icon: Icons.chevron_right,
                                enabled: _currentPage < totalPages,
                                onTap: () {
                                  setState(() => _currentPage++);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mostrando ${start + 1} - $end de ${filtered.length} tutores',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Widgets auxiliares

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label, this.color});
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ClickVetColors.gold, width: 1.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color ?? ClickVetColors.gold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
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

class _TutorCard extends StatelessWidget {
  const _TutorCard({
    required this.tutorId,
    required this.name,
    required this.cpf,
    required this.phone,
    required this.email,
    required this.address,
    required this.petsCount,
    required this.registerDate,
    required this.onPets,
    required this.onEdit,
    required this.onCall,
  });

  final String tutorId;
  final String name;
  final String cpf;
  final String phone;
  final String email;
  final String address;
  final int petsCount;
  final String registerDate;
  final VoidCallback onPets;
  final VoidCallback onEdit;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClickVetColors.gold, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F0FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$petsCount ${petsCount == 1 ? "Pet" : "Pets"}',
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('CPF: $cpf'),
          const SizedBox(height: 8),
          _info(Icons.phone, phone),
          _info(Icons.mail_outline, email),
          _info(Icons.location_on_outlined, address),
          const Divider(height: 24, color: Color(0x22000000)),
          Text(
            'Cadastrado em:',
            style: TextStyle(color: Colors.black.withOpacity(.55)),
          ),
          Text(
            registerDate,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onPets,
                icon: const Icon(
                  Icons.pets,
                  size: 18,
                  color: ClickVetColors.goldDark,
                ),
                label: const Text(
                  'Pets',
                  style: TextStyle(color: ClickVetColors.goldDark),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ClickVetColors.gold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onEdit,
                child: const Text(
                  'Editar',
                  style: TextStyle(color: ClickVetColors.goldDark),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ClickVetColors.gold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onCall,
                child: const Icon(
                  Icons.phone,
                  size: 18,
                  color: ClickVetColors.goldDark,
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ClickVetColors.gold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ClickVetColors.goldDark),
        const SizedBox(width: 6),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(Icons.people_outline, size: 70, color: ClickVetColors.gold),
        SizedBox(height: 8),
        Text(
          'Nenhum tutor encontrado',
          style: TextStyle(color: ClickVetColors.goldDark),
        ),
        SizedBox(height: 4),
        Text('Tente alterar os termos de busca.'),
      ],
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: ClickVetColors.gold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(40, 36),
      ),
      child: Icon(
        icon,
        size: 18,
        color: enabled ? ClickVetColors.goldDark : Colors.black26,
      ),
    );
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return selected
        ? ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: ClickVetColors.gold,
        foregroundColor: Colors.white,
        minimumSize: const Size(40, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(label),
    )
        : OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: ClickVetColors.gold),
        minimumSize: const Size(40, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(color: ClickVetColors.goldDark),
      ),
    );
  }
}
