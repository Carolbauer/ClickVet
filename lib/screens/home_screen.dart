import 'package:app/screens/agenda_screen.dart';
import 'package:app/screens/financial_dashboard_screen.dart';
import 'package:app/screens/new_schedule_screen.dart';
import 'package:app/screens/patients_screen.dart';
import 'package:app/screens/profile_screen.dart';
import 'package:app/screens/tutors_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:app/widgets/app_drawer.dart';
import '../services/firebase_user_service.dart';
import 'package:app/screens/register_pet_screen.dart';

const kBg        = Color(0xFFF5F2ED);
const kGold      = Color(0xFFB8860B);
const kGoldLt    = Color(0xFFD4AF37);
const kGoldDark  = Color(0xFF8B6914);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final userService = UserService();
  int _currentIndex = 0;

  Stream<QuerySnapshot<Map<String, dynamic>>> _appointmentsStream(String vetUid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(vetUid)
        .collection('appointments')
        .orderBy('date')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: Text('Nenhum usuário logado.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userService.streamUser(user.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: kBg,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(
            backgroundColor: kBg,
            body: Center(child: Text('Perfil não encontrado.')),
          );
        }

        final data = snap.data!.data()!;
        final String name = (data['name'] ?? 'Veterinário') as String;
        final String crmv = (data['crmv'] ?? '-') as String;
        final photoUrl = data['photoUrl'] as String?;

        return Scaffold(
          backgroundColor: kBg,
          drawer: AppDrawer(
            userName: name,
            crmv: crmv,
            photoUrl: photoUrl,
            selectedKey: DrawerItemKey.home,
            onLogout: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sair'),
                  content: const Text('Deseja realmente sair da sua conta?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              try {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao sair: $e')),
                );
              }
            },
            onProfile: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            onTutorPatients: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TutorListScreen()),
              );
            },
            onPetRegister: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterPetScreen()),
              );
            },
            onPatients: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PatientsScreen()),
              );
            },
            onAgenda: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AgendaScreen()),
              );
            },
            onFinancialDashboard: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FinancialDashboardScreen()),
              );
            },
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

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _appointmentsStream(user.uid),
                    builder: (context, apSnap) {
                      if (apSnap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (apSnap.hasError) {
                        return Text('Erro ao carregar agenda: ${apSnap.error}');
                      }

                      final docs = apSnap.data?.docs ?? [];

                      final now = DateTime.now();
                      final todayList = docs.where((d) {
                        final m = d.data();
                        final ts = m['date'];
                        if (ts is! Timestamp) return false;
                        final dt = ts.toDate();
                        return dt.year == now.year &&
                            dt.month == now.month &&
                            dt.day == now.day;
                      }).toList();

                      if (todayList.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Nenhuma consulta agendada para hoje.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        );
                      }

                      return _AgendaCardFromFirestore(appointments: todayList);
                    },
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AgendaScreen()),
                        );
                      },
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
            onDestinationSelected: (i) {
              setState(() => _currentIndex = i);

              if (i == 1) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AgendaScreen()),
                );
                return;
              }

              if (i == 2) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewScheduleScreen()),
                );
                return;
              }

              if (i == 3) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PatientsScreen()),
                );
              }
            },
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
                label: 'Agendar',
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

class _AgendaCardFromFirestore extends StatelessWidget {
  const _AgendaCardFromFirestore({required this.appointments});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> appointments;

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmado':
        return Colors.green;
      case 'Pendente':
        return Colors.orange;
      case 'Concluído':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

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
          final m = appointments[index].data();

          final ts = m['date'] as Timestamp;
          final dt = ts.toDate();

          final time =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

          final petName = (m['petName'] ?? '—').toString();
          final petBreed = (m['petBreed'] ?? '').toString();
          final tutorName = (m['tutorName'] ?? '—').toString();
          final status = (m['status'] ?? 'Pendente').toString();

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
                      Text(
                        '$time - $petName ${petBreed.isNotEmpty ? "($petBreed)" : ""}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tutor: $tutorName',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
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
                  status,
                  style: TextStyle(
                    color: _statusColor(status),
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
