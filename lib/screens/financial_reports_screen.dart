import 'package:flutter/material.dart';
import 'package:app/theme/clickvet_colors.dart';

// 👇 imports para gerar e visualizar PDF
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  DateTime _startDate = DateTime(2024, 1, 1);
  DateTime _endDate = DateTime(2024, 1, 31);

  // --- DADOS MOCKADOS (igual ao React) ---
  final double _totalRevenue = 45750.00;
  final double _totalExpenses = 18230.00;

  List<_RevenueCategory> get _revenueByCategory => const [
    _RevenueCategory('Consultas', 18500.00, 40.4),
    _RevenueCategory('Procedimentos', 15200.00, 33.2),
    _RevenueCategory('Vacinas', 6800.00, 14.9),
    _RevenueCategory('Produtos', 3250.00, 7.1),
    _RevenueCategory('Serviços', 2000.00, 4.4),
  ];

  List<_ExpenseCategory> get _expensesByCategory => const [
    _ExpenseCategory('Estoque', 8900.00, 48.8),
    _ExpenseCategory('Despesas Fixas', 5500.00, 30.2),
    _ExpenseCategory('Fornecedores', 2830.00, 15.5),
    _ExpenseCategory('Outros', 1000.00, 5.5),
  ];

  List<_TopService> get _topServices => const [
    _TopService('Consulta de Rotina', 123, 18500.00),
    _TopService('Cirurgias', 12, 14400.00),
    _TopService('Vacinação V10', 85, 6800.00),
    _TopService('Banho e Tosa', 67, 8040.00),
  ];

  List<_PaymentMethod> get _paymentMethods => const [
    _PaymentMethod('PIX', 18500.00, 40.4),
    _PaymentMethod('Cartão de Crédito', 15200.00, 33.2),
    _PaymentMethod('Dinheiro', 8050.00, 17.6),
    _PaymentMethod('Cartão de Débito', 4000.00, 8.8),
  ];

  double get _netProfit => _totalRevenue - _totalExpenses;

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

  void _generateReport() {
    // Aqui depois você pode filtrar dados reais.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Relatório gerado para o período selecionado.'),
      ),
    );
  }

  // 👇 Geração REAL de PDF (abre o compartilhamento/visualização)
  Future<void> _exportPdf() async {
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

              // Resumo
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
                  ['Faturamento', _formatMoney(_totalRevenue)],
                  ['Despesas', _formatMoney(_totalExpenses)],
                  ['Lucro Líquido', _formatMoney(_netProfit)],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 16),

              // Receitas por categoria
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
                data: _revenueByCategory
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

              // Despesas por categoria
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
                data: _expensesByCategory
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

              // Serviços mais realizados
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
                data: _topServices
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

              // Formas de pagamento
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
                data: _paymentMethods
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

      // Abre o diálogo de impressão/compartilhamento no emulador/celular
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
            // 👇 ícone no canto superior direito também exporta o PDF
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
            // ---- PERÍODO ----
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
                  onPressed: _generateReport,
                  icon: const Icon(Icons.calendar_month, color: Colors.white),
                  label: const Text(
                    'Gerar Relatório',
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

            const SizedBox(height: 16),

            // ---- FATURAMENTO ----
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
                    _formatMoney(_totalRevenue),
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

            // ---- DESPESAS E LUCRO ----
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
                          _formatMoney(_totalExpenses),
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
                          _formatMoney(_netProfit),
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

            // ---- RECEITAS POR CATEGORIA ----
            _SectionCard(
              title: 'Receitas por Categoria',
              icon: Icons.pie_chart_outline,
              child: Column(
                children: _revenueByCategory
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

            // ---- DESPESAS POR CATEGORIA ----
            _SectionCard(
              title: 'Despesas por Categoria',
              icon: Icons.pie_chart_outline,
              child: Column(
                children: _expensesByCategory
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

            // ---- SERVIÇOS MAIS REALIZADOS ----
            _SectionCard(
              title: 'Serviços Mais Realizados',
              child: Column(
                children: _topServices
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
                              '${_formatMoney(s.amount / s.count)} /un',
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

            // ---- FORMAS DE PAGAMENTO ----
            _SectionCard(
              title: 'Formas de Pagamento',
              child: Column(
                children: _paymentMethods
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

            // ---- EXPORTAR RELATÓRIO ----
            _SectionCard(
              title: 'Exportar Relatório',
              child: Column(
                children: [
                  SizedBox(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- MODELOS SIMPLES ----

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
              value: (percentage.clamp(0, 100)) / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }
}
