import 'package:app/screens/financial_reports_screen.dart';
import 'package:app/screens/financial_transactions_screen.dart';
import 'package:app/screens/inventory_screen.dart';
import 'package:app/screens/product_services_screen.dart';
import 'package:flutter/material.dart';
import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/vet_scaffold.dart';
import 'package:app/widgets/app_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  static const routeName = '/financial';

  @override
  State<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  String _selectedPeriod = 'month';

  String _formatMoney(double v) {
    final str = v.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $str';
  }

  String _formatDateFromIso(String iso) {
    try {
      final d = DateTime.parse(iso);
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yy = d.year.toString();
      return '$dd/$mm/$yy';
    } catch (_) {
      return iso;
    }
  }

  DateTime _periodStartDate() {
    final now = DateTime.now();
    if (_selectedPeriod == 'week') {
      return now.subtract(const Duration(days: 7));
    } else if (_selectedPeriod == 'year') {
      return DateTime(now.year, 1, 1);
    }
    // default: mês
    return DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return VetScaffold(
        selectedKey: DrawerItemKey.financial,
        appBar: AppBar(
          backgroundColor: ClickVetColors.bg,
          elevation: 0,
          title: const Text(
            'Financeiro',
            style: TextStyle(
              color: ClickVetColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'Você precisa estar logado para visualizar o financeiro.',
            style: TextStyle(
              color: ClickVetColors.goldDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // 🔹 Usa a mesma coleção da tela de lançamentos
    // Filtra por período no cliente (evita necessidade de índice composto no Firestore)
    final transactionsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('financial_entries')
        .orderBy('date', descending: true)
        .limit(200) // Limita para performance
        .snapshots();

    final inventoryStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('inventory')
        .snapshots();

    return VetScaffold(
      selectedKey: DrawerItemKey.financial,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text(
          'Financeiro',
          style: TextStyle(
            color: ClickVetColors.primary,
            fontSize: 20,
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
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: ClickVetColors.gold,
                  width: 1.3,
                ),
              ),
            ),
            child: Row(
              children: [
                _PeriodChip(
                  label: 'Semana',
                  selected: _selectedPeriod == 'week',
                  onPressed: () {
                    setState(() => _selectedPeriod = 'week');
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Mês',
                  selected: _selectedPeriod == 'month',
                  onPressed: () {
                    setState(() => _selectedPeriod = 'month');
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Ano',
                  selected: _selectedPeriod == 'year',
                  onPressed: () {
                    setState(() => _selectedPeriod = 'year');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: ClickVetColors.bg,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= LANÇAMENTOS / RESUMO =================
              StreamBuilder<QuerySnapshot>(
                stream: transactionsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'Erro ao carregar lançamentos.',
                      style: TextStyle(color: ClickVetColors.goldDark),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: CircularProgressIndicator(
                          color: ClickVetColors.gold,
                        ),
                      ),
                    );
                  }

                  final allDocs = snapshot.data?.docs ?? [];
                  final periodStart = _periodStartDate();
                  
                  // Filtrar por período no cliente (evita necessidade de índice composto)
                  final docs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final ts = data['date'] as Timestamp?;
                    if (ts == null) return false;
                    final d = ts.toDate();
                    return d.isAfter(periodStart.subtract(const Duration(seconds: 1))) &&
                           d.isBefore(DateTime.now().add(const Duration(seconds: 1)));
                  }).toList();

                  double totalRevenue = 0;
                  double totalExpenses = 0;
                  final List<_Transaction> recentTransactions = [];

                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};

                    final ts = data['date'] as Timestamp?;
                    if (ts == null) continue;
                    final d = ts.toDate();

                    final amount =
                        (data['amount'] as num?)?.toDouble() ?? 0.0;

                    final typeStr = (data['type'] ?? 'revenue') as String;
                    final desc =
                    (data['description'] ?? 'Sem descrição') as String;
                    final category =
                    (data['category'] ?? 'Outros') as String;

                    final type = (typeStr == 'expense' || typeStr == 'saida')
                        ? _TransactionType.expense
                        : _TransactionType.income;

                    if (type == _TransactionType.income) {
                      totalRevenue += amount;
                    } else {
                      totalExpenses += amount;
                    }

                    recentTransactions.add(
                      _Transaction(
                        id: doc.hashCode,
                        type: type,
                        description: desc,
                        amount: amount,
                        dateIso: d.toIso8601String(),
                        category: category,
                      ),
                    );
                  }

                  recentTransactions.sort(
                        (a, b) => b.dateIso.compareTo(a.dateIso),
                  );
                  final displayedTransactions =
                  recentTransactions.take(5).toList();

                  final netProfit = totalRevenue - totalExpenses;
                  final marginPercent = totalRevenue > 0
                      ? (netProfit / totalRevenue * 100).toStringAsFixed(1)
                      : '0,0';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryCard(
                        iconBg: const Color(0xFFE5F9EC),
                        icon: Icons.trending_up_rounded,
                        iconColor: const Color(0xFF16A34A),
                        title: 'Receitas',
                        badgeText: null, // por enquanto sem comparação %
                        badgeBg: null,
                        badgeColor: null,
                        value: _formatMoney(totalRevenue),
                      ),
                      const SizedBox(height: 10),
                      _SummaryCard(
                        iconBg: const Color(0xFFFEE2E2),
                        icon: Icons.trending_down_rounded,
                        iconColor: const Color(0xFFDC2626),
                        title: 'Despesas',
                        badgeText: null,
                        badgeBg: null,
                        badgeColor: null,
                        value: _formatMoney(totalExpenses),
                      ),
                      const SizedBox(height: 10),
                      _ProfitCard(
                        title: 'Lucro Líquido',
                        value: _formatMoney(netProfit),
                        marginPercent: marginPercent,
                      ),
                      const SizedBox(height: 18),

                      // AÇÕES RÁPIDAS
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.add,
                              label: 'Lançamento',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const FinancialTransactionsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.inventory_2_outlined,
                              label: 'Estoque',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const InventoryScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.bar_chart_outlined,
                              label: 'Relatórios',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const FinancialReportsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.shopping_cart_outlined,
                              label: 'Produtos',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const ProductsServicesScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lançamentos Recentes',
                            style: TextStyle(
                              color: ClickVetColors.goldDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const FinancialTransactionsScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Ver todos',
                              style: TextStyle(
                                color: ClickVetColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (displayedTransactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Nenhum lançamento encontrado para o período selecionado.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: displayedTransactions
                              .map(
                                (t) => Padding(
                              padding:
                              const EdgeInsets.only(bottom: 8.0),
                              child: _TransactionCard(
                                transaction: t,
                                formatMoney: _formatMoney,
                                formatDate: _formatDateFromIso,
                              ),
                            ),
                          )
                              .toList(),
                        ),
                    ],
                  );
                },
              ),

              // ================= ESTOQUE BAIXO =================
              const SizedBox(height: 22),
              StreamBuilder<QuerySnapshot>(
                stream: inventoryStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'Erro ao carregar estoque.',
                      style: TextStyle(color: ClickVetColors.goldDark),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final List<_LowStockItem> lowStockItems = docs
                      .map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>? ?? {};
                    final name =
                    (data['name'] ?? 'Sem nome') as String;
                    final quantity =
                        (data['quantity'] as num?)?.toInt() ?? 0;
                    final minStock =
                        (data['minStock'] as num?)?.toInt() ?? 0;
                    final type =
                    (data['type'] ?? 'Produto') as String;

                    return _LowStockItem(
                      id: doc.hashCode,
                      name: name,
                      quantity: quantity,
                      minStock: minStock,
                      type: type,
                    );
                  })
                      .where((item) => item.quantity <= item.minStock)
                      .toList();

                  if (lowStockItems.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estoque Baixo',
                            style: TextStyle(
                              color: ClickVetColors.goldDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const InventoryScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Ver estoque',
                              style: TextStyle(
                                color: ClickVetColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Column(
                        children: lowStockItems
                            .map(
                              (item) => Padding(
                            padding:
                            const EdgeInsets.only(bottom: 8.0),
                            child: _LowStockCard(item: item),
                          ),
                        )
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TransactionType { income, expense }

class _Transaction {
  final int id;
  final _TransactionType type;
  final String description;
  final double amount;
  final String dateIso;
  final String category;

  _Transaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.dateIso,
    required this.category,
  });
}

class _LowStockItem {
  final int id;
  final String name;
  final int quantity;
  final int minStock;
  final String type;

  const _LowStockItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.minStock,
    required this.type,
  });
}

// ----------------- WIDGETS AUXILIARES -----------------

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? ClickVetColors.gold : Colors.white;
    final textColor = selected ? Colors.white : ClickVetColors.goldDark;
    final borderColor = ClickVetColors.gold;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.badgeText,
    this.badgeBg,
    this.badgeColor,
  });

  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? badgeText;
  final Color? badgeBg;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClickVetColors.gold, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontSize: 11,
                      color: badgeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitCard extends StatelessWidget {
  const _ProfitCard({
    required this.title,
    required this.value,
    required this.marginPercent,
  });

  final String title;
  final String value;
  final String marginPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), ClickVetColors.gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: ClickVetColors.gold, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Margem: $marginPercent%',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onPressed,
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ClickVetColors.gold, width: 1.6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: ClickVetColors.goldDark,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: ClickVetColors.goldDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.formatMoney,
    required this.formatDate,
  });

  final _Transaction transaction;
  final String Function(double) formatMoney;
  final String Function(String) formatDate;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == _TransactionType.income;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClickVetColors.gold, width: 1.4),
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isIncome
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFECACA),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: isIncome
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    transaction.category,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'} ${formatMoney(transaction.amount)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isIncome
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
              Text(
                formatDate(transaction.dateIso),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.item});

  final _LowStockItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAB308),
          width: 1.6,
        ),
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE68A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication_liquid_outlined,
                  color: Color(0xFF92400E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.type,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                'Qtd: ${item.quantity}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Mín: ${item.minStock}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
