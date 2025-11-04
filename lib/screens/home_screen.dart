import 'package:app/screens/register_tutor_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/widgets/app_drawer.dart';
import '../services/firebase_user_service.dart';

const kCreme = Color(0xFFF7F2E6);
const kGold = Color(0xFF8C7A3E);
const kGoldDark = Color(0xFF6E5F2F);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final userService = UserService();

  int _currentIndex = 0;

  // MOCK de agenda
  final List<Map<String, dynamic>> _appointments = const [
    {
      'time': '08:00',
      'pet': 'Rex (Labrador)',
      'tutor': 'Pedro S.',
      'status': 'Confirmado',
      'statusColor': Colors.green,
    },
    {
      'time': '09:30',
      'pet': 'Maia (Siamês)',
      'tutor': 'Roberto R.',
      'status': 'Cancelado',
      'statusColor': Colors.red,
    },
    {
      'time': '11:00',
      'pet': 'Fred (Pastor Alemão)',
      'tutor': 'Roberto R.',
      'status': 'Confirmado',
      'statusColor': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: kCreme,
        body: Center(child: Text('Nenhum usuário logado.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userService.streamUser(user.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: kCreme,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(
            backgroundColor: kCreme,
            body: Center(child: Text('Perfil não encontrado.')),
          );
        }

        final data = snap.data!.data()!;
        final String name = (data['name'] ?? 'Veterinário') as String;
        final String crmv = (data['crmv'] ?? '-') as String;

        return Scaffold(
          backgroundColor: kCreme,
          drawer: AppDrawer(
            userName: name,
            crmv: crmv,
            onTutorPatients: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterTutorScreen()),
              );
            },
            onLogout: () => Navigator.pop(context),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (ctx) => IconButton(
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                          icon: const Icon(Icons.menu, size: 28, color: kGold),
                          splashRadius: 22,
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 110),
                        child: Image.asset(
                          'assets/images/logo1.png',
                          height: 150,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Olá! $name🐾',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kGold,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const _SearchField(),
                  const SizedBox(height: 20),

                  const Text(
                    'Agenda de Hoje',
                    style: TextStyle(
                      color: kGold,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _AgendaCard(appointments: _appointments),
                  const SizedBox(height: 20),

                  Center(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kGold),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Ver Agenda Completa',
                        style: TextStyle(
                          color: kGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          bottomNavigationBar: NavigationBar(
            height: 72,
            backgroundColor: Colors.white.withOpacity(0.85),
            indicatorColor: kGold.withOpacity(0.12),
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Agenda',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: 'Nova Consulta',
              ),
              NavigationDestination(
                icon: Icon(Icons.pets_outlined),
                selectedIcon: Icon(Icons.pets),
                label: 'Pacientes',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar paciente',
        prefixIcon: const Icon(Icons.search, color: kGold),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kGold, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kGoldDark, width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({required this.appointments});
  final List<Map<String, dynamic>> appointments;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGold, width: 1.2),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: appointments.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.black12.withOpacity(0.2)),
        itemBuilder: (_, index) {
          final a = appointments[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.event, color: kGold, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 14),
                          children: [
                            TextSpan(
                              text: '${a['time']} - ',
                              style:
                              const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(
                              text: a['pet'] as String,
                              style:
                              const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tutor: ${a['tutor']}',
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  a['status'] as String,
                  style: TextStyle(
                    color: (a['statusColor'] as Color),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
