import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/income_model.dart';
import '../models/category_model.dart';
import '../services/income_service.dart';
import '../services/category_service.dart';

// ─────────────────────────────────────────────────────────────
// LOCAL CATEGORY COLOR HELPERS
// ─────────────────────────────────────────────────────────────

/// Resolves a [CategoryModel]'s colour: parses hex if present, else palette.
Color _colorForCategoryModel(CategoryModel cat) {
  if (cat.colour != null && cat.colour!.isNotEmpty) {
    try {
      final hex = cat.colour!.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}
  }
  const palette = [
    AppColors.accentGreen,
    AppColors.primaryMid,
    AppColors.primaryDark,
    AppColors.accentRed,
    AppColors.accentPink,
  ];
  return palette[cat.name.hashCode.abs() % palette.length];
}

/// Resolves colour by name, looking up the full model list for hex data.
Color _colorForCategory(String name, List<CategoryModel> categories) {
  final match = categories.where((c) => c.name == name);
  if (match.isNotEmpty) return _colorForCategoryModel(match.first);
  const palette = [
    AppColors.accentGreen,
    AppColors.primaryMid,
    AppColors.primaryDark,
    AppColors.accentRed,
    AppColors.accentPink,
  ];
  return palette[name.hashCode.abs() % palette.length];
}

/// Preset swatches shown in the colour picker.
const _kColourSwatches = [
  '#4A8C6F', '#2E5EA8', '#C0392B', '#E67E22',
  '#8E44AD', '#16A085', '#D4A017', '#E91E8C',
];

/// Shows a simple colour-swatch picker dialog and returns the chosen hex.
Future<String?> _pickColour(BuildContext context, String? current) async {
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.cardLight,
      title: const Text('Pick a colour',
          style: TextStyle(color: AppColors.primaryDark)),
      content: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _kColourSwatches.map((hex) {
          final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
          final isSelected = current == hex;
          return GestureDetector(
            onTap: () => Navigator.pop(context, hex),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: AppColors.primaryDark, width: 3)
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  String _period = 'Month';
  String _selectedCategory = 'All';

  List<IncomeModel> _allEntries = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ── Data Loading ───────────────────────────────────────────

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        IncomeService.getIncomes(),
        CategoryService.getCategories(type: 'income'),
      ]);
      if (mounted) {
        setState(() {
          _allEntries = results[0] as List<IncomeModel>;
          _categories = results[1] as List<CategoryModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadIncomes() async {
    try {
      final incomes = await IncomeService.getIncomes();
      if (mounted) setState(() => _allEntries = incomes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh: $e')),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryService.getCategories(type: 'income');
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  // ── Filtering ──────────────────────────────────────────────

  List<IncomeModel> get _filteredEntries {
    final now = DateTime.now();
    return _allEntries.where((e) {
      final catMatch =
          _selectedCategory == 'All' || e.categoryName == _selectedCategory;
      final date = DateTime.tryParse(e.date);
      if (date == null) return catMatch;
      if (_period == 'Month') {
        return catMatch &&
            date.month == now.month &&
            date.year == now.year;
      } else {
        return catMatch && date.year == now.year;
      }
    }).toList();
  }

  List<String> get _categoryNames =>
      _categories.map((c) => c.name).toList();

  double get _totalIncome =>
      _filteredEntries.fold(0.0, (sum, e) => sum + e.amount);

  double get _avgIncome {
    if (_filteredEntries.isEmpty) return 0;
    if (_period == 'Month') return _totalIncome;
    final months =
        _filteredEntries.map((e) => e.date.substring(0, 7)).toSet();
    return months.isEmpty ? 0 : _totalIncome / months.length;
  }

  double get _highestIncome {
    if (_filteredEntries.isEmpty) return 0;
    return _filteredEntries
        .map((e) => e.amount)
        .reduce((a, b) => a > b ? a : b);
  }

  int get _entryCount => _filteredEntries.length;

  double _categoryTotal(String name) => _allEntries
      .where((e) => e.categoryName == name)
      .fold(0.0, (s, e) => s + e.amount);

  double get _grandTotal =>
      _allEntries.fold(0.0, (s, e) => s + e.amount);

  double _categoryPct(String name) {
    if (_grandTotal == 0) return 0;
    return (_categoryTotal(name) / _grandTotal) * 100;
  }

  // ── Add Category ──────────────────────────────────────────

  void _addCategory() {
    final nameCtrl = TextEditingController();
    String? pickedColour;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.cardLight,
          title: const Text('Add Category',
              style: TextStyle(color: AppColors.primaryDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: _inputDeco('Category name (e.g. Salary, Freelance)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Colour:', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final c = await _pickColour(ctx, pickedColour);
                      if (c != null) setS(() => pickedColour = c);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: pickedColour != null
                            ? Color(int.parse(
                                'FF${pickedColour!.replaceAll('#', '')}',
                                radix: 16))
                            : AppColors.primaryMid,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.textLight.withOpacity(0.4)),
                      ),
                      child: pickedColour == null
                          ? const Icon(Icons.colorize, size: 16,
                              color: AppColors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(pickedColour ?? 'tap to pick',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMid),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await CategoryService.createCategory(
                    name: name,
                    type: 'income',
                    icon: 'category',
                    colour: pickedColour,
                  );
                  await _loadCategories();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add category: $e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Category ─────────────────────────────────────────

  void _editCategory(CategoryModel cat) {
    final ctrl = TextEditingController(text: cat.name);
    String? pickedColour = cat.colour;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.cardLight,
          title: const Text('Edit Category',
              style: TextStyle(color: AppColors.primaryDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: _inputDeco('Category name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Colour:', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final c = await _pickColour(ctx, pickedColour);
                      if (c != null) setS(() => pickedColour = c);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: pickedColour != null
                            ? Color(int.parse(
                                'FF${pickedColour!.replaceAll('#', '')}',
                                radix: 16))
                            : AppColors.primaryMid,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.textLight.withOpacity(0.4)),
                      ),
                      child: pickedColour == null
                          ? const Icon(Icons.colorize, size: 16,
                              color: AppColors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(pickedColour ?? 'tap to pick',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMid),
              onPressed: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await CategoryService.updateCategory(cat.id,
                      name: name, colour: pickedColour);
                  if (_selectedCategory == cat.name) {
                    setState(() => _selectedCategory = name);
                  }
                  await _loadCategories();
                  await _loadIncomes();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update category: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete Category ───────────────────────────────────────

  void _deleteCategory(CategoryModel cat) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        message:
            'Delete category "${cat.name}"?\nAll its entries will also be affected.',
        onYes: () async {
          Navigator.pop(context);
          try {
            await CategoryService.deleteCategory(cat.id);
            if (_selectedCategory == cat.name) {
              setState(() => _selectedCategory = 'All');
            }
            await _loadCategories();
            await _loadIncomes();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete category: $e')),
              );
            }
          }
        },
        onNo: () => Navigator.pop(context),
      ),
    );
  }

  // ── Add Entry ──────────────────────────────────────────────

  void _addEntry() {
    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    CategoryModel? catChoice =
        _categories.isNotEmpty ? _categories.first : null;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.cardLight,
          title: const Text('Add Income Entry',
              style: TextStyle(color: AppColors.primaryDark)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Date: ${selectedDate.toIso8601String().substring(0, 10)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setS(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amtCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDeco('Amount (Rs.)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: _inputDeco('Description'),
                ),
                const SizedBox(height: 10),
                if (_categories.isNotEmpty)
                  DropdownButtonFormField<CategoryModel>(
                    value: catChoice,
                    decoration: _inputDeco('Category'),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setS(() => catChoice = v),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMid),
              onPressed: () async {
                final amt = double.tryParse(amtCtrl.text.trim());
                if (amt == null) return;
                Navigator.pop(ctx);
                try {
                  await IncomeService.addIncome(IncomeModel(
                    id: 0,
                    amount: amt,
                    description: descCtrl.text.trim(),
                    categoryId: catChoice?.id,
                    categoryName: catChoice?.name ?? 'Uncategorized',
                    date: selectedDate.toIso8601String().substring(0, 10),
                  ));
                  await _loadIncomes();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add income: $e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Entry ─────────────────────────────────────────────

  void _editEntry(IncomeModel entry) {
    final amtCtrl = TextEditingController(text: entry.amount.toStringAsFixed(0));
    final descCtrl = TextEditingController(text: entry.description);
    CategoryModel? catChoice = _categories.isNotEmpty
        ? (_categories.where((c) => c.id == entry.categoryId).isNotEmpty
            ? _categories.firstWhere((c) => c.id == entry.categoryId)
            : _categories.first)
        : null;
    DateTime selectedDate = DateTime.tryParse(entry.date) ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.cardLight,
          title: const Text('Edit Income Entry',
              style: TextStyle(color: AppColors.primaryDark)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Date: ${selectedDate.toIso8601String().substring(0, 10)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setS(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amtCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDeco('Amount (Rs.)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: _inputDeco('Description'),
                ),
                const SizedBox(height: 10),
                if (_categories.isNotEmpty)
                  DropdownButtonFormField<CategoryModel>(
                    value: catChoice,
                    decoration: _inputDeco('Category'),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setS(() => catChoice = v),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMid),
              onPressed: () async {
                final amt = double.tryParse(amtCtrl.text.trim());
                if (amt == null) return;
                Navigator.pop(ctx);
                try {
                  await IncomeService.updateIncome(entry.id, {
                    'amount': amt,
                    'description': descCtrl.text.trim(),
                    'date': selectedDate.toIso8601String().substring(0, 10),
                    if (catChoice != null) 'categoryId': catChoice!.id,
                  });
                  await _loadIncomes();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update income: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete Entry ───────────────────────────────────────────

  void _deleteEntry(IncomeModel entry) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        message:
            'Delete entry "${entry.date} – Rs. ${entry.amount.toStringAsFixed(0)}"?',
        onYes: () async {
          Navigator.pop(context);
          try {
            await IncomeService.deleteIncome(entry.id);
            await _loadIncomes();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete income: $e')),
              );
            }
          }
        },
        onNo: () => Navigator.pop(context),
      ),
    );
  }

  // ── Input Decoration Helper ────────────────────────────────

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.inputBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
      );

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;
    final now = DateTime.now();

    return SidebarScaffold(
      activeNav: 'Income',
      onLogout: () {},
      content: Column(
        children: [
          // ── Sticky Top Banner ──────────────────────────
          _TopBanner(
            period: _period,
            totalIncome: _totalIncome,
            currentMonth: now.month,
            currentYear: now.year,
            onPeriodChange: (v) => setState(() => _period = v),
          ),

          // ── Scrollable Content ─────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.accentGreen),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.accentRed)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadIncomes,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAll,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Stat cards
                                Row(
                                  children: [
                                    _StatCard(
                                      label: _period == 'Month'
                                          ? 'This Month'
                                          : 'Monthly Avg',
                                      value:
                                          'Rs. ${_avgIncome.toStringAsFixed(0)}',
                                      icon: Icons.trending_up,
                                      color: AppColors.primaryDark,
                                    ),
                                    const SizedBox(width: 12),
                                    _StatCard(
                                      label: 'Highest Entry',
                                      value:
                                          'Rs. ${_highestIncome.toStringAsFixed(0)}',
                                      icon: Icons.star_outline,
                                      color: AppColors.accentGreen,
                                    ),
                                    const SizedBox(width: 12),
                                    _StatCard(
                                      label: 'Transactions',
                                      value: '$_entryCount',
                                      icon: Icons.receipt_long_outlined,
                                      color: AppColors.accentRed,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Category breakdown
                                if (_categoryNames.isNotEmpty &&
                                    _grandTotal > 0)
                                  _CategoryBreakdown(
                                    categoryNames: _categoryNames,
                                    allEntries: _allEntries,
                                    totalIncome: _grandTotal,
                                    categories: _categories,
                                  ),

                                const SizedBox(height: 20),

                                // Category filter chips
                                Row(
                                  children: [
                                    const Text(
                                      'CATEGORIES',
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const Spacer(),
                                    _IconBtn(
                                      icon: Icons.add,
                                      tooltip: 'Add category',
                                      onTap: _addCategory,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _CategoryChip(
                                      label: 'All',
                                      color: AppColors.primaryMid,
                                      isSelected: _selectedCategory == 'All',
                                      onTap: () => setState(
                                          () => _selectedCategory = 'All'),
                                    ),
                                    ..._categoryNames.map((name) {
                                      final cat = _categories.isNotEmpty
                                          ? (_categories.where((c) => c.name == name).isNotEmpty
                                              ? _categories.firstWhere((c) => c.name == name)
                                              : null)
                                          : null;
                                      return _CategoryChip(
                                        label: name,
                                        color: _colorForCategory(name, _categories),
                                        isSelected: _selectedCategory == name,
                                        pct: _categoryPct(name),
                                        onTap: () => setState(
                                            () => _selectedCategory = name),
                                        onEdit: cat != null
                                            ? () => _editCategory(cat)
                                            : null,
                                        onDelete: cat != null
                                            ? () => _deleteCategory(cat)
                                            : null,
                                      );
                                    }),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Income entries list
                                Row(
                                  children: [
                                    const Text(
                                      'INCOME ENTRIES',
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const Spacer(),
                                    _IconBtn(
                                      icon: Icons.add,
                                      tooltip: 'Add entry',
                                      onTap: _addEntry,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                if (entries.isEmpty)
                                  _EmptyState(period: _period)
                                else
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.incomeBadge,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.accentGreen
                                              .withOpacity(0.5)),
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: const [
                                              Expanded(
                                                flex: 3,
                                                child: Text('Date',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        color:
                                                            AppColors.textMid)),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text('Category',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        color:
                                                            AppColors.textMid)),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text('Amount',
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        color:
                                                            AppColors.textMid)),
                                              ),
                                              SizedBox(width: 60),
                                            ],
                                          ),
                                        ),
                                        const Divider(
                                            height: 1,
                                            color: AppColors.accentGreen),
                                        ...entries.asMap().entries.map(
                                          (mapEntry) {
                                            final idx = mapEntry.key;
                                            final e = mapEntry.value;
                                            final isLast =
                                                idx == entries.length - 1;
                                            return Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 3,
                                                        child: Text(e.date,
                                                            style: const TextStyle(
                                                                fontSize: 13,
                                                                color: AppColors
                                                                    .textDark)),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: _CategoryBadge(
                                                            category: e
                                                                .categoryName,
                                                            categories:
                                                                _categories),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          'Rs. ${e.amount.toStringAsFixed(0)}',
                                                          textAlign:
                                                              TextAlign.right,
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 13,
                                                              color: AppColors
                                                                  .accentGreen),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          _IconBtn(
                                                            icon: Icons
                                                                .edit_outlined,
                                                            tooltip: 'Edit',
                                                            size: 16,
                                                            onTap: () =>
                                                                _editEntry(e),
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          _IconBtn(
                                                            icon: Icons
                                                                .delete_outline,
                                                            tooltip: 'Delete',
                                                            size: 16,
                                                            color: AppColors
                                                                .accentRed,
                                                            onTap: () =>
                                                                _deleteEntry(e),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (!isLast)
                                                  const Divider(
                                                      height: 1,
                                                      color:
                                                          AppColors.accentGreen,
                                                      indent: 16,
                                                      endIndent: 16),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BANNER
// ─────────────────────────────────────────────────────────────

class _TopBanner extends StatelessWidget {
  final String period;
  final double totalIncome;
  final int currentMonth;
  final int currentYear;
  final void Function(String) onPeriodChange;

  const _TopBanner({
    required this.period,
    required this.totalIncome,
    required this.currentMonth,
    required this.currentYear,
    required this.onPeriodChange,
  });

  String get _monthName {
    const months = [
      'JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC'
    ];
    return months[currentMonth - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: AppColors.primaryDark),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMid,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.trending_up,
                          color: AppColors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Income Overview',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  period == 'Month'
                      ? '$_monthName $currentYear'
                      : 'YEAR $currentYear',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${totalIncome.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  period == 'Month'
                      ? 'Total income this month'
                      : 'Total income this year',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ToggleGroup(
                options: const ['Month', 'Year'],
                selected: period,
                onSelect: onPeriodChange,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const NotificationBellIcon(),
                  const SizedBox(width: 10),
                  ProfileAvatar(),
                ],
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.white.withOpacity(0.15),
                size: 48,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CATEGORY BREAKDOWN BAR
// ─────────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final List<String> categoryNames;
  final List<IncomeModel> allEntries;
  final double totalIncome;
  final List<CategoryModel> categories;

  const _CategoryBreakdown({
    required this.categoryNames,
    required this.allEntries,
    required this.totalIncome,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    if (totalIncome == 0 || categoryNames.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INCOME BREAKDOWN',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Row(
                children: categoryNames.map((name) {
                  final catAmt = allEntries
                      .where((e) => e.categoryName == name)
                      .fold(0.0, (s, e) => s + e.amount);
                  final frac = catAmt / totalIncome;
                  return Flexible(
                    flex: (frac * 1000).round(),
                    child: Container(color: _colorForCategory(name, categories)),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: categoryNames.map((name) {
              final catAmt = allEntries
                  .where((e) => e.categoryName == name)
                  .fold(0.0, (s, e) => s + e.amount);
              final pct = totalIncome > 0
                  ? (catAmt / totalIncome * 100).toStringAsFixed(1)
                  : '0';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colorForCategory(name, categories),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('$name  $pct%',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textDark)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 10,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Courier')),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final double? pct;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CategoryChip({
    required this.label,
    required this.color,
    required this.isSelected,
    this.pct,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        color: isSelected ? AppColors.white : color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                if (pct != null)
                  Text('${pct!.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: isSelected
                              ? AppColors.white.withOpacity(0.8)
                              : color.withOpacity(0.7),
                          fontSize: 10)),
              ],
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEdit,
                child: Icon(Icons.edit_outlined,
                    size: 13,
                    color: isSelected
                        ? AppColors.white
                        : color.withOpacity(0.7)),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close,
                    size: 13,
                    color: isSelected
                        ? AppColors.white
                        : color.withOpacity(0.7)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  final List<CategoryModel> categories;

  const _CategoryBadge(
      {required this.category, required this.categories});

  @override
  Widget build(BuildContext context) {
    final color = _colorForCategory(category, categories);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(category,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _ToggleGroup extends StatelessWidget {
  final List<String> options;
  final String selected;
  final void Function(String) onSelect;

  const _ToggleGroup(
      {required this.options,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryMid.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final isSelected = o == selected;
          return GestureDetector(
            onTap: () => onSelect(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(o,
                  style: TextStyle(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final Color color;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 18,
    this.color = AppColors.textMid,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String period;
  const _EmptyState({required this.period});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined,
              size: 40, color: AppColors.textLight.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('No income entries for this $period',
              style:
                  const TextStyle(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('Tap + above to add one.',
              style:
                  TextStyle(color: AppColors.textLight, fontSize: 11)),
        ],
      ),
    );
  }
}