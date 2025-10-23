import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.userName,
    required this.crmv,
    this.onHome,
    this.onAgenda,
    this.onNewAppointment,
    this.onPatients,
    this.onSettings,
    this.onLogout,
  });

  final String userName;
  final String crmv;

  final VoidCallback? onHome;
  final VoidCallback? onAgenda;
  final VoidCallback? onNewAppointment;
  final VoidCallback? onPatients;
  final VoidCallback? onSettings;
  final VoidCallback? onLogout;

  static const kGold = Color(0xFF8C7A3E);
  static const kGoldDark = Color(0xFF6E5F2F);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            decoration: const BoxDecoration(color: kGold),
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
                subtitle: Text('CRMV: $crmv', style: const TextStyle(color: Colors.white70)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _item(Icons.home_outlined, 'Home', onHome),
                _item(Icons.calendar_month_outlined, 'Agenda', onAgenda),
                _item(Icons.add_circle_outline, 'Nova Consulta', onNewAppointment),
                _item(Icons.pets_outlined, 'Pacientes', onPatients),
                const Divider(height: 24),
                _item(Icons.settings_outlined, 'Configurações', onSettings),
                _item(Icons.logout, 'Sair', onLogout, iconColor: kGoldDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ListTile _item(IconData icon, String label, VoidCallback? onTap, {Color iconColor = kGold}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
