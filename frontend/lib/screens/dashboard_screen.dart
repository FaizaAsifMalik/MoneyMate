import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/income_service.dart';
import '../services/expense_service.dart';
import 'budget_screens.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;

  double _monthlyIncome = 0;
  double _monthlyExpenses = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final now = DateTime.now();
      final startDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      final endDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        IncomeService.getIncomes(startDate: startDate, endDate: endDate),
        ExpenseService.getExpenses(startDate: startDate, endDate: endDate),
      ]);

      final incomes = results[0] as dynamic;
      final expenses = results[1] as dynamic;

      final totalIncome =
          (incomes as List).fold(0.0, (s, e) => s + (e.amount as double));
      final totalExpenses =
          (expenses as List).fold(0.0, (s, e) => s + (e.amount as double));

      if (mounted) {
        setState(() {
          _monthlyIncome = totalIncome;
          _monthlyExpenses = totalExpenses;
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => ConfirmDialog(
        message: 'Do you want to log out?',
        onYes: () {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/logout_success');
        },
        onNo: () => Navigator.pop(context),
      ),
    );
  }

  double get _netBalance => _monthlyIncome - _monthlyExpenses;

  double get _savingsRate =>
      _monthlyIncome > 0 ? (_netBalance / _monthlyIncome) * 100 : 0;

  double get _spendingRate =>
      _monthlyIncome > 0 ? (_monthlyExpenses / _monthlyIncome) : 0;

  @override
  Widget build(BuildContext context) {
    return SidebarScaffold(
      activeNav: 'Dashboard',
      onLogout: () => _showLogoutDialog(context),
      content: Column(
        children: [
          // ── Sticky Top Banner ──────────────────────────────────────
          _TopBanner(
            netBalance: _netBalance,
            isLoading: _isLoading,
          ),

          // ── Scrollable Content ─────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.primaryMid),
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Stat Cards ─────────────────────
                                Row(
                                  children: [
                                    _StatCard(
                                      label: 'Monthly Income',
                                      value:
                                          'Rs. ${_monthlyIncome.toStringAsFixed(0)}',
                                      icon: Icons.trending_up,
                                      color: AppColors.accentGreen,
                                    ),
                                    const SizedBox(width: 12),
                                    _StatCard(
                                      label: 'Monthly Expenses',
                                      value:
                                          'Rs. ${_monthlyExpenses.toStringAsFixed(0)}',
                                      icon: Icons.trending_down,
                                      color: AppColors.accentRed,
                                    ),

                                  ],
                                ),

                                const SizedBox(height: 24),

                                // ── Spending Progress ───────────────
                                const Text(
                                  'MONTHLY SPENDING',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border(
                                      left: BorderSide(
                                          color: AppColors.primaryMid,
                                          width: 3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Spent  Rs. ${_monthlyExpenses.toStringAsFixed(0)} / ${_monthlyIncome.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                color: AppColors.textMid,
                                                fontSize: 13),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${_spendingRate > 1 ? '100' : (_spendingRate * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              color: AppColors.primaryMid,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Courier',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: _spendingRate.clamp(0.0, 1.0),
                                          backgroundColor: AppColors
                                              .primaryMid
                                              .withOpacity(0.15),
                                          color: _spendingRate > 0.9
                                              ? AppColors.accentRed
                                              : AppColors.primaryMid,
                                          minHeight: 10,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          _MiniStat(
                                            label: 'Savings rate',
                                            value:
                                                '${_savingsRate.toStringAsFixed(1)}%',
                                            color: _savingsRate >= 0
                                                ? AppColors.accentGreen
                                                : AppColors.accentRed,
                                          ),
                                          const SizedBox(width: 24),
                                          _MiniStat(
                                            label: 'Remaining',
                                            value:
                                                'Rs. ${_netBalance.toStringAsFixed(0)}',
                                            color: _netBalance >= 0
                                                ? AppColors.primaryMid
                                                : AppColors.accentRed,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── Quick Access ────────────────────
                                const Text(
                                  'QUICK ACCESS',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const BudgetDashboardScreen(),
                                          ),
                                        ),
                                        child: _QuickCard(
                                          color: const Color(0xFFB88C9E),
                                          icon: Icons.pie_chart_outline,
                                          iconBgColor: AppColors.primaryMid
                                              .withOpacity(0.5),
                                          iconColor: AppColors.white,
                                          title: 'Budget',
                                          subtitle: 'View categories',
                                          titleColor: AppColors.white,
                                          subtitleColor:
                                              AppColors.white.withOpacity(0.55),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _QuickCard(
                                        color: const Color(0xFFF1C8DB),
                                        icon: Icons.show_chart,
                                        iconBgColor: AppColors.accentPink
                                            .withOpacity(0.15),
                                        iconColor: AppColors.accentPink,
                                        title: 'Trends',
                                        subtitle: 'Spending over time',
                                        titleColor: AppColors.textDark,
                                        subtitleColor: AppColors.textLight,
                                        border: Border.all(
                                            color: AppColors.primaryMid
                                                .withOpacity(0.2)),
                                      ),
                                    ),
                                  ],
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
  final double netBalance;
  final bool isLoading;

  const _TopBanner({required this.netBalance, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];

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
                      child: const Icon(Icons.dashboard_outlined,
                          color: AppColors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Dashboard',
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
                  '${months[now.month - 1]} ${now.year}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                isLoading
                    ? const Text(
                        '...',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      )
                    : Text(
                        'Rs. ${netBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      ),
                const SizedBox(height: 2),
                Text(
                  'Net balance this month',
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
              Row(
                children: [
                  const NotificationBellIcon(),
                  const SizedBox(width: 10),
                  ProfileAvatar(),
                ],
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.white.withOpacity(0.15),
                size: 64,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STAT CARD
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
                    fontSize: 13,
                    fontFamily: 'Courier')),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MINI STAT (inline label + value)
// ─────────────────────────────────────────────────────────────

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
            style: const TextStyle(
                color: AppColors.textLight, fontSize: 10)),
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
// QUICK ACCESS CARD
// ─────────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final BoxBorder? border;

  const _QuickCard({
    required this.color,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const Spacer(),
          Text(title,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Courier',
              )),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(color: subtitleColor, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LOGOUT SUCCESS SCREEN
// ─────────────────────────────────────────────────────────────

class LogoutSuccessScreen extends StatelessWidget {
  const LogoutSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You have been successfully logged out',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.check, color: AppColors.white, size: 32),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (r) => false),
                child: const Text('Back to Login',
                    style: TextStyle(color: AppColors.textLight)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}