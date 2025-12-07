import 'package:app/screens/financial_reports_screen.dart';
import 'package:app/screens/financial_transactions_screen.dart';
import 'package:app/screens/inventory_screen.dart';
import 'package:app/screens/product_services_screen.dart';
import 'package:flutter/material.dart';
import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/vet_scaffold.dart';
import 'package:app/widgets/app_drawer.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  static const routeName = '/financial';

  @override
  State<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  String _selectedPeriod = 'month';

  // Mock de resumo financeiro
  final _financialSummary = const _FinancialSummary(
    totalRevenue: 45750.00,
    totalExpenses: 18230.00,
    netProfit: 27520.00,
    pendingReceivables: 8900.00,
  );

  // Mock de lançamentos recentes
  final List<_Transaction> _recentTransactions = const [
    _Transaction(
      id: 1,
      type: _TransactionType.income,
      description: 'Consulta - Rex',
      amount: 150.00,
      dateIso: '2024-01-28',
      category: 'Consulta',
    ),
    _Transaction(
      id: 2,
      type: _TransactionType.expense,
      description: 'Compra Vacinas',
      amount: 890.00,
      dateIso: '2024-01-27',
      category: 'Estoque',
    ),
    _Transaction(
      id: 3,
      type: _TransactionType.income,
      description: 'Cirurgia - Luna',
      amount: 1200.00,
      dateIso: '2024-01-27',
      category: 'Procedimento',
    ),
    _Transaction(
      id: 4,
      type: _TransactionType.income,
      description: 'Vacina - Thor',
      amount: 80.00,
      dateIso: '2024-01-26',
      category: 'Vacina',
    ),
    _Transaction(
      id: 5,
      type: _TransactionType.expense,
      description: 'Fornecedor Medicamentos',
      amount: 650.00,
      dateIso: '2024-01-25',
      category: 'Estoque',
    ),
  ];

  // Mock de itens com estoque baixo
  final List<_LowStockItem> _lowStockItems = const [
    _LowStockItem(
      id: 1,
      name: 'Vacina V10',
      quantity: 5,
      minStock: 10,
      type: 'Vacina',
    ),
    _LowStockItem(
      id: 2,
      name: 'Antibiótico Amoxicilina',
      quantity: 8,
      minStock: 15,
      type: 'Medicamento',
    ),
    _LowStockItem(
      id: 3,
      name: 'Ração Premium 15kg',
      quantity: 3,
      minStock: 10,
      type: 'Produto',
    ),
  ];

  String _formatMoney(double v) {
    // R$ 1.234,56
    final str = v.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $str';
  }

  String _formatDate(String iso) {
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

  void _showSoon(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => Navigator.of(context).pop(),
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
              _SummaryCard(
                iconBg: const Color(0xFFE5F9EC),
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF16A34A),
                title: 'Receitas',
                badgeText: '+15%',
                badgeBg: const Color(0xFFD1FAE5),
                badgeColor: const Color(0xFF166534),
                value: _formatMoney(_financialSummary.totalRevenue),
              ),
              const SizedBox(height: 10),
              _SummaryCard(
                iconBg: const Color(0xFFFEE2E2),
                icon: Icons.trending_down_rounded,
                iconColor: const Color(0xFFDC2626),
                title: 'Despesas',
                badgeText: '-8%',
                badgeBg: const Color(0xFFFECACA),
                badgeColor: const Color(0xFFB91C1C),
                value: _formatMoney(_financialSummary.totalExpenses),
              ),
              const SizedBox(height: 10),
              _ProfitCard(
                title: 'Lucro Líquido',
                value: _formatMoney(_financialSummary.netProfit),
                marginPercent: (_financialSummary.netProfit /
                    _financialSummary.totalRevenue *
                    100)
                    .toStringAsFixed(1),
              ),
              const SizedBox(height: 10),
              _SummaryCard(
                iconBg: const Color(0xFFFEF3C7),
                icon: Icons.receipt_long_outlined,
                iconColor: const Color(0xFFEAB308),
                title: 'Contas a Receber',
                badgeText: null,
                badgeBg: null,
                badgeColor: null,
                value: _formatMoney(_financialSummary.pendingReceivables),
              ),

              const SizedBox(height: 18),
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
                            builder: (_) =>
                            const InventoryScreen(),
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
                    onPressed: () => _showSoon(
                      context,
                      'Ver todos os lançamentos',
                    ),
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
              Column(
                children: _recentTransactions
                    .map(
                      (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _TransactionCard(
                      transaction: t,
                      formatMoney: _formatMoney,
                      formatDate: _formatDate,
                    ),
                  ),
                )
                    .toList(),
              ),

              if (_lowStockItems.isNotEmpty) ...[
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      onPressed: () => _showSoon(
                        context,
                        'Ver tela de estoque',
                      ),
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
                  children: _lowStockItems
                      .map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _LowStockCard(item: item),
                    ),
                  )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FinancialSummary {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final double pendingReceivables;

  const _FinancialSummary({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.pendingReceivables,
  });
}

enum _TransactionType { income, expense }

class _Transaction {
  final int id;
  final _TransactionType type;
  final String description;
  final double amount;
  final String dateIso;
  final String category;

  const _Transaction({
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                decoration: BoxDecoration(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
            crossAxisAlignment: CrossAxisAlignment.end,
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
          color: Color(0xFFEAB308),
          width: 1.6,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
            crossAxisAlignment: CrossAxisAlignment.end,
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
