import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Firestore + Auth
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum TransactionType { all, entrada, saida }

class TransactionModel {
  final String description;
  final double amount;
  final String category;
  final String paymentMethod;
  final DateTime date;
  final TransactionType type;

  TransactionModel({
    required this.description,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.date,
    required this.type,
  });
}

class FinancialTransactionsScreen extends StatefulWidget {
  const FinancialTransactionsScreen({super.key});

  static const routeName = '/financial-transactions';

  @override
  State<FinancialTransactionsScreen> createState() =>
      _FinancialTransactionsScreenState();
}

class _FinancialTransactionsScreenState
    extends State<FinancialTransactionsScreen> {
  final _currencyFormat =
  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ', decimalDigits: 2);

  final TextEditingController _searchController = TextEditingController();
  TransactionType _filterType = TransactionType.all;

  // AGORA: lista mutável preenchida pelo Firestore
  List<TransactionModel> _transactions = [];

  StreamSubscription<QuerySnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _listenTransactions();
  }

  void _listenTransactions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Você pode exibir um SnackBar avisando que precisa logar
      return;
    }

    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('financial_entries')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        final rawAmount = data['amount'];
        final double amount = rawAmount is int
            ? rawAmount.toDouble()
            : (rawAmount is num ? rawAmount.toDouble() : 0.0);

        final typeStr = (data['type'] ?? 'revenue') as String;
        final TransactionType type = (typeStr == 'expense' || typeStr == 'saida')
            ? TransactionType.saida
            : TransactionType.entrada;

        return TransactionModel(
          description: (data['description'] ?? '') as String,
          amount: amount,
          category: (data['category'] ?? 'Outros') as String,
          paymentMethod: (data['paymentMethod'] ?? '') as String,
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          type: type,
        );
      }).toList();

      setState(() {
        _transactions = list;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> get _filteredTransactions {
    final term = _searchController.text.toLowerCase();

    return _transactions.where((t) {
      final matchesSearch = t.description.toLowerCase().contains(term) ||
          t.category.toLowerCase().contains(term);

      final matchesFilter =
          _filterType == TransactionType.all || t.type == _filterType;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  double get _totalEntradas => _filteredTransactions
      .where((t) => t.type == TransactionType.entrada)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalSaidas => _filteredTransactions
      .where((t) => t.type == TransactionType.saida)
      .fold(0.0, (sum, t) => sum + t.amount);

  void _openNewTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: _NewTransactionForm(
          onSave: (transaction) async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Faça login para salvar lançamentos.'),
                ),
              );
              return;
            }

            final typeString =
            transaction.type == TransactionType.entrada ? 'revenue' : 'expense';

            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('financial_entries')
                .add({
              'description': transaction.description,
              'amount': transaction.amount,
              'category': transaction.category,
              'paymentMethod': transaction.paymentMethod,
              'type': typeString,
              'date': Timestamp.fromDate(transaction.date),
              // opcional: 'createdAt': FieldValue.serverTimestamp(),
            });
            // O listener em _listenTransactions() atualiza a lista automaticamente
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF5F2ED);
    const primary = Color(0xFFB8860B);
    const primaryDark = Color(0xFF8B6914);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: primary, width: 2),
                ),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: primaryDark,
                          size: 26,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Lançamentos',
                        style: TextStyle(
                          color: primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _openNewTransactionModal,
                        icon: Container(
                          decoration: const BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar lançamentos...',
                      prefixIcon:
                      const Icon(Icons.search, color: primary, size: 22),
                      filled: true,
                      fillColor: backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                        const BorderSide(color: primary, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                        const BorderSide(color: primary, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                        const BorderSide(color: primaryDark, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _FilterChip(
                        label: 'Todos',
                        selected: _filterType == TransactionType.all,
                        selectedColor: primary,
                        onTap: () => setState(
                                () => _filterType = TransactionType.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Entradas',
                        selected: _filterType == TransactionType.entrada,
                        selectedColor: Colors.green.shade600,
                        onTap: () => setState(
                                () => _filterType = TransactionType.entrada),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Saídas',
                        selected: _filterType == TransactionType.saida,
                        selectedColor: Colors.red.shade600,
                        onTap: () => setState(
                                () => _filterType = TransactionType.saida),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ResumoCard(
                            title: 'Entradas',
                            icon: Icons.trending_up,
                            iconColor: Colors.green.shade600,
                            borderColor: Colors.green.shade500,
                            value: _currencyFormat.format(_totalEntradas),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ResumoCard(
                            title: 'Saídas',
                            icon: Icons.trending_down,
                            iconColor: Colors.red.shade600,
                            borderColor: Colors.red.shade500,
                            value: _currencyFormat.format(_totalSaidas),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: const Border.fromBorderSide(
                          BorderSide(color: primary, width: 2),
                        ),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), primary],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saldo do Período',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFormat
                                .format(_totalEntradas - _totalSaidas),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_filteredTransactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 64,
                              color: primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Nenhum lançamento encontrado',
                              style: TextStyle(
                                color: primaryDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tente ajustar os filtros de busca.',
                              style: TextStyle(
                                color: primaryDark.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: _filteredTransactions
                            .map(
                              (t) => _TransactionCard(
                            transaction: t,
                            currencyFormat: _currencyFormat,
                          ),
                        )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- widgets auxiliares --------------------

class _ResumoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;

  const _ResumoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: iconColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selectedColor;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : borderColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final NumberFormat currencyFormat;

  const _TransactionCard({
    required this.transaction,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isEntrada = transaction.type == TransactionType.entrada;
    final color = isEntrada ? Colors.green.shade600 : Colors.red.shade600;
    final bgCircle = isEntrada ? Colors.green.shade100 : Colors.red.shade100;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB8860B), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgCircle,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEntrada ? Icons.trending_up : Icons.trending_down,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8860B).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        transaction.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8B6914),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      transaction.paymentMethod,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isEntrada ? '+' : '-'} ${currencyFormat.format(transaction.amount).replaceFirst('R\$', '')}',
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(transaction.date),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewTransactionForm extends StatefulWidget {
  final void Function(TransactionModel) onSave;

  const _NewTransactionForm({required this.onSave});

  @override
  State<_NewTransactionForm> createState() => _NewTransactionFormState();
}

class _NewTransactionFormState extends State<_NewTransactionForm> {
  final _formKey = GlobalKey<FormState>();

  TransactionType _type = TransactionType.entrada;
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  String _category = 'Consulta';
  DateTime _date = DateTime.now();
  String _paymentMethod = 'Dinheiro';
  final TextEditingController _notesCtrl = TextEditingController();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(
      _amountCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
    );
    if (amount == null) return;

    final transaction = TransactionModel(
      description: _descriptionCtrl.text.trim(),
      amount: amount,
      category: _category,
      paymentMethod: _paymentMethod,
      date: _date,
      type: _type,
    );

    widget.onSave(transaction);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFB8860B);
    const primaryDark = Color(0xFF8B6914);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Novo Lançamento',
              style: TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Registre uma entrada ou saída financeira.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('Tipo'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<TransactionType>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Entrada'),
                    value: TransactionType.entrada,
                    groupValue: _type,
                    activeColor: primary,
                    onChanged: (val) =>
                        setState(() => _type = val ?? TransactionType.entrada),
                  ),
                ),
                Expanded(
                  child: RadioListTile<TransactionType>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Saída'),
                    value: TransactionType.saida,
                    groupValue: _type,
                    activeColor: primary,
                    onChanged: (val) =>
                        setState(() => _type = val ?? TransactionType.saida),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Descrição'),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                hintText: 'Ex: Consulta - Rex',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            const Text('Categoria'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                'Consulta',
                'Procedimento',
                'Vacina',
                'Produto',
                'Serviço',
                'Estoque',
                'Fixo',
                'Outros',
              ]
                  .map(
                    (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                ),
              )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Valor (R\$)'),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: '0,00',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Obrigatório';
                          }
                          final parsed = double.tryParse(
                            value
                                .replaceAll('.', '')
                                .replaceAll(',', '.'),
                          );
                          if (parsed == null) return 'Valor inválido';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data'),
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(_date),
                              ),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Forma de pagamento'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                'Dinheiro',
                'Cartão de Crédito',
                'Cartão de Débito',
                'PIX',
                'Transferência',
                'Boleto',
              ]
                  .map(
                    (m) => DropdownMenuItem(
                  value: m,
                  child: Text(m),
                ),
              )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _paymentMethod = value);
              },
            ),
            const SizedBox(height: 12),
            const Text('Observações (opcional)'),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Informações adicionais...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: primaryDark),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _submit,
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
