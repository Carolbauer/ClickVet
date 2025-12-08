import 'package:flutter/material.dart';
import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/vet_scaffold.dart';
import 'package:app/widgets/app_drawer.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  static const routeName = '/inventory';

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchTerm = '';
  String _selectedTab = 'all';

  // Lista de itens de estoque (mock)
  final List<_InventoryItem> _items = [
    _InventoryItem(
      id: 1,
      name: 'Vacina V10',
      type: 'vacina',
      quantity: 5,
      minStock: 10,
      cost: 25.00,
      price: 80.00,
      supplier: 'BioVet',
      batch: 'VAC2024-001',
      expiryDate: DateTime(2024, 12, 31),
    ),
    _InventoryItem(
      id: 2,
      name: 'Antibiótico Amoxicilina 500mg',
      type: 'medicamento',
      quantity: 8,
      minStock: 15,
      cost: 12.50,
      price: 35.00,
      supplier: 'FarmaVet',
      batch: 'MED2024-045',
      expiryDate: DateTime(2025, 6, 30),
    ),
    _InventoryItem(
      id: 3,
      name: 'Ração Premium 15kg',
      type: 'produto',
      quantity: 3,
      minStock: 10,
      cost: 85.00,
      price: 180.00,
      supplier: 'Pet Food Brasil',
      batch: 'RAC2024-120',
      expiryDate: DateTime(2024, 8, 15),
    ),
    _InventoryItem(
      id: 4,
      name: 'Vacina Antirrábica',
      type: 'vacina',
      quantity: 15,
      minStock: 10,
      cost: 18.00,
      price: 60.00,
      supplier: 'BioVet',
      batch: 'VAC2024-002',
      expiryDate: DateTime(2024, 11, 30),
    ),
    _InventoryItem(
      id: 5,
      name: 'Anti-inflamatório Meloxicam',
      type: 'medicamento',
      quantity: 20,
      minStock: 15,
      cost: 15.00,
      price: 42.00,
      supplier: 'FarmaVet',
      batch: 'MED2024-089',
      expiryDate: DateTime(2025, 3, 31),
    ),
    _InventoryItem(
      id: 6,
      name: 'Shampoo Antipulgas',
      type: 'produto',
      quantity: 12,
      minStock: 8,
      cost: 22.00,
      price: 55.00,
      supplier: 'Pet Care',
      batch: 'PRO2024-015',
      expiryDate: DateTime(2026, 1, 31),
    ),
    _InventoryItem(
      id: 7,
      name: 'Vermífugo Comprimido',
      type: 'medicamento',
      quantity: 25,
      minStock: 20,
      cost: 8.00,
      price: 25.00,
      supplier: 'FarmaVet',
      batch: 'MED2024-103',
      expiryDate: DateTime(2025, 9, 30),
    ),
    _InventoryItem(
      id: 8,
      name: 'Coleira Antipulgas',
      type: 'produto',
      quantity: 18,
      minStock: 10,
      cost: 32.00,
      price: 75.00,
      supplier: 'Pet Care',
      batch: 'PRO2024-027',
      expiryDate: DateTime(2026, 12, 31),
    ),
  ];

  String _newType = 'medicamento';
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  final _minStockCtrl = TextEditingController(text: '0');
  final _costCtrl = TextEditingController(text: '0,00');
  final _priceCtrl = TextEditingController(text: '0,00');
  final _supplierCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _validityCtrl = TextEditingController();
  DateTime? _validityDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _minStockCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    _supplierCtrl.dispose();
    _batchCtrl.dispose();
    _validityCtrl.dispose();
    super.dispose();
  }

  List<_InventoryItem> get _filteredItems {
    return _items.where((item) {
      final term = _searchTerm.toLowerCase();
      final matchesSearch = term.isEmpty ||
          item.name.toLowerCase().contains(term) ||
          item.supplier.toLowerCase().contains(term);

      final matchesTab =
      _selectedTab == 'all' ? true : item.type == _selectedTab;

      return matchesSearch && matchesTab;
    }).toList();
  }

  List<_InventoryItem> get _lowStockItems {
    return _filteredItems
        .where((item) => item.quantity <= item.minStock)
        .toList();
  }

  double get _totalValue {
    return _filteredItems.fold(
      0.0,
          (sum, item) => sum + (item.cost * item.quantity),
    );
  }

  double get _potentialRevenue {
    return _filteredItems.fold(
      0.0,
          (sum, item) => sum + (item.price * item.quantity),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'vacina':
        return Icons.vaccines_outlined;
      case 'medicamento':
        return Icons.medication_liquid_outlined;
      case 'produto':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'vacina':
        return const Color(0xFF2563EB); // azul
      case 'medicamento':
        return const Color(0xFF7C3AED); // roxo
      case 'produto':
        return const Color(0xFF16A34A); // verde
      default:
        return Colors.grey;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'vacina':
        return 'Vacina';
      case 'medicamento':
        return 'Medicamento';
      case 'produto':
        return 'Produto';
      default:
        return type;
    }
  }

  String _formatMoney(double v) {
    return 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  double _parseMoney(String text) {
    final clean = text.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(clean) ?? 0.0;
  }

  int _parseInt(String text) {
    return int.tryParse(text.trim()) ?? 0;
  }

  Future<void> _openNewItemDialog() async {
    _newType = 'medicamento';
    _nameCtrl.clear();
    _qtyCtrl.text = '0';
    _minStockCtrl.text = '0';
    _costCtrl.text = '0,00';
    _priceCtrl.text = '0,00';
    _supplierCtrl.clear();
    _batchCtrl.clear();
    _validityCtrl.clear();
    _validityDate = null;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 24),
                          const Expanded(
                            child: Text(
                              'Novo Item no Estoque',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: ClickVetColors.gold,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.black54,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Adicione um novo produto, medicamento ou vacina.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const _FieldLabel('Tipo'),
                      const SizedBox(height: 4),
                      _DropdownTipo(
                        value: _newType,
                        onChanged: (v) {
                          setState(() => _newType = v);
                        },
                      ),
                      const SizedBox(height: 12),

                      const _FieldLabel('Nome do Item'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _nameCtrl,
                        decoration: _modalInputDecoration(
                          hint: 'Ex: Vacina V10',
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Quantidade'),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _qtyCtrl,
                                  keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                                  decoration:
                                  _modalInputDecoration(hint: '0'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Estoque Mínimo'),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _minStockCtrl,
                                  keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                                  decoration:
                                  _modalInputDecoration(hint: '0'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Custo (R\$)'),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _costCtrl,
                                  keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration:
                                  _modalInputDecoration(hint: '0,00'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Preço Venda (R\$)'),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _priceCtrl,
                                  keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration:
                                  _modalInputDecoration(hint: '0,00'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      const _FieldLabel('Fornecedor'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _supplierCtrl,
                        decoration: _modalInputDecoration(
                          hint: 'Nome do fornecedor',
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Lote'),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _batchCtrl,
                                  decoration: _modalInputDecoration(
                                    hint: 'Ex: VAC2024-001',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Validade'),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _validityCtrl,
                                  readOnly: true,
                                  decoration: _modalInputDecoration(
                                    hint: 'dd/mm/aaaa',
                                  ).copyWith(
                                    suffixIcon: const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 18,
                                      color: ClickVetColors.goldDark,
                                    ),
                                  ),
                                  onTap: () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: now,
                                      firstDate: DateTime(now.year - 1),
                                      lastDate: DateTime(now.year + 10),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _validityDate = picked;
                                        _validityCtrl.text =
                                            _formatDate(picked);
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ClickVetColors.gold,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _handleSaveNewItem,
                          child: const Text(
                            'Salvar',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: ClickVetColors.gold,
                              width: 1.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: ClickVetColors.goldDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSaveNewItem() {
    if (_nameCtrl.text.trim().isEmpty || _validityDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha pelo menos Nome e Validade.'),
        ),
      );
      return;
    }

    final newItem = _InventoryItem(
      id: _items.length + 1,
      name: _nameCtrl.text.trim(),
      type: _newType,
      quantity: _parseInt(_qtyCtrl.text),
      minStock: _parseInt(_minStockCtrl.text),
      cost: _parseMoney(_costCtrl.text),
      price: _parseMoney(_priceCtrl.text),
      supplier: _supplierCtrl.text.trim(),
      batch: _batchCtrl.text.trim(),
      expiryDate: _validityDate!,
    );

    setState(() {
      _items.add(newItem);
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final low = _lowStockItems;

    return VetScaffold(
      selectedKey: DrawerItemKey.financial,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        title: const Text(
          'Estoque',
          style: TextStyle(
            color: ClickVetColors.gold,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        // 🔹 AGORA: botão de voltar em vez do menu
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ClickVetColors.goldDark,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _openNewItemDialog,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ClickVetColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1.3,
            thickness: 1.3,
            color: ClickVetColors.gold,
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
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar produtos...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: ClickVetColors.goldDark,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: ClickVetColors.gold,
                      width: 1.4,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: ClickVetColors.goldDark,
                      width: 1.8,
                    ),
                  ),
                ),
                onChanged: (v) {
                  setState(() => _searchTerm = v);
                },
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  _FilterChip(
                    label: 'Todos',
                    selected: _selectedTab == 'all',
                    onTap: () => setState(() => _selectedTab = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Vacinas',
                    selected: _selectedTab == 'vacina',
                    onTap: () => setState(() => _selectedTab = 'vacina'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Remédios',
                    selected: _selectedTab == 'medicamento',
                    onTap: () =>
                        setState(() => _selectedTab = 'medicamento'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Produtos',
                    selected: _selectedTab == 'produto',
                    onTap: () => setState(() => _selectedTab = 'produto'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.inventory_2_outlined,
                      iconColor: ClickVetColors.goldDark,
                      title: 'Itens',
                      value: filtered.length.toString(),
                      borderColor: ClickVetColors.gold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFCA8A04),
                      title: 'Baixo',
                      value: low.length.toString(),
                      borderColor: const Color(0xFFCA8A04),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.savings_outlined,
                      iconColor: ClickVetColors.goldDark,
                      title: 'Valor Estoque',
                      value: _formatMoney(_totalValue),
                      borderColor: ClickVetColors.gold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.attach_money_rounded,
                      iconColor: ClickVetColors.goldDark,
                      title: 'Valor Venda',
                      value: _formatMoney(_potentialRevenue),
                      borderColor: ClickVetColors.gold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (low.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEFCE8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFACC15),
                      width: 1.6,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_outlined,
                        color: Color(0xFFCA8A04),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${low.length} item(ns) com estoque baixo',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF854D0E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              if (filtered.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 54,
                          color: ClickVetColors.goldDark,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Nenhum item encontrado',
                          style: TextStyle(
                            color: ClickVetColors.goldDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tente ajustar os filtros de busca.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: filtered
                      .map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InventoryCard(
                        item: item,
                        typeIcon: _typeIcon(item.type),
                        typeColor: _typeColor(item.type),
                        typeLabel: _typeLabel(item.type),
                        formatMoney: _formatMoney,
                        formatDate: _formatDate,
                      ),
                    ),
                  )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryItem {
  final int id;
  final String name;
  final String type;
  final int quantity;
  final int minStock;
  final double cost;
  final double price;
  final String supplier;
  final String batch;
  final DateTime expiryDate;

  _InventoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.quantity,
    required this.minStock,
    required this.cost,
    required this.price,
    required this.supplier,
    required this.batch,
    required this.expiryDate,
  });
}

// ---------- WIDGETS AUXILIARES ----------

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? ClickVetColors.gold : Colors.white;
    final textColor = selected ? Colors.white : ClickVetColors.goldDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ClickVetColors.gold, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.borderColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.typeIcon,
    required this.typeColor,
    required this.typeLabel,
    required this.formatMoney,
    required this.formatDate,
  });

  final _InventoryItem item;
  final IconData typeIcon;
  final Color typeColor;
  final String typeLabel;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final hasLowStock = item.quantity <= item.minStock;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
          hasLowStock ? const Color(0xFFFACC15) : ClickVetColors.gold,
          width: 1.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  typeIcon,
                  color: typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: typeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (hasLowStock) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius:
                              BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Estoque Baixo',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFCA8A04),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantidade',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.quantity} un.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estoque Mín.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.minStock} un.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Custo Unit.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMoney(item.cost),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preço Venda',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMoney(item.price),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fornecedor:',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.supplier,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lote:',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.batch,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Validade:',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDate(item.expiryDate),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Margem de Lucro:',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
              Text(
                '${(((item.price - item.cost) / item.cost) * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: ClickVetColors.goldDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

InputDecoration _modalInputDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 11, color: Colors.black38),
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
      const BorderSide(color: ClickVetColors.gold, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
      const BorderSide(color: ClickVetColors.goldDark, width: 1.6),
    ),
  );
}

class _DropdownTipo extends StatelessWidget {
  const _DropdownTipo({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: const Border.fromBorderSide(
          BorderSide(color: ClickVetColors.gold, width: 1.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ClickVetColors.goldDark,
          ),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: const [
            DropdownMenuItem(
              value: 'medicamento',
              child: Text('Medicamento'),
            ),
            DropdownMenuItem(
              value: 'vacina',
              child: Text('Vacina'),
            ),
            DropdownMenuItem(
              value: 'produto',
              child: Text('Produto'),
            ),
          ],
        ),
      ),
    );
  }
}
