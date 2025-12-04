import 'package:app/theme/clickvet_colors.dart';
import 'package:app/widgets/vet_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';

class ProductsServicesScreen extends StatefulWidget {
  const ProductsServicesScreen({super.key});

  static const routeName = '/products-services';

  @override
  State<ProductsServicesScreen> createState() =>
      _ProductsServicesScreenState();
}

class _ProductsServicesScreenState extends State<ProductsServicesScreen> {
  String _selectedTab = 'all';
  String _searchTerm = '';

  @override
  Widget build(BuildContext context) {
    return VetScaffold(
      selectedKey: DrawerItemKey.financial,
      appBar: AppBar(
        backgroundColor: ClickVetColors.bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ClickVetColors.goldDark,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Produtos e Serviços',
          style: TextStyle(
            color: ClickVetColors.goldDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 36,
              height: 36,
              child: ElevatedButton(
                onPressed: _openNewItem,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: ClickVetColors.gold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: ClickVetColors.bg,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: ClickVetColors.goldDark,
                      ),
                      hintText: 'Buscar serviços...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: ClickVetColors.gold,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: ClickVetColors.goldDark,
                          width: 1.8,
                        ),
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchTerm = v),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _CategoryChip(
                        label: 'Todos',
                        value: 'all',
                        selected: _selectedTab,
                        onSelected: (v) => setState(() => _selectedTab = v),
                      ),
                      _CategoryChip(
                        label: 'Consultas',
                        value: 'consulta',
                        selected: _selectedTab,
                        onSelected: (v) => setState(() => _selectedTab = v),
                      ),
                      _CategoryChip(
                        label: 'Procedimentos',
                        value: 'procedimento',
                        selected: _selectedTab,
                        onSelected: (v) => setState(() => _selectedTab = v),
                      ),
                      _CategoryChip(
                        label: 'Vacinas',
                        value: 'vacina',
                        selected: _selectedTab,
                        onSelected: (v) => setState(() => _selectedTab = v),
                      ),
                      _CategoryChip(
                        label: 'Estética',
                        value: 'estetica',
                        selected: _selectedTab,
                        onSelected: (v) => setState(() => _selectedTab = v),
                      ),
                      _CategoryChip(
                        label: 'Exames',
                        value: 'exame',
                        selected: _selectedTab,
                        onSelected: (v) => setState(() => _selectedTab = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            Expanded(
              child: _ProductsServicesStream(
                selectedTab: _selectedTab,
                searchTerm: _searchTerm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNewItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewServiceSheet(),
    );
  }
}

class _ProductsServicesStream extends StatelessWidget {
  const _ProductsServicesStream({
    required this.selectedTab,
    required this.searchTerm,
  });

  final String selectedTab;
  final String searchTerm;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'Você precisa estar logado para ver seus serviços.',
          style: TextStyle(color: ClickVetColors.goldDark),
        ),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('products_services')
        .orderBy('name');


    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Erro ao carregar serviços.',
              style: TextStyle(color: ClickVetColors.goldDark),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: ClickVetColors.gold,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final activeDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final isActive = data['isActive'] as bool?;
          return isActive == null || isActive == true;
        }).toList();

        final services = activeDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final name = (data['name'] ?? '') as String;
          final category = (data['category'] ?? '') as String;
          final cost = (data['cost'] as num?)?.toDouble() ?? 0;
          final price = (data['price'] as num?)?.toDouble() ?? 0;
          final duration = (data['duration'] ?? '') as String;
          final margin = (data['margin'] as num?)?.toDouble() ??
              (cost > 0 ? ((price - cost) / cost) * 100 : 0);

          return _ServiceItem(
            id: doc.id,
            name: name,
            category: category,
            cost: cost,
            price: price,
            duration: duration,
            margin: margin,
          );
        }).toList();

        final filtered = services.where((s) {
          final matchesTerm = s.name
              .toLowerCase()
              .contains(searchTerm.toLowerCase().trim());
          final matchesTab =
              selectedTab == 'all' || s.category == selectedTab;
          return matchesTerm && matchesTab;
        }).toList();

        final averageMargin = filtered.isEmpty
            ? 0.0
            : filtered.fold(0.0, (sum, s) => sum + s.margin) /
            filtered.length;

        final totalPotential = filtered.fold(
          0.0,
              (sum, s) => sum + s.price,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.medical_services_outlined,
                    title: 'Serviços',
                    value: filtered.length.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Margem Média',
                    value: '${averageMargin.toStringAsFixed(0)}%',
                    valueColor: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SummaryCard(
              icon: Icons.attach_money_rounded,
              title: 'Potencial por Catálogo',
              value:
              'R\$ ${totalPotential.toStringAsFixed(2).replaceAll('.', ',')}',
            ),
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Text(
                  'Nenhum serviço cadastrado.\nUse o botão + para adicionar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ClickVetColors.goldDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ...filtered.map(
                    (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ServiceCard(item: s),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ServiceItem {
  final String id;
  final String name;
  final String category;
  final double cost;
  final double price;
  final String duration;
  final double margin;

  _ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.cost,
    required this.price,
    required this.duration,
    required this.margin,
  });
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool active = selected == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? ClickVetColors.gold : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ClickVetColors.gold, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : ClickVetColors.goldDark,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClickVetColors.gold, width: 1.4),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F2ED),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ClickVetColors.goldDark, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item});

  final _ServiceItem item;

  @override
  Widget build(BuildContext context) {
    final profit = item.price - item.cost;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // futuro: edição do serviço
                },
                icon: const Icon(
                  Icons.edit,
                  size: 18,
                  color: ClickVetColors.goldDark,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 11,
                    color: ClickVetColors.goldDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.duration,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoCol(
                  label: 'Custo',
                  value: 'R\$ ${item.cost.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _InfoCol(
                  label: 'Preço',
                  value: 'R\$ ${item.price.toStringAsFixed(2)}',
                  valueColor: Colors.green.shade700,
                ),
              ),
              Expanded(
                child: _InfoCol(
                  label: 'Margem',
                  value: '${item.margin.toStringAsFixed(0)}%',
                  valueColor: ClickVetColors.goldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lucro por atendimento:',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
              Text(
                'R\$ ${profit.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCol extends StatelessWidget {
  const _InfoCol({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
          const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _NewServiceSheet extends StatefulWidget {
  const _NewServiceSheet();

  @override
  State<_NewServiceSheet> createState() => _NewServiceSheetState();
}

class _NewServiceSheetState extends State<_NewServiceSheet> {
  final _nameCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _category = 'consulta';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: ClickVetColors.gold,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: ClickVetColors.goldDark,
          width: 1.6,
        ),
      ),
    );
  }

  double? get _cost =>
      double.tryParse(_costCtrl.text.replaceAll(',', '.'));

  double? get _price =>
      double.tryParse(_priceCtrl.text.replaceAll(',', '.'));

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final cost = _cost;
    final price = _price;

    if (name.isEmpty || cost == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, custo e preço.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final profit = price - cost;
    final margin = (profit / cost) * 100;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('products_services')
          .add({
        'name': name,
        'category': _category,
        'cost': cost,
        'price': price,
        'duration': _durationCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'profit': profit,
        'margin': margin,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'ownerId': user.uid,
        'isActive': true,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serviço salvo com sucesso!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar no Firestore: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    final cost = _cost;
    final price = _price;
    double? margin;
    double? profit;

    if (cost != null && price != null && cost > 0) {
      profit = price - cost;
      margin = (profit / cost) * 100;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottom + 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: ClickVetColors.bg,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const Text(
                  'Novo Produto/Serviço',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ClickVetColors.goldDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cadastre um novo serviço com valores e margem.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _nameCtrl,
                  decoration: _deco('Nome do serviço/produto'),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: _deco('Categoria'),
                  items: const [
                    DropdownMenuItem(
                        value: 'consulta', child: Text('Consulta')),
                    DropdownMenuItem(
                        value: 'procedimento',
                        child: Text('Procedimento')),
                    DropdownMenuItem(
                        value: 'vacina', child: Text('Vacina')),
                    DropdownMenuItem(
                        value: 'estetica', child: Text('Estética')),
                    DropdownMenuItem(
                        value: 'exame', child: Text('Exame')),
                  ],
                  onChanged: (v) =>
                      setState(() => _category = v ?? 'consulta'),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _costCtrl,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: _deco('Custo (R\$)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _priceCtrl,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: _deco('Preço (R\$)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _durationCtrl,
                  decoration: _deco('Duração (ex: 30 min)'),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _descCtrl,
                  decoration: _deco('Descrição (opcional)'),
                ),
                const SizedBox(height: 12),

                if (margin != null && profit != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ClickVetColors.gold,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Margem:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '${margin.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: ClickVetColors.goldDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Lucro:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              'R\$ ${profit.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: ClickVetColors.gold,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: ClickVetColors.goldDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ClickVetColors.gold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(46),
                        ),
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                            : const Text(
                          'Salvar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
