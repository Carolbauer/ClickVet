import 'package:flutter/material.dart';
import 'package:app/theme/clickvet_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0); // último dia do mês
  }

  _FinancialReportData? _reportData;
  bool _isLoading = false;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatMoney(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (_, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ClickVetColors.gold,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (_, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ClickVetColors.gold,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<_FinancialReportData> _fetchReportData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end =
    DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('financial_entries')
        .orderBy('date', descending: false)
        .get();

    final filteredDocs = snap.docs.where((doc) {
      final data = doc.data();
      final ts = data['date'] as Timestamp?;
      if (ts == null) return false;
      final date = ts.toDate();
      return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
             date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    final entries = filteredDocs.map((d) {
      final m = d.data();
      final amountRaw = m['amount'] ?? 0;
      final double amount = amountRaw is int
          ? amountRaw.toDouble()
          : (amountRaw is double ? amountRaw : 0.0);

      return _FinancialEntry(
        amount: amount,
        type: (m['type'] ?? 'revenue').toString(),
        category: (m['category'] ?? 'Outros').toString(),
        serviceName: (m['serviceName'] ?? '').toString(),
        paymentMethod: (m['paymentMethod'] ?? '').toString(),
        date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();

    double totalRevenue = 0;
    double totalExpenses = 0;

    final Map<String, double> revenueByCat = {};
    final Map<String, double> expensesByCat = {};
    final Map<String, _ServiceAgg> servicesAgg = {};
    final Map<String, double> paymentAgg = {};

    for (final e in entries) {
      if (e.type == 'expense') {
        totalExpenses += e.amount;
        expensesByCat[e.category] =
            (expensesByCat[e.category] ?? 0) + e.amount;
      } else {
        totalRevenue += e.amount;
        revenueByCat[e.category] =
            (revenueByCat[e.category] ?? 0) + e.amount;

        if (e.serviceName != null && e.serviceName!.isNotEmpty) {
          final current =
              servicesAgg[e.serviceName!] ?? _ServiceAgg(count: 0, total: 0);
          servicesAgg[e.serviceName!] = _ServiceAgg(
            count: current.count + 1,
            total: current.total + e.amount,
          );
        }

        if (e.paymentMethod != null && e.paymentMethod!.isNotEmpty) {
          paymentAgg[e.paymentMethod!] =
              (paymentAgg[e.paymentMethod!] ?? 0) + e.amount;
        }
      }
    }

    final netProfit = totalRevenue - totalExpenses;

    final revenueList = revenueByCat.entries
        .map((e) => _RevenueCategory(
      e.key,
      e.value,
      totalRevenue > 0 ? (e.value / totalRevenue) * 100 : 0,
    ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final expensesList = expensesByCat.entries
        .map((e) => _ExpenseCategory(
      e.key,
      e.value,
      totalExpenses > 0 ? (e.value / totalExpenses) * 100 : 0,
    ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final topServicesList = servicesAgg.entries
        .map((e) => _TopService(e.key, e.value.count, e.value.total))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final paymentMethodsList = paymentAgg.entries
        .map((e) => _PaymentMethod(
      e.key,
      e.value,
      totalRevenue > 0 ? (e.value / totalRevenue) * 100 : 0,
    ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return _FinancialReportData(
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
      revenueByCategory: revenueList,
      expensesByCategory: expensesList,
      topServices: topServicesList,
      paymentMethods: paymentMethodsList,
      totalEntries: entries.length,
    );
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      final data = await _fetchReportData();
      if (!mounted) return;
      setState(() => _reportData = data);

      if (data.totalEntries == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não há lançamentos no período selecionado.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relatório atualizado com dados reais.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_reportData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gere o relatório antes de exportar o PDF.'),
        ),
      );
      return;
    }

    final data = _reportData!;

    try {
      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageTheme: const pw.PageTheme(
            margin: pw.EdgeInsets.all(24),
          ),
          build: (pw.Context context) {
            return [
              pw.Text(
                'Relatório Financeiro - ClickVet',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Período: ${_formatDate(_startDate)} até ${_formatDate(_endDate)}',
                style: pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 16),

              pw.Text(
                'Resumo do Período',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: ['Descrição', 'Valor'],
                data: [
                  ['Faturamento', _formatMoney(data.totalRevenue)],
                  ['Despesas', _formatMoney(data.totalExpenses)],
                  ['Lucro Líquido', _formatMoney(data.netProfit)],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 16),

              pw.Text(
                'Receitas por Categoria',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: ['Categoria', 'Valor', '%'],
                data: data.revenueByCategory
                    .map((r) => [
                  r.category,
                  _formatMoney(r.amount),
                  '${r.percentage.toStringAsFixed(1)}%',
                ])
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 16),

              pw.Text(
                'Despesas por Categoria',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: ['Categoria', 'Valor', '%'],
                data: data.expensesByCategory
                    .map((e) => [
                  e.category,
                  _formatMoney(e.amount),
                  '${e.percentage.toStringAsFixed(1)}%',
                ])
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 16),

              pw.Text(
                'Serviços Mais Realizados',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: ['Serviço', 'Qtd', 'Total'],
                data: data.topServices
                    .map((s) => [
                  s.name,
                  s.count.toString(),
                  _formatMoney(s.amount),
                ])
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 16),

              pw.Text(
                'Formas de Pagamento',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: ['Forma', 'Valor', '%'],
                data: data.paymentMethods
                    .map((m) => [
                  m.method,
                  _formatMoney(m.amount),
                  '${m.percentage.toStringAsFixed(1)}%',
                ])
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _reportData;

    return Scaffold(
      backgroundColor: ClickVetColors.bg,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ClickVetColors.goldDark,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Relatórios',
          style: TextStyle(
            color: ClickVetColors.gold,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _exportPdf,
            icon: const Icon(
              Icons.file_download,
              color: ClickVetColors.goldDark,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickStartDate,
                    child: _DateField(
                      label: 'Data Início',
                      value: _formatDate(_startDate),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickEndDate,
                    child: _DateField(
                      label: 'Data Fim',
                      value: _formatDate(_endDate),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ClickVetColors.goldLight, ClickVetColors.gold],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateReport,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : const Icon(Icons.calendar_month, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Carregando...' : 'Gerar Relatório',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ClickVetColors.goldLight, ClickVetColors.gold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: ClickVetColors.goldDark,
                  width: 1.6,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Faturamento do Período',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatMoney(data?.totalRevenue ?? 0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.redAccent, width: 1.6),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.trending_down,
                                color: Colors.redAccent, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Despesas',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatMoney(data?.totalExpenses ?? 0),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.green, width: 1.6),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.attach_money,
                                color: Colors.green, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Lucro Líquido',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatMoney(data?.netProfit ?? 0),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: 'Receitas por Categoria',
              icon: Icons.pie_chart_outline,
              child: Column(
                children:
                (data?.revenueByCategory ?? const <_RevenueCategory>[])
                    .map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CategoryRow(
                      label: item.category,
                      value: _formatMoney(item.amount),
                      percentage: item.percentage,
                      barColor: ClickVetColors.gold,
                      valueColor: Colors.black87,
                    ),
                  ),
                )
                    .toList(),
              ),
            ),

            const SizedBox(height: 12),

            _SectionCard(
              title: 'Despesas por Categoria',
              icon: Icons.pie_chart_outline,
              child: Column(
                children:
                (data?.expensesByCategory ?? const <_ExpenseCategory>[])
                    .map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CategoryRow(
                      label: item.category,
                      value: _formatMoney(item.amount),
                      percentage: item.percentage,
                      barColor: Colors.redAccent,
                      valueColor: Colors.redAccent,
                    ),
                  ),
                )
                    .toList(),
              ),
            ),

            const SizedBox(height: 12),

            _SectionCard(
              title: 'Serviços Mais Realizados',
              child: Column(
                children: (data?.topServices ?? const <_TopService>[])
                    .map(
                      (s) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ClickVetColors.bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${s.count} atendimentos',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatMoney(s.amount),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.count > 0
                                  ? '${_formatMoney(s.amount / s.count)} /un'
                                  : '—',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                    .toList(),
              ),
            ),

            const SizedBox(height: 12),

            _SectionCard(
              title: 'Formas de Pagamento',
              child: Column(
                children:
                (data?.paymentMethods ?? const <_PaymentMethod>[])
                    .map(
                      (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CategoryRow(
                      label: m.method,
                      value: _formatMoney(m.amount),
                      percentage: m.percentage,
                      barColor: ClickVetColors.goldDark,
                      valueColor: Colors.black87,
                    ),
                  ),
                )
                    .toList(),
              ),
            ),

            const SizedBox(height: 12),

            _SectionCard(
              title: 'Exportar Relatório',
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        ClickVetColors.goldLight,
                        ClickVetColors.gold,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _exportPdf,
                    icon: const Icon(Icons.description_outlined,
                        color: Colors.white),
                    label: const Text(
                      'Exportar em PDF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _FinancialEntry {
  final double amount;
  final String type;
  final String category;
  final String? serviceName;
  final String? paymentMethod;
  final DateTime date;

  _FinancialEntry({
    required this.amount,
    required this.type,
    required this.category,
    this.serviceName,
    this.paymentMethod,
    required this.date,
  });
}

class _FinancialReportData {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final List<_RevenueCategory> revenueByCategory;
  final List<_ExpenseCategory> expensesByCategory;
  final List<_TopService> topServices;
  final List<_PaymentMethod> paymentMethods;
  final int totalEntries;

  _FinancialReportData({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.revenueByCategory,
    required this.expensesByCategory,
    required this.topServices,
    required this.paymentMethods,
    required this.totalEntries,
  });
}

class _ServiceAgg {
  final int count;
  final double total;

  _ServiceAgg({required this.count, required this.total});
}

class _RevenueCategory {
  final String category;
  final double amount;
  final double percentage;

  const _RevenueCategory(this.category, this.amount, this.percentage);
}

class _ExpenseCategory {
  final String category;
  final double amount;
  final double percentage;

  const _ExpenseCategory(this.category, this.amount, this.percentage);
}

class _TopService {
  final String name;
  final int count;
  final double amount;

  const _TopService(this.name, this.count, this.amount);
}

class _PaymentMethod {
  final String method;
  final double amount;
  final double percentage;

  const _PaymentMethod(this.method, this.amount, this.percentage);
}

// ---- WIDGETS AUXILIARES ----

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.calendar_today,
            color: ClickVetColors.goldDark, size: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
          const BorderSide(color: ClickVetColors.gold, width: 1.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
              color: ClickVetColors.goldDark, width: 2.0),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.icon,
    required this.child,
  });

  final String title;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ClickVetColors.gold, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 18, color: ClickVetColors.goldDark),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: const TextStyle(
                  color: ClickVetColors.goldDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.value,
    required this.percentage,
    required this.barColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final double percentage;
  final Color barColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final pct = percentage.isNaN ? 0.0 : percentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (pct.clamp(0, 100)) / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${pct.toStringAsFixed(1)}%',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }
}
