import 'package:app/screens/medical_record_screen.dart';
import 'package:app/screens/new_evolution_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/vet_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_drawer.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _selectedDate = DateTime.now();

  void _changeDate(int deltaDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: deltaDays));
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _appointmentsStream(
      String vetUid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(vetUid)
        .collection('appointments')
        .orderBy('date')
        .snapshots();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatSelectedDate(DateTime d) {
    const weekdays = [
      'Domingo',
      'Segunda-Feira',
      'Terça-Feira',
      'Quarta-Feira',
      'Quinta-Feira',
      'Sexta-Feira',
      'Sábado',
    ];
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    final wd = weekdays[d.weekday % 7];
    final month = months[d.month - 1];
    final day = d.day.toString().padLeft(2, '0');
    final year = d.year;

    return '$wd, $day de $month de $year';
  }

  Future<void> _confirmAppointment(_Appointment appointment) async {
    final vet = FirebaseAuth.instance.currentUser;
    if (vet == null) return;

    if (appointment.status == AppointmentStatus.pending) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirmar e Iniciar Atendimento'),
          content: const Text(
            'Ao confirmar, você será direcionado para registrar a evolução desta consulta.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar e Atender'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(vet.uid)
            .collection('appointments')
            .doc(appointment.id)
            .update({
          'status': 'Em Atendimento',
          'confirmedAt': FieldValue.serverTimestamp(),
        });

        appointment.status = AppointmentStatus.inProgress;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao confirmar: $e')),
        );
        return;
      }
    }

    if (appointment.petId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível iniciar o atendimento: este agendamento não está vinculado a um pet.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    final finished = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NewEvolutionScreen(
          petId: appointment.petId,
          petName: appointment.petName,
          petBreed: appointment.breed,
          tutorName: appointment.owner,
        ),
      ),
    );

    if (finished == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(vet.uid)
            .collection('appointments')
            .doc(appointment.id)
            .update({'status': 'Concluído'});

        appointment.status = AppointmentStatus.done;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao concluir consulta: $e')),
        );
      }
    }
  }

  Future<void> _deleteAppointment(_Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir consulta'),
        content: const Text(
          'Essa ação não poderá ser desfeita. '
              'Deseja realmente excluir esta consulta da agenda?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final vet = FirebaseAuth.instance.currentUser;
      if (vet == null) return;

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(vet.uid)
            .collection('appointments')
            .doc(appointment.id)
            .delete();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
  }

  void _editAppointment(_Appointment appointment) async {
    final vet = FirebaseAuth.instance.currentUser;
    if (vet == null) return;

    const tiposPermitidos = [
      'Consulta de Rotina',
      'Emergência',
      'Cirurgia',
      'Vacinação',
      'Exame',
    ];

    final dateController = TextEditingController(
      text:
      '${appointment.date.day.toString().padLeft(2, '0')}/${appointment.date.month.toString().padLeft(2, '0')}/${appointment.date.year}',
    );
    final timeController = TextEditingController(
      text: appointment.time,
    );

    String _normalizarTipo(String raw) {
      final r = raw.toLowerCase();

      if (r.contains('rotina')) return 'Consulta de Rotina';
      if (r.contains('emerg')) return 'Emergência';
      if (r.contains('cirurg')) return 'Cirurgia';
      if (r.contains('vacin')) return 'Vacinação';
      if (r.contains('exame')) return 'Exame';

      return '';
    }

    String tipoConsulta = _normalizarTipo(appointment.type);
    if (!tiposPermitidos.contains(tipoConsulta)) {
      tipoConsulta = '';
    }

    Future<void> pickDate(BuildContext ctx) async {
      DateTime initial = appointment.date;

      final picked = await showDatePicker(
        context: ctx,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDate: initial,
      );

      if (picked != null) {
        dateController.text =
        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      }
    }

    Future<void> pickTime(BuildContext ctx) async {
      final now = TimeOfDay.now();
      final picked = await showTimePicker(
        context: ctx,
        initialTime: now,
        initialEntryMode: TimePickerEntryMode.input,
        builder: (ctx2, child) {
          return MediaQuery(
            data: MediaQuery.of(ctx2!).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );

      if (picked != null) {
        timeController.text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      }
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Editar consulta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Data',
                  ),
                  onTap: () => pickDate(dialogCtx),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: timeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Horário',
                  ),
                  onTap: () => pickTime(dialogCtx),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tipoConsulta.isEmpty ? null : tipoConsulta,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de consulta',
                  ),
                  items: tiposPermitidos
                      .map(
                        (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t),
                    ),
                  )
                      .toList(),
                  onChanged: (val) {
                    tipoConsulta = val ?? '';
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      try {
        final parts = dateController.text.split('/');
        if (parts.length != 3) {
          throw 'Data inválida';
        }
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        int hour = 0;
        int minute = 0;
        if (timeController.text.contains(':')) {
          final tp = timeController.text.split(':');
          hour = int.tryParse(tp[0]) ?? 0;
          minute = int.tryParse(tp[1]) ?? 0;
        }

        final newDate = DateTime(year, month, day, hour, minute);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(vet.uid)
            .collection('appointments')
            .doc(appointment.id)
            .update({
          'date': Timestamp.fromDate(newDate),
          'time': timeController.text.trim(),
          'tipoConsulta': tipoConsulta,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consulta atualizada com sucesso!'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar consulta: $e'),
          ),
        );
      }
    }
  }

  void _contactOwner(_Appointment appointment) async {
    var raw = appointment.ownerPhone.replaceAll(RegExp(r'\D'), '');

    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Telefone do tutor não cadastrado.'),
        ),
      );
      return;
    }

    if (!raw.startsWith('55')) {
      raw = '55$raw';
    }

    final uri = Uri.parse('https://wa.me/$raw');

    try {
      final can = await canLaunchUrl(uri);
      if (can) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        final telUri = Uri.parse('tel:$raw');
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir WhatsApp ou telefone.'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir contato: $e'),
        ),
      );
    }
  }

  AppointmentStatus _parseStatus(String? s) {
    switch (s) {
      case 'Confirmado':
        return AppointmentStatus.confirmed;
      case 'Em Atendimento':
        return AppointmentStatus.inProgress;
      case 'Concluído':
        return AppointmentStatus.done;
      default:
        return AppointmentStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vet = FirebaseAuth.instance.currentUser;
    if (vet == null) {
      return const Scaffold(
        backgroundColor: ClickVetColors.bg,
        body: Center(child: Text('Sessão expirada.')),
      );
    }

    return VetScaffold(
      selectedKey: DrawerItemKey.agenda,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text(
          'Agenda Completa',
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
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                decoration: BoxDecoration(
                  color: ClickVetColors.bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _changeDate(-1),
                      icon: const Icon(
                        Icons.chevron_left,
                        color: ClickVetColors.goldDark,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatSelectedDate(_selectedDate),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ClickVetColors.goldDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeDate(1),
                      icon: const Icon(
                        Icons.chevron_right,
                        color: ClickVetColors.goldDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _appointmentsStream(vet.uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data?.docs ?? [];

                  final sameDayAppointments = docs
                      .map((d) {
                    final m = d.data();
                    final ts = m['date'];

                    if (ts == null || ts is! Timestamp) return null;
                    final dt = ts.toDate();

                    return _Appointment(
                      id: d.id,
                      date: dt,
                      time: (m['time'] ?? '--:--').toString(),
                      petName: (m['petName'] ?? '—').toString(),
                      petId: (m['petId'] ?? '').toString(),
                      breed: (m['petBreed'] ?? '—').toString(),
                      owner: (m['tutorName'] ?? '—').toString(),
                      ownerPhone: (m['tutorPhone'] ??
                          m['tutorTelefone'] ??
                          m['telefoneTutor'] ??
                          m['phone'] ??
                          m['telefone'] ??
                          m['tel'] ??
                          m['ownerPhone'] ??
                          '')
                          .toString(),
                      status: _parseStatus(m['status']?.toString()),
                      type: (m['tipoConsulta'] ?? '—').toString(),
                    );
                  })
                      .whereType<_Appointment>()
                      .where((a) => _isSameDay(a.date, _selectedDate))
                      .toList()
                    ..sort((a, b) => a.date.compareTo(b.date));

                  if (sameDayAppointments.isEmpty) {
                    return const _EmptyAgenda();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: sameDayAppointments.length,
                    itemBuilder: (context, index) {
                      final a = sameDayAppointments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _AppointmentCard(
                          appointment: a,
                          onConfirm: _confirmAppointment,
                          onDelete: _deleteAppointment,
                          onEdit: _editAppointment,
                          onContact: _contactOwner,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AppointmentStatus { confirmed, pending, inProgress, done }

class _Appointment {
  _Appointment({
    required this.id,
    required this.date,
    required this.time,
    required this.petName,
    required this.petId,
    required this.breed,
    required this.owner,
    required this.ownerPhone,
    required this.status,
    required this.type,
  });

  final String id;
  final DateTime date;
  final String time;
  final String petName;
  final String petId;
  final String breed;
  final String owner;
  final String ownerPhone;
  AppointmentStatus status;
  final String type;
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onConfirm,
    required this.onDelete,
    required this.onEdit,
    required this.onContact,
  });

  final _Appointment appointment;
  final void Function(_Appointment) onConfirm;
  final void Function(_Appointment) onDelete;
  final void Function(_Appointment) onEdit;
  final void Function(_Appointment) onContact;

  Color _statusBg(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.confirmed:
        return const Color(0xFFE6F9EC);
      case AppointmentStatus.pending:
        return const Color(0xFFFFF4D6);
      case AppointmentStatus.inProgress:
        return const Color(0xFFE0F2FE);
      case AppointmentStatus.done:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _statusText(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.confirmed:
        return const Color(0xFF166534);
      case AppointmentStatus.pending:
        return const Color(0xFF92400E);
      case AppointmentStatus.inProgress:
        return const Color(0xFF1D4ED8);
      case AppointmentStatus.done:
        return const Color(0xFF4B5563);
    }
  }

  String _statusLabel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.confirmed:
        return 'Confirmado';
      case AppointmentStatus.pending:
        return 'Pendente';
      case AppointmentStatus.inProgress:
        return 'Em Atendimento';
      case AppointmentStatus.done:
        return 'Concluído';
    }
  }

  Color _typeDotColor(String t) {
    if (t == 'Consulta de Rotina') return Colors.green;
    if (t == 'Emergência') return Colors.red;
    if (t == 'Cirurgia') return Colors.purple;
    if (t == 'Vacinação') return Colors.blue;
    if (t == 'Exame') return Colors.orange;
    return ClickVetColors.gold;
  }

  @override
  Widget build(BuildContext context) {
    final status = appointment.status;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ClickVetColors.gold, width: 1.6),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Column(
              children: [
                Text(
                  appointment.time,
                  style: const TextStyle(
                    color: ClickVetColors.goldDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _typeDotColor(appointment.type),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.petName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appointment.breed,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBg(status),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: _statusText(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Tutor: ${appointment.owner}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tipo: ${appointment.type}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (status == AppointmentStatus.pending ||
                        status == AppointmentStatus.inProgress)
                      ElevatedButton.icon(
                        onPressed: () => onConfirm(appointment),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: Text(
                          status == AppointmentStatus.pending
                              ? 'Confirmar e Atender'
                              : 'Retomar Atendimento',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => onDelete(appointment),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Excluir',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => onEdit(appointment),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ClickVetColors.gold),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Editar',
                        style: TextStyle(color: ClickVetColors.goldDark),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => onContact(appointment),
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: ClickVetColors.goldDark,
                      ),
                      label: const Text(
                        'Contato',
                        style: TextStyle(color: ClickVetColors.goldDark),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ClickVetColors.gold),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.calendar_today_outlined,
              size: 60,
              color: ClickVetColors.gold,
            ),
            SizedBox(height: 10),
            Text(
              'Nenhuma consulta agendada',
              style: TextStyle(
                color: ClickVetColors.goldDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Não há consultas para esta data.',
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
