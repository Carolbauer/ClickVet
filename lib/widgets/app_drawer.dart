import 'package:flutter/material.dart';

enum DrawerItemKey {
  home,
  agenda,
  newAppointment,
  patients,
  tutors,
  petRegister,
  profile,
  settings, newSchedule,
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.userName,
    required this.crmv,
    this.selectedKey,
    this.onHome,
    this.onAgenda,
    this.onNewSChedule,
    this.onPatients,
    this.onTutorPatients,
    this.onPetRegister,
    this.onProfile,
    this.onSettings,
    this.onLogout,
  });

  final String userName;
  final String crmv;

  final DrawerItemKey? selectedKey;

  final VoidCallback? onHome;
  final VoidCallback? onAgenda;
  final VoidCallback? onNewSChedule;
  final VoidCallback? onPatients;
  final VoidCallback? onTutorPatients;
  final VoidCallback? onPetRegister;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;
  final VoidCallback? onLogout;

  // ClickVet cores
  static const kCvPrimary   = Color(0xFFB8860B); // dourado médio
  static const kCvLight     = Color(0xFFD4AF37); // dourado claro
  static const kCvSecondary = Color(0xFF8B6914); // dourado escuro
  static const kGoldDark    = Color(0xFF8B6914);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [kCvLight, kCvPrimary],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withOpacity(.2),
                    child: const Icon(Icons.person, size: 32, color: Colors.white),
                  ),
                  title: Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('CRMV: ', style: TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _item(
                  context,
                  keyItem: DrawerItemKey.home,
                  icon: Icons.home_outlined,
                  label: 'Home',
                  onTap: onHome,
                ),
                _item(
                  context,
                  keyItem: DrawerItemKey.agenda,
                  icon: Icons.calendar_month_outlined,
                  label: 'Agenda',
                  onTap: onAgenda,
                ),
                _item(
                  context,
                  keyItem: DrawerItemKey.newAppointment,
                  icon: Icons.add_circle_outline,
                  label: 'Nova Consulta',
                  onTap: onNewSChedule,
                ),
                _item(
                  context,
                  keyItem: DrawerItemKey.petRegister,
                  icon: Icons.pets_outlined,
                  label: 'Cadastrar Pet',
                  onTap: onPetRegister,
                ),
                _item(
                  context,
                  keyItem: DrawerItemKey.patients,
                  icon: Icons.pets_sharp,
                  label: 'Pacientes',
                  onTap: onPatients,
                ),
                _item(
                  context,
                  keyItem: DrawerItemKey.tutors,
                  icon: Icons.person_2_rounded,
                  label: 'Tutores',
                  onTap: onTutorPatients,
                ),
                if (onProfile != null)
                  _item(
                    context,
                    keyItem: DrawerItemKey.profile,
                    icon: Icons.person_outline,
                    label: 'Meu Perfil',
                    onTap: onProfile,
                  ),

                const Divider(height: 24),

                _item(
                  context,
                  keyItem: DrawerItemKey.settings,
                  icon: Icons.settings_outlined,
                  label: 'Configurações',
                  onTap: onSettings,
                ),

                ListTile(
                  leading: const Icon(Icons.logout, color: kGoldDark),
                  title: const Text('Sair', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ListTile _item(
      BuildContext context, {
        required DrawerItemKey keyItem,
        required IconData icon,
        required String label,
        VoidCallback? onTap,
      }) {
    final bool isSelected = selectedKey == keyItem;

    return ListTile(
      leading: Icon(icon, color: kCvSecondary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      tileColor: isSelected ? kCvPrimary.withOpacity(0.10) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.of(context).pop();
        onTap?.call();
      },
    );
  }
}
