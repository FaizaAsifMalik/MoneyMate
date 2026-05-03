import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/budget_service.dart';
import '../services/expense_service.dart';
import '../services/category_service.dart';
import '../services/goal_service.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';

// ── Budget Dashboard ────────────────────────────────────────────────────────
class BudgetDashboardScreen extends StatefulWidget {
  const BudgetDashboardScreen({super.key});

  @override
  State<BudgetDashboardScreen> createState() =>
      _BudgetDashboardScreenState();
}

class _BudgetDashboardScreenState extends State<BudgetDashboardScreen> {
  String _period = 'Month';

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _budgets = [];
  List<CategoryModel> _expenseCategories = [];
  Map<int, double> _categorySpent = {};

  // Derived totals
  double get _totalBudget =>
      _budgets.fold(0.0, (s, b) => s + (double.tryParse(b['limit_amount']?.toString() ?? '0') ?? 0.0));

  double get _totalSpent => _categorySpent.values.fold(0.0, (a, b) => a + b);

  double get _totalLeft => _totalBudget - _totalSpent;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final now = DateTime.now();
      final startDate = _period == 'Month'
          ? '${now.year}-${now.month.toString().padLeft(2, '0')}-01'
          : '${now.year}-01-01';
      final endDate = _period == 'Month'
          ? '${now.year}-${now.month.toString().padLeft(2, '0')}-${DateTime(now.year, now.month + 1, 0).day}'
          : '${now.year}-12-31';

      final results = await Future.wait([
        BudgetService.getBudgets(),
        CategoryService.getCategories(type: 'expense'),
        ExpenseService.getSummary(startDate: startDate, endDate: endDate),
      ]);

      final budgets = results[0] as List<Map<String, dynamic>>;
      final cats = results[1] as List<CategoryModel>;
      final summary = results[2] as List<Map<String, dynamic>>;

      final spentMap = <int, double>{};
      for (final s in summary) {
        // category_id and total are the exact fields from getSummaryByCategory SQL
        final catId = s['category_id'];
        final id = catId is int ? catId : int.tryParse(catId?.toString() ?? '');
        final amt = double.tryParse(s['total']?.toString() ?? '0') ?? 0;
        if (id != null) spentMap[id] = amt;
      }

      if (mounted) {
        setState(() {
          _budgets = budgets;
          _expenseCategories = cats;
          _categorySpent = spentMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _colorForBudget(Map<String, dynamic> budget) {
    final catId = budget['category_id'] as int?;
    final cat = _expenseCategories.where((c) => c.id == catId).isNotEmpty
        ? _expenseCategories.firstWhere((c) => c.id == catId)
        : null;
    if (cat?.colour != null && cat!.colour!.isNotEmpty) {
      try {
        return Color(int.parse('FF${cat.colour!.replaceAll('#', '')}', radix: 16));
      } catch (_) {}
    }
    const palette = [
      Color(0xFF4A8C6F), Color(0xFF2E5EA8), Color(0xFFC0392B),
      Color(0xFFE67E22), Color(0xFF8E44AD), Color(0xFF16A085),
    ];
    return palette[(budget['budget_id'] as int? ?? 0) % palette.length];
  }

  String _catNameForBudget(Map<String, dynamic> budget) {
    final catId = budget['category_id'] as int?;
    final cat = _expenseCategories.where((c) => c.id == catId).isNotEmpty
        ? _expenseCategories.firstWhere((c) => c.id == catId)
        : null;
    return cat?.name ?? budget['name'] ?? 'Unnamed';
  }

  double _spentForBudget(Map<String, dynamic> budget) {
    final catId = budget['category_id'];
    final id = catId is int ? catId : int.tryParse(catId?.toString() ?? '');
    return id != null ? (_categorySpent[id] ?? 0.0) : 0.0;
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> budget) {
    final name = _catNameForBudget(budget);
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        message: 'Do you want to delete\nthe "$name" budget?',
        onYes: () async {
          Navigator.pop(context);
          try {
            await BudgetService.deleteBudget(budget['budget_id'] as int);
            await _loadAll();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete budget: $e')),
              );
            }
          }
        },
        onNo: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const monthNames = [
      'JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC'
    ];
    final periodLabel = _period == 'Month'
        ? '${monthNames[now.month - 1]} ${now.year}'
        : 'YEAR ${now.year}';

    final totalBudget = _totalBudget;
    final spent = _totalSpent;
    final left = _totalLeft;
    final progress = totalBudget > 0 ? (spent / totalBudget).clamp(0.0, 1.0) : 0.0;

    return SidebarScaffold(
      activeNav: 'Dashboard',
      onLogout: () {},
      content: Column(
        children: [
          // ── Sticky Top Banner ─────────────────────────────────────────────
          Container(
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
                            child: const Icon(Icons.account_balance_wallet,
                                color: AppColors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Budget Overview',
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
                        'Rs. ${totalBudget.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total budget this ${_period.toLowerCase()}',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _MiniStat(
                              label: 'Spent',
                              value: 'Rs. ${spent.toStringAsFixed(0)}',
                              color: AppColors.accentRed),
                          const SizedBox(width: 20),
                          _MiniStat(
                              label: 'Remaining',
                              value: 'Rs. ${left.toStringAsFixed(0)}',
                              color: AppColors.accentGreen),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppColors.white.withOpacity(0.2),
                          color: AppColors.accentGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Rs. ${spent.toStringAsFixed(0)} spent',
                              style: TextStyle(
                                  color: AppColors.white.withOpacity(0.6),
                                  fontSize: 11)),
                          const Spacer(),
                          Text('Rs. ${left.toStringAsFixed(0)} left',
                              style: TextStyle(
                                  color: AppColors.white.withOpacity(0.6),
                                  fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryMid.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ['Month', 'Year'].map((o) {
                          final sel = o == _period;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _period = o);
                              _loadAll();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(o,
                                  style: TextStyle(
                                      color: sel
                                          ? AppColors.primaryDark
                                          : AppColors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          );
                        }).toList(),
                      ),
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
                      Icons.pie_chart_outline,
                      color: AppColors.white.withOpacity(0.12),
                      size: 48,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Scrollable Content ─────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.accentGreen),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: const TextStyle(color: AppColors.accentRed)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadAll,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAll,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Categories
                              Row(
                                children: [
                                  const Text(
                                    'BUDGET PER CATEGORY',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddBudgetCategoryScreen(
                                          expenseCategories: _expenseCategories,
                                          onSave: (categoryId, limit, period) async {
                                            try {
                                              await BudgetService.createBudget(
                                                categoryId: categoryId,
                                                limit: limit,
                                                period: period,
                                              );
                                              await _loadAll();
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Failed to create budget: $e')),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    child: const Icon(Icons.add,
                                        size: 20, color: AppColors.textMid),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_budgets.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 32),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.pie_chart_outline,
                                          size: 36, color: AppColors.textLight),
                                      SizedBox(height: 10),
                                      Text('No budgets yet. Tap + to add one.',
                                          style: TextStyle(
                                              color: AppColors.textLight,
                                              fontSize: 13)),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.cardLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.primaryDark.withOpacity(0.12)),
                                  ),
                                  child: Column(
                                    children: _budgets.asMap().entries.map((entry) {
                                      final idx = entry.key;
                                      final b = entry.value;
                                      final isLast = idx == _budgets.length - 1;
                                      final catName = _catNameForBudget(b);
                                      final budgetLimit = double.tryParse(b['limit_amount']?.toString() ?? '0') ?? 0.0;
                                      final catSpent = _spentForBudget(b);
                                      final fraction = budgetLimit > 0
                                          ? (catSpent / budgetLimit).clamp(0.0, 1.0)
                                          : 0.0;
                                      final color = _colorForBudget(b);
                                      return Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: _BudgetCategoryRow(
                                              name: catName,
                                              budget: budgetLimit,
                                              spent: catSpent,
                                              fraction: fraction,
                                              color: color,
                                              onEdit: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => EditBudgetScreen(
                                                    budget: b,
                                                    categoryName: catName,
                                                    spent: catSpent,
                                                    color: color,
                                                    onSave: (limit, period) async {
                                                      try {
                                                        await BudgetService.updateBudget(
                                                          b['budget_id'] as int,
                                                          limit: limit,
                                                          period: period,
                                                        );
                                                        await _loadAll();
                                                      } catch (e) {
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Failed to update budget: $e')),
                                                          );
                                                        }
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                              onDelete: () => _showDeleteDialog(context, b),
                                            ),
                                          ),
                                          if (!isLast)
                                            Divider(
                                                height: 1,
                                                color: AppColors.primaryDark.withOpacity(0.08),
                                                indent: 12,
                                                endIndent: 12),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),

                              const SizedBox(height: 20),

                              // AI Suggestions
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/ai_screen'),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.auto_awesome,
                                          color: AppColors.white, size: 16),
                                      SizedBox(width: 8),
                                      Text('AI Suggestions',
                                          style: TextStyle(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/budget_goal'),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.primaryDark.withOpacity(0.15)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.flag_outlined,
                                          size: 16, color: AppColors.textMid),
                                      SizedBox(width: 8),
                                      Text(
                                        'No budget goal yet? Create it now →',
                                        style: TextStyle(
                                            color: AppColors.textLight, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Currency Converter
                              const Text(
                                'CURRENCY CONVERTER',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const _CurrencyConverter(),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Stat Widget (matches ExpenseScreen) ────────────────────────────────
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

// ── Currency Converter ──────────────────────────────────────────────────────
class _CurrencyConverter extends StatefulWidget {
  const _CurrencyConverter();

  @override
  State<_CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<_CurrencyConverter> {
  final _ctrl = TextEditingController();
  String _fromCurrency = 'PKR';

  // Approximate static rates relative to PKR
  static const Map<String, double> _ratesFromPKR = {
    'PKR': 1.0,
    'USD': 0.0036,
    'EUR': 0.0033,
    'GBP': 0.0028,
  };

  double _convert(double amount, String from, String to) {
    final inPKR = amount / (_ratesFromPKR[from] ?? 1.0);
    return inPKR * (_ratesFromPKR[to] ?? 1.0);
  }

  String _format(double val, String currency) {
    if (val >= 1000) {
      return '${val.toStringAsFixed(2)}';
    }
    return val.toStringAsFixed(4);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputAmount = double.tryParse(_ctrl.text) ?? 0.0;
    final currencies = ['PKR', 'USD', 'EUR', 'GBP'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.primaryDark.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Enter amount',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                          color: AppColors.textLight, fontSize: 13),
                    ),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _fromCurrency,
                    items: currencies
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold))))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _fromCurrency = v ?? 'PKR'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (inputAmount > 0)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: currencies
                  .where((c) => c != _fromCurrency)
                  .map((toCurrency) {
                final result =
                    _convert(inputAmount, _fromCurrency, toCurrency);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primaryDark.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(toCurrency,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMid,
                              letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text(
                        _format(result, toCurrency),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'Enter an amount above to see conversions',
              style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.7),
                  fontSize: 12),
            ),
          const SizedBox(height: 8),
          Text(
            'Rates are approximate. PKR · USD · EUR · GBP',
            style: TextStyle(
                color: AppColors.textLight.withOpacity(0.5),
                fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryRow extends StatelessWidget {
  final String name;
  final double budget;
  final double spent;
  final double fraction;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCategoryRow({
    required this.name,
    required this.budget,
    required this.spent,
    required this.fraction,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final left = budget - spent;
    final isOverBudget = spent > budget && budget > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            Text(
              isOverBudget
                  ? 'Rs. ${(spent - budget).toStringAsFixed(0)} over'
                  : 'Rs. ${left.toStringAsFixed(0)} left',
              style: TextStyle(
                  color: isOverBudget ? AppColors.accentRed : AppColors.textMid,
                  fontSize: 11),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(fraction * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
                onTap: onEdit,
                child: const Icon(Icons.edit_outlined,
                    size: 14, color: AppColors.textLight)),
            const SizedBox(width: 4),
            GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline,
                    size: 14, color: AppColors.textLight)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Rs. ${budget.toStringAsFixed(0)} budget · Rs. ${spent.toStringAsFixed(0)} spent',
          style: const TextStyle(color: AppColors.textLight, fontSize: 10),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            color: isOverBudget ? AppColors.accentRed : color,
          ),
        ),
      ],
    );
  }
}

// ── Edit Budget Category ────────────────────────────────────────────────────
class EditBudgetScreen extends StatefulWidget {
  final Map<String, dynamic> budget;
  final String categoryName;
  final double spent;
  final Color color;
  final Future<void> Function(double limit, String period) onSave;

  const EditBudgetScreen({
    super.key,
    required this.budget,
    required this.categoryName,
    required this.spent,
    required this.color,
    required this.onSave,
  });

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  late final TextEditingController _limitCtrl;
  late String _selectedPeriod;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _limitCtrl = TextEditingController(
      text: (double.tryParse(widget.budget['limit_amount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(0),
    );
    _limitCtrl.addListener(() => setState(() {}));
    _selectedPeriod = widget.budget['period'] as String? ?? 'monthly';
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final limit = double.tryParse(_limitCtrl.text.trim());
    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget amount')),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(limit, _selectedPeriod);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final budget = double.tryParse(widget.budget['limit_amount']?.toString() ?? '0') ?? 0.0;
    final left = budget - widget.spent;
    final fraction = budget > 0 ? (widget.spent / budget).clamp(0.0, 1.0) : 0.0;

    return SidebarScaffold(
      activeNav: 'Dashboard',
      onLogout: () {},
      content: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Edit budget category'),
            const SizedBox(height: 20),
            _EditRow(label: 'Category:', value: widget.categoryName),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Budget amount:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _limitCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: 'Rs. ',
                      filled: true,
                      fillColor: AppColors.inputBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ReadOnlyRow(
                label: 'Amount spent:',
                value: 'Rs. ${widget.spent.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            _ReadOnlyRow(
                label: 'Remaining:',
                value: 'Rs. ${((double.tryParse(_limitCtrl.text.trim()) ?? budget) - widget.spent).toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Period:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (v) => setState(() => _selectedPeriod = v ?? _selectedPeriod),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                color: widget.color,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white))
                      : const Text('Confirm',
                          style: TextStyle(color: AppColors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  final String label;
  final String value;

  const _EditRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.edit, size: 16, color: AppColors.textMid),
      ],
    );
  }
}

// Read-only row — no edit icon, used for auto-calculated fields
class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.inputBg.withOpacity(0.6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textLight)),
        ),
      ],
    );
  }
}

// ── Budget Goal ─────────────────────────────────────────────────────────────
class BudgetGoalScreen extends StatefulWidget {
  const BudgetGoalScreen({super.key});

  @override
  State<BudgetGoalScreen> createState() => _BudgetGoalScreenState();
}

class _BudgetGoalScreenState extends State<BudgetGoalScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    final startDate = _startDateCtrl.text.trim();
    final endDate = _endDateCtrl.text.trim();

    if (name.isEmpty || amountText.isEmpty || startDate.isEmpty || endDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (_validateDate(startDate) != null || _validateDate(endDate) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid dates (MM/DD/YYYY)')),
      );
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // Convert end date from MM/DD/YYYY to YYYY-MM-DD for the API
      final parts = endDate.split('/');
      final deadline =
          '${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}';

      final goal = GoalModel(
        id: 0, // assigned by server
        title: name,
        targetAmount: amount,
        savedAmount: 0,
        deadline: deadline,
      );
      await GoalService.addGoal(goal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal successfully created!')),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/budget_dashboard',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create goal: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  String? _validateDate(String value) {
    if (value.isEmpty) return null;
    final parts = value.split('/');
    if (parts.length != 3) return 'Use MM/DD/YYYY';
    final mm = int.tryParse(parts[0]);
    final dd = int.tryParse(parts[1]);
    final yyyy = int.tryParse(parts[2]);
    if (mm == null || mm < 1 || mm > 12) return 'Invalid month';
    if (dd == null || dd < 1 || dd > 31) return 'Invalid day';
    if (yyyy == null || yyyy < 2000) return 'Invalid year';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SidebarScaffold(
      activeNav: 'Dashboard',
      onLogout: () {},
      content: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Budget Goal',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, '/other_goals'),
                  child: const Text('see other budget goals →',
                      style: TextStyle(
                          color: AppColors.textMid, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name for goal
            const Text('Name for goal:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Save for vacation',
                hintStyle: const TextStyle(
                    color: AppColors.textLight, fontSize: 13),
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 13),
            ),

            const SizedBox(height: 14),

            // Budget amount
            const Text('Set budget amount:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g. 50000',
                hintStyle: const TextStyle(
                    color: AppColors.textLight, fontSize: 13),
                prefixText: 'Rs. ',
                prefixStyle: const TextStyle(
                    color: AppColors.textMid,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 13),
            ),

            const SizedBox(height: 14),

            // Start date
            const Text('Set a start date:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _startDateCtrl,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                hintText: 'MM/DD/YYYY',
                hintStyle: const TextStyle(
                    color: AppColors.textLight, fontSize: 13),
                suffixIcon: const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.textMid),
                filled: true,
                fillColor: AppColors.primaryLight.withOpacity(0.15),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => setState(() {}),
            ),
            if (_validateDate(_startDateCtrl.text) != null &&
                _startDateCtrl.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(_validateDate(_startDateCtrl.text)!,
                    style: const TextStyle(
                        color: AppColors.accentRed, fontSize: 11)),
              ),

            const SizedBox(height: 14),

            // End date
            const Text('Set an end date:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _endDateCtrl,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                hintText: 'MM/DD/YYYY',
                hintStyle: const TextStyle(
                    color: AppColors.textLight, fontSize: 13),
                suffixIcon: const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.textMid),
                filled: true,
                fillColor: AppColors.primaryLight.withOpacity(0.15),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => setState(() {}),
            ),
            if (_validateDate(_endDateCtrl.text) != null &&
                _endDateCtrl.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(_validateDate(_endDateCtrl.text)!,
                    style: const TextStyle(
                        color: AppColors.accentRed, fontSize: 11)),
              ),

            const SizedBox(height: 24),

            Row(
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white))
                      : const Text('Confirm goal',
                          style: TextStyle(color: AppColors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goal History ────────────────────────────────────────────────────────────

class GoalHistoryScreen extends StatefulWidget {
  const GoalHistoryScreen({super.key});

  @override
  State<GoalHistoryScreen> createState() => _GoalHistoryScreenState();
}

class _GoalHistoryScreenState extends State<GoalHistoryScreen> {
  List<GoalModel> _goals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final goals = await GoalService.getGoals();
      if (mounted) setState(() { _goals = goals; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  /// Format YYYY-MM-DD (or ISO) to MM/DD/YYYY for display
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.month.toString().padLeft(2, '0')}/'
             '${dt.day.toString().padLeft(2, '0')}/'
             '${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Derive a status label from saved vs target amounts
  String _statusFor(GoalModel g) {
    if (g.targetAmount <= 0) return 'In progress';
    if (g.savedAmount >= g.targetAmount) return 'Completed!';
    return 'In progress';
  }

  Color _colorForStatus(String status) {
    switch (status) {
      case 'Completed!':
        return AppColors.successGreen;
      default:
        return Colors.blue;
    }
  }

  void _editGoal(GoalModel goal) {
    final nameCtrl = TextEditingController(text: goal.title);
    final amountCtrl =
        TextEditingController(text: goal.targetAmount.toStringAsFixed(0));
    final savedCtrl =
        TextEditingController(text: goal.savedAmount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardLight,
        title: const Text('Edit Goal',
            style: TextStyle(color: AppColors.primaryDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Goal name:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text('Target amount:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text('Saved amount:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: savedCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark),
            onPressed: () async {
              final title = nameCtrl.text.trim();
              final target = double.tryParse(amountCtrl.text.trim());
              final saved = double.tryParse(savedCtrl.text.trim());
              if (title.isEmpty || target == null || saved == null) return;
              Navigator.pop(ctx);
              try {
                await GoalService.updateGoal(goal.id, {
                  'title': title,
                  'targetAmount': target,
                  'savedAmount': saved,
                });
                await _loadGoals();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update goal: $e')),
                  );
                }
              }
            },
            child: const Text('Save',
                style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteGoal(GoalModel goal) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        message: 'Do you want to delete\n"${goal.title}"?',
        onYes: () async {
          Navigator.pop(context);
          try {
            await GoalService.deleteGoal(goal.id);
            await _loadGoals();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete goal: $e')),
              );
            }
          }
        },
        onNo: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SidebarScaffold(
      activeNav: 'Dashboard',
      onLogout: () {},
      content: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.accentGreen),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style:
                              const TextStyle(color: AppColors.accentRed)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _loadGoals,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadGoals,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Goal History'),
                            const SizedBox(height: 16),
                            if (_goals.isEmpty)
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 16),
                                child: Text('No goals yet.',
                                    style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 13)),
                              ),
                          ],
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final g = _goals[index];
                            final status = _statusFor(g);
                            final statusColor = _colorForStatus(status);
                            final progress = g.targetAmount > 0
                                ? (g.savedAmount / g.targetAmount)
                                    .clamp(0.0, 1.0)
                                : 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.primaryDark
                                          .withOpacity(0.1)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(g.title,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 13)),
                                        ),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(status,
                                              style: const TextStyle(
                                                  color: AppColors.white,
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _editGoal(g),
                                          child: const Icon(
                                              Icons.edit_outlined,
                                              size: 16,
                                              color: AppColors.textMid),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () => _deleteGoal(g),
                                          child: const Icon(
                                              Icons.delete_outline,
                                              size: 16,
                                              color: AppColors.textLight),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Rs. ${g.savedAmount.toStringAsFixed(0)} / Rs. ${g.targetAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: AppColors.textMid,
                                          fontSize: 11),
                                    ),
                                    if (g.deadline != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Deadline: ${_formatDate(g.deadline)}',
                                        style: const TextStyle(
                                            color: AppColors.textLight,
                                            fontSize: 11),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 6,
                                        backgroundColor:
                                            Colors.grey.shade200,
                                        color: status == 'Completed!'
                                            ? AppColors.successGreen
                                            : AppColors.accentGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _goals.length,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── Add Budget Category ─────────────────────────────────────────────────────
class AddBudgetCategoryScreen extends StatefulWidget {
  final List<CategoryModel> expenseCategories;
  final Future<void> Function(int categoryId, double limit, String period)? onSave;

  const AddBudgetCategoryScreen({
    super.key,
    required this.expenseCategories,
    this.onSave,
  });

  @override
  State<AddBudgetCategoryScreen> createState() =>
      _AddBudgetCategoryScreenState();
}

class _AddBudgetCategoryScreenState extends State<AddBudgetCategoryScreen> {
  final _amountCtrl = TextEditingController();
  CategoryModel? _selectedCategory;
  String _selectedPeriod = 'monthly';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.expenseCategories.isNotEmpty) {
      _selectedCategory = widget.expenseCategories.first;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget amount')),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.onSave?.call(_selectedCategory!.id, amount, _selectedPeriod);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SidebarScaffold(
      activeNav: 'Dashboard',
      onLogout: () {},
      content: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Add new budget category'),
            const SizedBox(height: 20),

            // Category dropdown
            const Text('Category:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            if (widget.expenseCategories.isEmpty)
              const Text('No expense categories found. Add one first.',
                  style: TextStyle(color: AppColors.textLight, fontSize: 13))
            else
              DropdownButtonFormField<CategoryModel>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                items: widget.expenseCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),

            const SizedBox(height: 14),

            // Budget amount field
            const Text('Set budget amount:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 10000',
                hintStyle: const TextStyle(
                    color: AppColors.textLight, fontSize: 13),
                prefixText: 'Rs. ',
                prefixStyle: const TextStyle(
                    color: AppColors.textMid,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 13),
            ),

            const SizedBox(height: 14),

            // Period selector
            const Text('Period:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (v) => setState(() => _selectedPeriod = v ?? _selectedPeriod),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white))
                      : const Text('Confirm category',
                          style: TextStyle(color: AppColors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final String label;
  final bool isDate;

  const _GoalRow({required this.label, required this.isDate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDate
                  ? AppColors.primaryLight.withOpacity(0.4)
                  : AppColors.inputBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: isDate
                ? const Text('MM/DD/YYYY',
                    style: TextStyle(
                        color: AppColors.textLight, fontSize: 12))
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}