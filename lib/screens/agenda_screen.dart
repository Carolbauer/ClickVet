import 'package:flutter/material.dart';
import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/vet_scaffold.dart';

import '../widgets/app_drawer.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _selectedDate = DateTime(2025, 11, 20);

  /// Mock inicial de consultas
  final List<_Appointment> _appointments = [
    _Appointment(
      id: '1',
      date: DateTime(2025, 11, 20),
      time: '08:00',
      petName: 'Rex',
      breed: 'Labrador',
      owner: 'Pedro S.',
      ownerPhone: '(11) 98765-4321',
      status: AppointmentStatus.confirmed,
      type: 'Consulta de Rotina',
    ),
    _Appointment(
      id: '2',
      date: DateTime(2025, 11, 20),
      time: '09:30',
      petName: 'Maia',
      breed: 'Siamês',
      owner: 'Roberto R.',
      ownerPhone: '(11) 91234-5678',
      status: AppointmentStatus.pending,
      type: 'Vacinação',
    ),
    _Appointment(
      id: '3',
      date: DateTime(2025, 11, 20),
      time: '11:00',
      petName: 'Fred',
      breed: 'Pastor Alemão',
      owner: 'Roberto R.',
      ownerPhone: '(11) 91234-5678',
      status: AppointmentStatus.confirmed,
      type: 'Emergência',
    ),
    _Appointment(
      id: '4',
      date: DateTime(2025, 11, 20),
      time: '14:30',
      petName: 'Luna',
      breed: 'Golden Retriever',
      owner: 'Ana Silva',
      ownerPhone: '(11) 99876-5432',
      status: AppointmentStatus.confirmed,
      type: 'Exame',
    ),
    _Appointment(
      id: '5',
      date: DateTime(2025, 11, 20),
      time: '16:00',
      petName: 'Thor',
      breed: 'Bulldog',
      owner: 'Carla Santos',
      ownerPhone: '(11) 98888-7777',
      status: AppointmentStatus.pending,
      type: 'Cirurgia',
    ),
  ];

  void _changeDate(int deltaDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: deltaDays));
    });
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar consulta'),
        content: const Text(
          'Você tem certeza de que deseja confirmar esta consulta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        appointment.status = AppointmentStatus.confirmed;
      });
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
      setState(() {
        _appointments.removeWhere((a) => a.id == appointment.id);
      });
    }
  }

  void _editAppointment(_Appointment appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edição da consulta de ${appointment.petName} em breve.'),
      ),
    );
  }

  void _contactOwner(_Appointment appointment) {
    // Depois usar url_launcher para abrir WhatsApp.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contato do tutor: ${appointment.ownerPhone}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sameDayAppointments = _appointments.where((a) {
      return a.date.year == _selectedDate.year &&
          a.date.month == _selectedDate.month &&
          a.date.day == _selectedDate.day;
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    return VetScaffold(
      selectedKey: DrawerItemKey.home,
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
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
              child: sameDayAppointments.isEmpty
                  ? const _EmptyAgenda()
                  : ListView.builder(
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
                    if (status == AppointmentStatus.pending)
                      ElevatedButton.icon(
                        onPressed: () => onConfirm(appointment),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Confirmar'),
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
