import 'package:app/widgets/app_drawer.dart';
import 'package:app/screens/login_screen.dart';
import 'package:app/services/firebase_user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/register_pet_screen.dart';
import '../theme/clickvet_colors.dart';


class VetScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final userService = UserService();
    final vet = FirebaseAuth.instance.currentUser;

    if (vet == null) {
      return const Scaffold(
        backgroundColor: ClickVetColors.bg,
        body: Center(
          child: Text('Sessão expirada. Faça login novamente.'),
        ),
      );
    }

    return StreamBuilder(
      stream: userService.streamUser(vet.uid),
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

        final data = snap.data!.data() as Map<String, dynamic>;
        final name = (data['name'] ?? 'Veterinário') as String;
        final crmv = (data['crmv'] ?? '-') as String;

        return Scaffold(
            backgroundColor: ClickVetColors.bg,
          drawer: AppDrawer(
            userName: name,
            crmv: crmv,
            selectedKey: selectedKey,
            onHome: () => Navigator.pop(context),
            onTutorPatients: () {},
            onPetRegister: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RegisterPetScreen(),
                ),
              );
            },
            onSettings: () {},
            onLogout: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao sair: $e')),
                );
              }
            },
          ),
          appBar: appBar,
          body: body,
          bottomNavigationBar: bottomNavigationBar,
        );
      },
    );
  }
}
