import 'package:app/screens/patients_screen.dart';
import 'package:app/widgets/app_drawer.dart';
import 'package:app/screens/login_screen.dart';
import 'package:app/services/firebase_user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/register_pet_screen.dart';
import '../theme/clickvet_colors.dart';

class VetScaffold extends StatefulWidget {
  const VetScaffold({
    super.key,
    required this.selectedKey,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
  });

  final DrawerItemKey? selectedKey;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;

  @override
  State<VetScaffold> createState() => _VetScaffoldState();
}

class _VetScaffoldState extends State<VetScaffold> {
  final UserService _userService = UserService();
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;
  User? _vet;

  @override
  void initState() {
    super.initState();
    _vet = FirebaseAuth.instance.currentUser;

    if (_vet != null) {
      _userStream = _userService.streamUser(_vet!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vet == null) {
      return const Scaffold(
        backgroundColor: ClickVetColors.bg,
        body: Center(
          child: Text('Sessão expirada. Faça login novamente.'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: ClickVetColors.bg,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(
            backgroundColor: ClickVetColors.bg,
            body: Center(child: Text('Perfil não encontrado.')),
          );
        }

        final data = snap.data!.data()!;
        final name = (data['name'] ?? 'Veterinário') as String;
        final crmv = (data['crmv'] ?? '-') as String;

        return Scaffold(
          backgroundColor: ClickVetColors.bg,
          drawer: AppDrawer(
            userName: name,
            crmv: crmv,
            selectedKey: widget.selectedKey,

            onHome: () {
              Navigator.pop(context);
              if (widget.selectedKey == DrawerItemKey.home) {
                return;
              }
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
              );
            },

            onTutorPatients: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PatientsScreen(),
                ),
              );
            },

            onPetRegister: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RegisterPetScreen(),
                ),
              );
            },

            onPatients: (){
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PatientsScreen(),
                ),
              );
            },

            onSettings: () {
              Navigator.pop(context);
            },

            onLogout: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao sair: $e')),
                );
              }
            },
          ),
          appBar: widget.appBar,
          body: widget.body,
          bottomNavigationBar: widget.bottomNavigationBar,
        );
      },
    );
  }
}
