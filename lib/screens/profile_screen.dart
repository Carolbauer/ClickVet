import 'package:app/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/vet_scaffold.dart';
import 'package:app/widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _error;
  _VeterinarianData? _data;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Usuário não autenticado.';
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Dados de perfil não encontrados.';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      _data = _VeterinarianData.fromMap(data);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar perfil. Tente novamente.';
        _isLoading = false;
      });
      debugPrint('Erro _loadProfile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = const Center(
        child: CircularProgressIndicator(color: ClickVetColors.gold),
      );
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(
                color: ClickVetColors.goldDark,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: ClickVetColors.gold,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    } else {
      final data = _data!;
      body = Container(
        color: ClickVetColors.bg,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderSection(data: data),
              const SizedBox(height: 20),
              _ProfessionalInfoCard(data: data),
              const SizedBox(height: 16),
              _PersonalInfoCard(data: data),
              const SizedBox(height: 16),
              _ContactInfoCard(data: data),
              const SizedBox(height: 24),
              _ActionsSection(
                onProfileUpdated: _loadProfile,
              ),
            ],
          ),
        ),
      );
    }

    return VetScaffold(
      selectedKey: DrawerItemKey.profile,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text(
          'Meu Perfil',
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
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1.3,
            color: ClickVetColors.gold,
          ),
        ),
      ),
      body: body,
    );
  }
}


class _VeterinarianData {
  final String fullName;
  final String email;
  final String phone;
  final String crmv;
  final String cpf;
  final String cnpj;
  final bool isIndividual;
  final String? photoUrl;

  _VeterinarianData({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.crmv,
    required this.cpf,
    required this.cnpj,
    required this.isIndividual,
    required this.photoUrl,
  });

  factory _VeterinarianData.fromMap(Map<String, dynamic> map) {
    final type = (map['type'] ?? 'PF') as String;
    final doc = (map['doc'] ?? '') as String;
    final respCpf = (map['responsibleCpf'] ?? '') as String;
    final isPF = type == 'PF';

    return _VeterinarianData(
      fullName: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      crmv: (map['crmv'] ?? '') as String,
      cpf: isPF ? doc : respCpf,
      cnpj: isPF ? '' : doc,
      isIndividual: isPF,
      photoUrl: map['photoUrl'] as String?,
    );
  }
}


class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.data});

  final _VeterinarianData data;

  @override
  Widget build(BuildContext context) {
    final labelTipo = data.isIndividual ? 'Pessoa Física' : 'Pessoa Jurídica';

    Widget avatarChild;
    if (data.photoUrl != null && data.photoUrl!.isNotEmpty) {
      avatarChild = ClipOval(
        child: Image.network(
          data.photoUrl!,
          fit: BoxFit.cover,
          width: 96,
          height: 96,
          errorBuilder: (_, __, ___) {
            return const Icon(
              Icons.person,
              color: Colors.white,
              size: 46,
            );
          },
        ),
      );
    } else {
      avatarChild = const Icon(
        Icons.person,
        color: Colors.white,
        size: 46,
      );
    }

    return Column(
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4AF37), ClickVetColors.gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: avatarChild,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          data.fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ClickVetColors.goldDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ClickVetColors.gold,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            labelTipo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfessionalInfoCard extends StatelessWidget {
  const _ProfessionalInfoCard({required this.data});

  final _VeterinarianData data;

  @override
  Widget build(BuildContext context) {
    return _CardBase(
      title: 'Informações Profissionais',
      children: [
        _InfoRow(
          icon: Icons.badge_outlined,
          label: 'CRMV',
          value: data.crmv,
        ),
      ],
    );
  }
}

class _PersonalInfoCard extends StatelessWidget {
  const _PersonalInfoCard({required this.data});

  final _VeterinarianData data;

  @override
  Widget build(BuildContext context) {
    return _CardBase(
      title: 'Informações Pessoais',
      children: [
        _InfoRow(
          icon: Icons.person_outline,
          label: 'Nome Completo',
          value: data.fullName,
        ),
        const SizedBox(height: 10),
        _InfoRow(
          icon: Icons.credit_card,
          label: data.isIndividual ? 'CPF' : 'CNPJ',
          value: data.isIndividual ? data.cpf : data.cnpj,
        ),
        if (!data.isIndividual && data.cpf.isNotEmpty) ...[
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'CPF do Responsável',
            value: data.cpf,
          ),
        ],
      ],
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({required this.data});

  final _VeterinarianData data;

  @override
  Widget build(BuildContext context) {
    return _CardBase(
      title: 'Contato',
      children: [
        _InfoRow(
          icon: Icons.mail_outline,
          label: 'Email',
          value: data.email,
        ),
        const SizedBox(height: 10),
        _InfoRow(
          icon: Icons.phone,
          label: 'Telefone',
          value: data.phone,
        ),
      ],
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.onProfileUpdated,
    super.key,
  });

  final Future<void> Function() onProfileUpdated;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFD4AF37), ClickVetColors.gold],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              offset: Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const EditProfileScreen(),
              ),
            );

            if (updated == true) {
              await onProfileUpdated();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Editar Perfil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBase extends StatelessWidget {
  const _CardBase({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClickVetColors.gold, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ClickVetColors.goldDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: ClickVetColors.goldDark,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
