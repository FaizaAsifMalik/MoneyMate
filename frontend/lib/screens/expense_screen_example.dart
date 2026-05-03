import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../services/expense_service.dart';
import '../services/category_service.dart';


/// Maps a [CategoryModel] to a display color.
Color _colorForCategory(CategoryModel cat) {
  if (cat.colour != null && cat.colour!.isNotEmpty) {
    try {
      final hex = cat.colour!.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}
  }
  // Fallback palette keyed by name
  const palette = {
    'Food': Color(0xFF4A8C6F),
    'Shopping': AppColors.primaryDark,
    'Utilities': AppColors.primaryMid,
    'Transport': Color(0xFFD08040),
    'Health': AppColors.accentRed,
  };
  return palette[cat.name] ?? const Color(0xFF5A7A9A);
}

Color _colorForName(String name, List<CategoryModel> categories) {
  final match = categories.where((c) => c.name == name);
  if (match.isNotEmpty) return _colorForCategory(match.first);
  return const Color(0xFF5A7A9A);
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


String _formatDate(String iso) {
  try {
    final d = DateTime.parse(iso);
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  } catch (_) {
    return iso;
  }
}

/// Returns YYYY-MM-DD bounds for the selected period.
({String start, String end}) _periodRange(String period) {
  final now = DateTime.now();
  switch (period) {
    case 'Week':
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      return (
        start: monday.toIso8601String().substring(0, 10),
        end: sunday.toIso8601String().substring(0, 10),
      );
    case 'Year':
      return (
        start: '${now.year}-01-01',
        end: '${now.year}-12-31',
      );
    case 'Month':
    default:
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      return (
        start: '${now.year}-${now.month.toString().padLeft(2, '0')}-01',
        end:
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}',
      );
  }
}

// ─────────────────────────────────────────────────────────────
// EXPENSE SCREEN
// ─────────────────────────────────────────────────────────────

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  String _chartType = 'Pie';
  String _period = 'Month';

  bool _loadingExpenses = true;
  bool _loadingCategories = true;
  String? _error;

  List<ExpenseModel> _expenses = [];
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadCategories(), _loadExpenses()]);
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryService.getCategories(type: 'expense');
      if (mounted) setState(() { _categories = cats; _loadingCategories = false; });
    } catch (e) {
      if (mounted) setState(() { _loadingCategories = false; _error = e.toString(); });
    }
  }

  Future<void> _loadExpenses() async {
    final range = _periodRange(_period);
    try {
      final exps = await ExpenseService.getExpenses(
        startDate: range.start,
        endDate: range.end,
      );
      if (mounted) setState(() { _expenses = exps; _loadingExpenses = false; });
    } catch (e) {
      if (mounted) setState(() { _loadingExpenses = false; _error = e.toString(); });
    }
  }

  Future<void> _onPeriodChange(String p) async {
    setState(() { _period = p; _loadingExpenses = true; });
    await _loadExpenses();
  }

  // ── Computed values ─────────────────────────────────────────

  double get _totalSpent => _expenses.fold(0.0, (s, e) => s + e.amount);

  double get _highestEntry {
    if (_expenses.isEmpty) return 0;
    return _expenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
  }

  Map<String, double> get _catAmounts {
    final map = <String, double>{};
    for (final cat in _categories) {
      map[cat.name] = _expenses
          .where((e) => e.categoryName == cat.name)
          .fold(0.0, (s, e) => s + e.amount);
    }
    return map;
  }

  double _catPct(String name) {
    if (_totalSpent == 0) return 0;
    return (_catAmounts[name] ?? 0) / _totalSpent * 100;
  }

  // ── Category dialogs ────────────────────────────────────────

  void _addCategory() {
    final nameCtrl = TextEditingController();
    final iconCtrl = TextEditingController(text: 'category');
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
              _DialogField(ctrl: nameCtrl, label: 'Category name'),
              const SizedBox(height: 10),
              _DialogField(ctrl: iconCtrl, label: 'Icon name (material)'),
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
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMid),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await CategoryService.createCategory(
                    name: name,
                    type: 'expense',
                    icon: iconCtrl.text.trim().isEmpty
                        ? 'category'
                        : iconCtrl.text.trim(),
                    colour: pickedColour,
                  );
                  await _loadCategories();
                } catch (e) {
                  _showError('Failed to add category: $e');
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

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
              _DialogField(ctrl: ctrl, label: 'Category name'),
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
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMid),
              onPressed: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await CategoryService.updateCategory(cat.id,
                      name: name, colour: pickedColour);
                  await _loadCategories();
                  await _loadExpenses();
                } catch (e) {
                  _showError('Failed to update category: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

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
            await _loadAll();
          } catch (e) {
            _showError('Failed to delete category: $e');
          }
        },
        onNo: () => Navigator.pop(context),
      ),
    );
  }

  // ── Expense entry dialogs ───────────────────────────────────

  void _addEntry() {
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    CategoryModel? catChoice =
        _categories.isNotEmpty ? _categories.first : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.cardLight,
          title: const Text('Add Expense',
              style: TextStyle(color: AppColors.primaryDark)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(ctrl: descCtrl, label: 'Description'),
                const SizedBox(height: 10),
                _DialogField(
                    ctrl: amtCtrl,
                    label: 'Amount (Rs.)',
                    type: TextInputType.number),
                const SizedBox(height: 10),
                // Date picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Date: ${_formatDate(selectedDate.toIso8601String().substring(0, 10))}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setS(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 10),
                if (_categories.isNotEmpty)
                  DropdownButtonFormField<CategoryModel>(
                    value: catChoice,
                    decoration: _dropDeco('Category'),
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMid),
              onPressed: () async {
                final amt = double.tryParse(amtCtrl.text.trim());
                if (descCtrl.text.trim().isEmpty || amt == null) return;
                Navigator.pop(context);
                try {
                  final newExp = ExpenseModel(
                    id: 0,
                    amount: amt,
                    description: descCtrl.text.trim(),
                    categoryId: catChoice?.id,
                    date: selectedDate.toIso8601String().substring(0, 10),
                  );
                  await ExpenseService.addExpense(newExp);
                  await _loadExpenses();
                } catch (e) {
                  _showError('Failed to add expense: $e');
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editEntry(ExpenseModel entry) {
    final descCtrl = TextEditingController(text: entry.description);
    final amtCtrl = TextEditingController(text: entry.amount.toStringAsFixed(0));
    DateTime selectedDate = DateTime.tryParse(entry.date) ?? DateTime.now();
    CategoryModel? catChoice = _categories
        .where((c) => c.id == entry.categoryId)
        .isNotEmpty
        ? _categories.firstWhere((c) => c.id == entry.categoryId)
        : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.cardLight,
          title: const Text('Edit Expense',
              style: TextStyle(color: AppColors.primaryDark)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(ctrl: descCtrl, label: 'Description'),
                const SizedBox(height: 10),
                _DialogField(
                    ctrl: amtCtrl,
                    label: 'Amount (Rs.)',
                    type: TextInputType.number),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Date: ${_formatDate(selectedDate.toIso8601String().substring(0, 10))}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setS(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 10),
                if (_categories.isNotEmpty)
                  DropdownButtonFormField<CategoryModel>(
                    value: catChoice,
                    decoration: _dropDeco('Category'),
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMid),
              onPressed: () async {
                final amt = double.tryParse(amtCtrl.text.trim());
                if (amt == null) return;
                Navigator.pop(context);
                try {
                  await ExpenseService.updateExpense(entry.id, {
                    'amount': amt,
                    'description': descCtrl.text.trim(),
                    'date':
                        selectedDate.toIso8601String().substring(0, 10),
                    if (catChoice != null) 'categoryId': catChoice!.id,
                  });
                  await _loadExpenses();
                } catch (e) {
                  _showError('Failed to update expense: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteEntry(ExpenseModel entry) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        message:
            'Delete "${entry.description} – Rs. ${entry.amount.toStringAsFixed(0)}"?',
        onYes: () async {
          Navigator.pop(context);
          try {
            await ExpenseService.deleteExpense(entry.id);
            await _loadExpenses();
          } catch (e) {
            _showError('Failed to delete expense: $e');
          }
        },
        onNo: () => Navigator.pop(context),
      ),
    );
  }

  void _viewAll() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'All Expenses',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryDark),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: controller,
                children: _expenses
                    .map((e) => ListTile(
                          title: Text(e.description,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark)),
                          subtitle: Text(
                              '${e.categoryName ?? 'Uncategorized'}  •  ${_formatDate(e.date)}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight)),
                          trailing: Text(
                            '-Rs. ${e.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppColors.accentRed,
                                fontWeight: FontWeight.bold),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final catAmts = _catAmounts;
    final isLoading = _loadingExpenses || _loadingCategories;

    return SidebarScaffold(
      activeNav: 'Expenses',
      onLogout: () {},
      content: Column(
        children: [
          // ── Sticky Top Banner ──────────────────────────
          _TopBanner(
            period: _period,
            totalSpent: _totalSpent,
            highestEntry: _highestEntry,
            entryCount: _expenses.length,
            onPeriodChange: _onPeriodChange,
          ),

          // ── Scrollable Content ─────────────────────────
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
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
                                onPressed: () {
                                  setState(() => _error = null);
                                  _loadAll();
                                },
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Chart header
                              Row(
                                children: [
                                  const Text(
                                    'SPENDING CHART',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  _ToggleGroup(
                                    options: const ['Pie', 'Bar', 'Line'],
                                    selected: _chartType,
                                    onSelect: (v) =>
                                        setState(() => _chartType = v),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.cardLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _buildChart(catAmts),
                              ),

                              const SizedBox(height: 20),

                              _CategoryBreakdown(
                                categories: _categories,
                                catAmounts: catAmts,
                                totalSpent: _totalSpent,
                              ),

                              const SizedBox(height: 20),

                              // Categories section
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
                                  GestureDetector(
                                    onTap: _viewAll,
                                    child: const Text(
                                      'View all →',
                                      style: TextStyle(
                                          color: AppColors.primaryMid,
                                          fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _IconBtn(
                                      icon: Icons.add,
                                      tooltip: 'Add category',
                                      onTap: _addCategory),
                                ],
                              ),

                              const SizedBox(height: 10),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _categories
                                    .map((cat) => _CategoryChip(
                                          cat: cat,
                                          pct: _catPct(cat.name),
                                          onEdit: () => _editCategory(cat),
                                          onDelete: () =>
                                              _deleteCategory(cat),
                                        ))
                                    .toList(),
                              ),

                              const SizedBox(height: 24),

                              // Expenses section
                              Row(
                                children: [
                                  const Text(
                                    'EXPENSE ENTRIES',
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
                                      tooltip: 'Add expense',
                                      onTap: _addEntry),
                                ],
                              ),

                              const SizedBox(height: 10),

                              if (_expenses.isEmpty)
                                _EmptyState(period: _period)
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.expenseBadge,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.accentRed
                                            .withOpacity(0.3)),
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
                                              child: Text('Description',
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
                                          color: AppColors.accentRed),
                                      ..._expenses
                                          .asMap()
                                          .entries
                                          .map((me) {
                                        final idx = me.key;
                                        final e = me.value;
                                        final isLast =
                                            idx == _expenses.length - 1;
                                        return Column(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          e.description,
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 13,
                                                              color: AppColors
                                                                  .textDark),
                                                        ),
                                                        Text(
                                                          _formatDate(e.date),
                                                          style: const TextStyle(
                                                              fontSize: 10,
                                                              color: AppColors
                                                                  .textLight),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: _CategoryBadge(
                                                      categoryName: e
                                                              .categoryName ??
                                                          'Uncategorized',
                                                      categories:
                                                          _categories,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      '-Rs. ${e.amount.toStringAsFixed(0)}',
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                        color: AppColors
                                                            .accentRed,
                                                      ),
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
                                                  color: AppColors.accentRed,
                                                  indent: 16,
                                                  endIndent: 16),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(Map<String, double> catAmts) {
    final nonEmpty =
        _categories.where((c) => (catAmts[c.name] ?? 0) > 0).toList();

    if (nonEmpty.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text('No data for this period',
              style: TextStyle(color: AppColors.textLight)),
        ),
      );
    }

    switch (_chartType) {
      case 'Bar':
        return _BarChart(categories: nonEmpty, catAmounts: catAmts);
      case 'Line':
        return _LineChart(entries: _expenses, categories: _categories);
      case 'Pie':
      default:
        return _PieChart(categories: nonEmpty, catAmounts: catAmts);
    }
  }

  InputDecoration _dropDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.inputBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
      );
}

// ─────────────────────────────────────────────────────────────
// TOP BANNER
// ─────────────────────────────────────────────────────────────

class _TopBanner extends StatelessWidget {
  final String period;
  final double totalSpent;
  final double highestEntry;
  final int entryCount;
  final Future<void> Function(String) onPeriodChange;

  const _TopBanner({
    required this.period,
    required this.totalSpent,
    required this.highestEntry,
    required this.entryCount,
    required this.onPeriodChange,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final periodLabel = period == 'Week'
        ? 'THIS WEEK'
        : period == 'Month'
            ? '${months[now.month - 1].toUpperCase()} ${now.year}'
            : 'YEAR ${now.year}';

    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
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
                      child: const Icon(Icons.trending_down,
                          color: AppColors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Expense Overview',
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
                  periodLabel,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${totalSpent.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total spent this ${period.toLowerCase()}',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _MiniStat(
                        label: 'Highest',
                        value: 'Rs. ${highestEntry.toStringAsFixed(0)}',
                        color: AppColors.accentRed),
                    const SizedBox(width: 20),
                    _MiniStat(
                        label: 'Transactions',
                        value: '$entryCount',
                        color: AppColors.accentPink),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ToggleGroup(
                options: const ['Week', 'Month', 'Year'],
                selected: period,
                onSelect: onPeriodChange,
              ),
              const SizedBox(height: 16),
              ProfileAvatar(),
              const SizedBox(height: 4),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.white.withOpacity(0.12),
                size: 48,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.white.withOpacity(0.5), fontSize: 10)),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'Courier')),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PIE CHART  (unchanged logic, types updated double)
// ─────────────────────────────────────────────────────────────

class _PieChart extends StatelessWidget {
  final List<CategoryModel> categories;
  final Map<String, double> catAmounts;

  const _PieChart({required this.categories, required this.catAmounts});

  @override
  Widget build(BuildContext context) {
    final total = catAmounts.values.fold(0.0, (a, b) => a + b);
    return Row(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CustomPaint(
            painter: _PiePainter(
              categories: categories,
              catAmounts: catAmounts,
              total: total,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories.map((c) {
              final amt = catAmounts[c.name] ?? 0;
              final pct =
                  total > 0 ? (amt / total * 100).toStringAsFixed(1) : '0';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: _colorForCategory(c),
                            borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(c.name,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textDark))),
                    Text('$pct%',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _colorForCategory(c))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<CategoryModel> categories;
  final Map<String, double> catAmounts;
  final double total;

  _PiePainter(
      {required this.categories,
      required this.catAmounts,
      required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    double startAngle = -math.pi / 2;

    for (final c in categories) {
      final amt = catAmounts[c.name] ?? 0;
      if (amt == 0) continue;
      final sweep = 2 * math.pi * amt / total;
      paint.color = _colorForCategory(c);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );
      startAngle += sweep;
    }

    paint.color = AppColors.cardLight;
    canvas.drawCircle(center, radius * 0.52, paint);
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.catAmounts != catAmounts || old.total != total;
}

// ─────────────────────────────────────────────────────────────
// BAR CHART
// ─────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<CategoryModel> categories;
  final Map<String, double> catAmounts;

  const _BarChart({required this.categories, required this.catAmounts});

  @override
  Widget build(BuildContext context) {
    final maxAmt =
        catAmounts.values.fold(0.0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: categories.map((c) {
          final amt = catAmounts[c.name] ?? 0;
          final frac = maxAmt > 0 ? amt / maxAmt : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    amt > 0 ? '${(amt / 1000).toStringAsFixed(1)}k' : '',
                    style: TextStyle(
                        fontSize: 9,
                        color: _colorForCategory(c),
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    height: frac * 130,
                    decoration: BoxDecoration(
                      color: _colorForCategory(c),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 8, color: AppColors.textMid),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LINE CHART
// ─────────────────────────────────────────────────────────────

class _LineChart extends StatelessWidget {
  final List<ExpenseModel> entries;
  final List<CategoryModel> categories;

  const _LineChart({required this.entries, required this.categories});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text('No data for this period',
              style: TextStyle(color: AppColors.textLight)),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _LinePainter(entries: entries, categories: categories),
        size: Size.infinite,
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<ExpenseModel> entries;
  final List<CategoryModel> categories;

  _LinePainter({required this.entries, required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    // ── Group entries by date, summing amounts per category per day ──
    // Build sorted list of unique dates across all entries
    final allDates = entries.map((e) => e.date.substring(0, 10)).toSet().toList()
      ..sort();
    if (allDates.isEmpty) return;

    // For each category, build a map of date -> total amount
    // catDailyAmounts[catName][dateStr] = totalAmt
    final catDailyAmounts = <String, Map<String, double>>{};
    for (final e in entries) {
      final name = e.categoryName ?? 'Uncategorized';
      final dateKey = e.date.substring(0, 10);
      catDailyAmounts.putIfAbsent(name, () => {});
      catDailyAmounts[name]![dateKey] =
          (catDailyAmounts[name]![dateKey] ?? 0) + e.amount;
    }

    // Global max across all categories and dates for y-axis scaling
    double maxAmt = 0;
    for (final dayMap in catDailyAmounts.values) {
      for (final v in dayMap.values) {
        if (v > maxAmt) maxAmt = v;
      }
    }
    if (maxAmt == 0) return;

    const padding = EdgeInsets.fromLTRB(36, 12, 8, 24);
    final chartW = size.width - padding.left - padding.right;
    final chartH = size.height - padding.top - padding.bottom;

    // ── Grid lines + Y-axis labels ──────────────────────────────────
    final gridPaint = Paint()
      ..color = AppColors.textLight.withOpacity(0.15)
      ..strokeWidth = 1;
    final labelStyle =
        TextStyle(color: AppColors.textLight.withOpacity(0.6), fontSize: 8);

    for (int i = 0; i <= 4; i++) {
      final y = padding.top + chartH * (1 - i / 4);
      canvas.drawLine(
          Offset(padding.left, y), Offset(size.width - padding.right, y), gridPaint);
      final val = (maxAmt * i / 4 / 1000).toStringAsFixed(1);
      final tp = TextPainter(
          text: TextSpan(text: '${val}k', style: labelStyle),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // ── Draw a line per category ────────────────────────────────────
    for (final cat in categories) {
      final dayMap = catDailyAmounts[cat.name];
      if (dayMap == null || dayMap.isEmpty) continue;

      // Build points at each date position (0 if category had no spending)
      final pts = allDates.asMap().entries.map((me) {
        final i = me.key;
        final dateStr = me.value;
        final amt = dayMap[dateStr] ?? 0.0;
        final x = padding.left +
            (allDates.length > 1
                ? chartW * i / (allDates.length - 1)
                : chartW / 2);
        final y = padding.top + chartH * (1 - amt / maxAmt);
        return Offset(x, y);
      }).toList();

      final color = _colorForCategory(cat);
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (pts.length == 1) {
        // Single data point — just draw a dot
        canvas.drawCircle(pts.first, 4, Paint()..color = color);
      } else {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (int i = 1; i < pts.length; i++) {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
        canvas.drawPath(path, linePaint);

        final dotPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        for (final pt in pts) {
          canvas.drawCircle(pt, 3, dotPaint);
        }
      }
    }

    // ── X-axis date labels ──────────────────────────────────────────
    final xLabelStyle =
        TextStyle(color: AppColors.textLight.withOpacity(0.7), fontSize: 8);
    // Show at most 6 labels to avoid crowding
    final step = math.max(1, (allDates.length / 6).ceil());
    for (int i = 0; i < allDates.length; i += step) {
      final x = padding.left +
          (allDates.length > 1
              ? chartW * i / (allDates.length - 1)
              : chartW / 2);
      final y = size.height - 14;
      final parts = _formatDate(allDates[i]).split(' ');
      final label = parts.length >= 2
          ? '${parts[0]} ${parts[1].replaceAll(',', '')}'
          : allDates[i];
      final tp = TextPainter(
          text: TextSpan(text: label, style: xLabelStyle),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.entries != entries;
}

// ─────────────────────────────────────────────────────────────
// CATEGORY BREAKDOWN BAR
// ─────────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final List<CategoryModel> categories;
  final Map<String, double> catAmounts;
  final double totalSpent;

  const _CategoryBreakdown({
    required this.categories,
    required this.catAmounts,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSpent == 0) return const SizedBox.shrink();
    final nonEmpty =
        categories.where((c) => (catAmounts[c.name] ?? 0) > 0).toList();
    if (nonEmpty.isEmpty) return const SizedBox.shrink();

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
            'SPENDING BREAKDOWN',
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
                children: nonEmpty.map((cat) {
                  final amt = (catAmounts[cat.name] ?? 0).round();
                  return Flexible(
                    flex: amt,
                    child: Container(color: _colorForCategory(cat)),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: nonEmpty.map((cat) {
              final amt = catAmounts[cat.name] ?? 0;
              final pct = (amt / totalSpent * 100).toStringAsFixed(1);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: _colorForCategory(cat),
                        borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 6),
                  Text('${cat.name}  $pct%',
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
// CATEGORY CHIP
// ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final CategoryModel cat;
  final double pct;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryChip({
    required this.cat,
    required this.pct,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForCategory(cat);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
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
              Text(cat.name,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              Text('${pct.toStringAsFixed(1)}%',
                  style:
                      TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEdit,
            child: Icon(Icons.edit_outlined,
                size: 13, color: color.withOpacity(0.7)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 13, color: color.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CATEGORY BADGE
// ─────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String categoryName;
  final List<CategoryModel> categories;

  const _CategoryBadge(
      {required this.categoryName, required this.categories});

  @override
  Widget build(BuildContext context) {
    final color = _colorForName(categoryName, categories);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        categoryName,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOGGLE GROUP
// ─────────────────────────────────────────────────────────────

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
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                o,
                style: TextStyle(
                  color:
                      isSelected ? AppColors.primaryDark : AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ICON BUTTON
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// DIALOG FIELD HELPER
// ─────────────────────────────────────────────────────────────

class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType type;

  const _DialogField({
    required this.ctrl,
    required this.label,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.inputBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined,
              size: 40, color: AppColors.textLight.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('No expenses for this ${period.toLowerCase()}',
              style: const TextStyle(
                  color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('Tap + above to add one.',
              style: TextStyle(color: AppColors.textLight, fontSize: 11)),
        ],
      ),
    );
  }
}