import 'package:app/widgets/app_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/screens/register_tutor_screen.dart';

import '../theme/clickvet_colors.dart';
import '../widgets/vet_scaffold.dart';

class TutorListScreen extends StatefulWidget {
  const TutorListScreen({super.key});

  @override
  State<TutorListScreen> createState() => _TutorsListScreenState();
}

class _TutorsListScreenState extends State<TutorListScreen> {
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

  @override
  Widget build(BuildContext context) {
    final vet = FirebaseAuth.instance.currentUser;
    if (vet == null) {
      return const Scaffold(
          backgroundColor: ClickVetColors.bg,
        body: Center(child: Text('Sessão expirada. Faça login novamente.')),
      );
    }

    return VetScaffold(
      selectedKey: DrawerItemKey.tutors,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text('Tutores', style: TextStyle(color: ClickVetColors.gold)),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                return (m['name'] ?? '').toString().toLowerCase().contains(_query) ||
                    (m['cpf'] ?? '').toString().toLowerCase().contains(_query) ||
                    (m['phone'] ?? '').toString().toLowerCase().contains(_query) ||
                    (m['email'] ?? '').toString().toLowerCase().contains(_query) ||
                    (m['city'] ?? '').toString().toLowerCase().contains(_query);
              }).toList();

              final totalTutors = filtered.length;
              final totalPets = filtered.fold<int>(0, (sum, d) {
                final pc = (d.data()['petsCount'] ?? 0);
                return sum + (pc is int ? pc : 0);
              });


              final totalPages = (filtered.length / _perPage).ceil().clamp(1, 999);
              final start = ((_currentPage - 1) * _perPage).clamp(0, filtered.length);
              final end = (start + _perPage).clamp(0, filtered.length);
              final pageDocs = filtered.sublist(start, end);

              return Column(
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
                      prefixIcon: const Icon(Icons.search, color: ClickVetColors.gold),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color:ClickVetColors.gold, width: 1.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ClickVetColors.goldDark, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _StatBox(value: '$totalTutors', label: 'Total'),
                      const SizedBox(width: 10),
                      _StatBox(value: '$totalPets', label: 'Pets', color: Colors.green),
                    ],
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
                                builder: (_) => const RegisterTutorScreen()),
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
                    child: pageDocs.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                      itemCount: pageDocs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final m = pageDocs[i].data();

                        return _TutorCard(
                          name: m['name'] ?? '—',
                          cpf: m['cpf'] ?? '—',
                          phone: m['phone'] ?? '—',
                          email: m['email'] ?? '—',
                          address: '${m['address'] ?? '—'}, ${m['city'] ?? ''}',
                          petsCount: (m['petsCount'] is int) ? m['petsCount'] : 0,
                          registerDate: _fmtDate(m['registeredAt']),
                          onPets: () {},
                          onEdit: () {},
                          onCall: () {},
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
                          onTap: () => setState(() => _currentPage--),
                        ),
                        for (int p = 1; p <= totalPages; p++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _PageNumber(
                              selected: _currentPage == p,
                              label: '$p',
                              onTap: () => setState(() => _currentPage = p),
                            ),
                          ),
                        _PageBtn(
                          icon: Icons.chevron_right,
                          enabled: _currentPage < totalPages,
                          onTap: () => setState(() => _currentPage++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mostrando ${start + 1} - $end de ${filtered.length} tutores',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


/// ----- Widgets auxiliares -----

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
            Text(value, style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color ?? ClickVetColors.gold,
            )),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: ClickVetColors.goldDark, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({
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
                child: Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F0FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$petsCount ${petsCount == 1 ? "Pet" : "Pets"}',
                  style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text("CPF: $cpf"),

          const SizedBox(height: 8),
          _info(Icons.phone, phone),
          _info(Icons.mail_outline, email),
          _info(Icons.location_on_outlined, address),

          const Divider(height: 24, color: Color(0x22000000)),

          Text("Cadastrado em:",
              style: TextStyle(color: Colors.black.withOpacity(.55))),
          Text(registerDate,
              style: const TextStyle(fontWeight: FontWeight.w700)),

          const SizedBox(height: 10),

          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onPets,
                icon: const Icon(Icons.favorite_border, size: 18, color: ClickVetColors.goldDark),
                label: const Text('Pets', style: TextStyle(color: ClickVetColors.goldDark)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ClickVetColors.gold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('Editar', style: TextStyle(color: ClickVetColors.goldDark)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ClickVetColors.gold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onCall,
                child: const Icon(Icons.phone, size: 18, color: ClickVetColors.goldDark),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ClickVetColors.gold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
        Text("Nenhum tutor encontrado", style: TextStyle(color: ClickVetColors.goldDark)),
        SizedBox(height: 4),
        Text("Tente alterar os termos de busca."),
      ],
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: ClickVetColors.gold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(40, 36),
      ),
      child: Icon(icon, size: 18, color: enabled ? ClickVetColors.goldDark : Colors.black26),
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
            borderRadius: BorderRadius.circular(10)),
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
      child: Text(label,
          style: const TextStyle(color: ClickVetColors.goldDark)),
    );
  }
}
