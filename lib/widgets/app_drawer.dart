import 'package:flutter/material.dart';
import 'package:app/theme/clickvet_colors.dart';

enum DrawerItemKey {
  home,
  agenda,
  patients,
  tutors,
  petRegister,
  profile,
  settings,
  newSchedule,
  financial,
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.userName,
    required this.crmv,
    this.photoUrl,
    this.selectedKey,
    this.onHome,
    this.onAgenda,
    this.onNewSChedule,
    this.onPatients,
    this.onTutorPatients,
    this.onPetRegister,
    this.onMedicalRecord,
    this.onProfile,
    this.onSettings,
    this.onLogout,
    this.onFinancialDashboard,
  });

  final String userName;
  final String crmv;
  final String? photoUrl;

  final DrawerItemKey? selectedKey;

  final VoidCallback? onProfile;
  final VoidCallback? onHome;
  final VoidCallback? onAgenda;
  final VoidCallback? onNewSChedule;
  final VoidCallback? onPatients;
  final VoidCallback? onTutorPatients;
  final VoidCallback? onPetRegister;
  final VoidCallback? onMedicalRecord;
  final VoidCallback? onSettings;
  final VoidCallback? onLogout;
  final VoidCallback? onFinancialDashboard;

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
                  colors: [ClickVetColors.goldLight, ClickVetColors.gold],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) {
                          final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
                          return CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white.withOpacity(.2),
                            backgroundImage: hasPhoto
                                ? NetworkImage(photoUrl!)
                                : null,
                            onBackgroundImageError: hasPhoto
                                ? (exception, stackTrace) {
                                    // Se houver erro ao carregar a imagem, mostra o ícone
                                  }
                                : null,
                            child: !hasPhoto
                                ? const Icon(Icons.person, size: 36, color: Colors.white)
                                : null,
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CRMV: ${crmv.isNotEmpty ? crmv : '—'}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Fechar',
                      ),
                    ],
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
                  keyItem: DrawerItemKey.petRegister,
                  icon: Icons.pets,
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
                _item(
                  context,
                  keyItem: DrawerItemKey.financial,
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Financeiro',
                  onTap: onFinancialDashboard,
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
                  leading: const Icon(
                    Icons.logout,
                    color: ClickVetColors.goldDark,
                  ),
                  title: const Text(
                    'Sair',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: onLogout,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
      leading: Icon(
        icon,
        color: ClickVetColors.goldDark,
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      tileColor: isSelected
          ? ClickVetColors.gold.withOpacity(0.10)
          : null,
      selected: isSelected,
      selectedTileColor: ClickVetColors.gold.withOpacity(0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: () {
        onTap?.call();
      },
    );
  }
}
