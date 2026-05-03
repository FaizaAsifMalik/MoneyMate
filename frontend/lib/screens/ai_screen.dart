import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/ai_service.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _insights = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final insights = await AIService.getInsights();
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SidebarScaffold(
        activeNav: 'Smart Spending',
        onLogout: null,
        content: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SidebarScaffold(
        activeNav: 'Smart Spending',
        onLogout: null,
        content: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  style: const TextStyle(color: AppColors.accentRed),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    // ── Parse insights payload ─────────────────────────
    final suggestions =
        (_insights['suggestions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final budgetPredictions =
        _insights['budgetPredictions'] as Map<String, dynamic>? ?? {};
    final expenseSummary =
        (_insights['expenseSummary'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Budget prediction values
    final predictedSpending = budgetPredictions['predictedSpending'];
    final remainingBudget = budgetPredictions['remainingBudget'];
    final accuracy = budgetPredictions['accuracy'];
    final predictedDiff = budgetPredictions['predictedDiff'];
    final remainingDiff = budgetPredictions['remainingDiff'];
    final accuracyBase =
        budgetPredictions['accuracyBase'] ?? 'Based on last 6 months';

    // Category colors cycling list
    final categoryColors = [
      Colors.green,
      Colors.pink,
      Colors.red,
      const Color.fromARGB(255, 136, 126, 35),
      Colors.indigo,
      Colors.grey,
    ];

    return SidebarScaffold(
      activeNav: 'Smart Spending',
      onLogout: () {},
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopBanner(),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── AI Suggestions ──────────────────────────
                  const Text(
                    'AI SUGGESTIONS',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (suggestions.isEmpty)
                    const _EmptyState(message: 'No suggestions available.')
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: suggestions.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final s = entry.value;
                          final colors = [
                            AppColors.accentRed,
                            AppColors.accentGreen,
                            AppColors.primaryMid,
                            AppColors.primaryDark,
                          ];
                          final icons = [
                            Icons.trending_down,
                            Icons.savings_outlined,
                            Icons.receipt_long_outlined,
                            Icons.lightbulb_outline,
                          ];
                          final colorIdx = idx % colors.length;
                          return Padding(
                            padding: EdgeInsets.only(
                                right: idx < suggestions.length - 1 ? 10 : 0),
                            child: _AISuggestionCard(
                              icon: icons[colorIdx],
                              iconColor: colors[colorIdx],
                              title: s['title'] ?? s['type'] ?? '',
                              body: s['description'] ?? s['message'] ?? '',

                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Budget Prediction ───────────────────────
                  const Text(
                    'BUDGET PREDICTION',
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
                      border: Border.all(
                          color: AppColors.primaryDark.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        _PredictionTile(
                          icon: Icons.arrow_downward_rounded,
                          iconColor: AppColors.accentGreen,
                          label: 'Predicted Spending',
                          value: predictedSpending != null
                              ? 'Rs. $predictedSpending'
                              : '—',
                          sub: predictedDiff != null
                              ? '↙ Rs. $predictedDiff less than budget'
                              : '',
                        ),
                        const _VerticalDivider(),
                        _PredictionTile(
                          icon: Icons.savings_outlined,
                          iconColor: AppColors.primaryMid,
                          label: 'Remaining Budget',
                          value: remainingBudget != null
                              ? 'Rs. $remainingBudget'
                              : '—',
                          sub: remainingDiff != null
                              ? '↑ Rs. $remainingDiff more than last month'
                              : '',
                        ),
                        const _VerticalDivider(),
                        _PredictionTile(
                          icon: Icons.track_changes_outlined,
                          iconColor: AppColors.accentRed,
                          label: 'Prediction Accuracy',
                          value: accuracy != null ? '$accuracy%' : '—',
                          sub: accuracyBase,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Category Spending ───────────────────────
                  const Text(
                    'CATEGORY SPENDING',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (expenseSummary.isEmpty)
                    const _EmptyState(message: 'No category data available.')
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primaryDark.withOpacity(0.15)),
                      ),
                      child: Column(
                        children: expenseSummary.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final c = entry.value;
                          final color =
                              categoryColors[idx % categoryColors.length];
                          final allTotals = expenseSummary
                              .map((e) =>
                                  (e['total'] as num?)?.toDouble() ?? 0.0)
                              .toList();
                          final maxTotal = allTotals.isEmpty
                              ? 1.0
                              : allTotals.reduce((a, b) => a > b ? a : b);
                          final total =
                              (c['total'] as num?)?.toDouble() ?? 0.0;
                          final ratio = maxTotal > 0
                              ? (total / maxTotal).clamp(0.0, 1.0)
                              : 0.0;
                          final percent = (ratio * 100).toInt();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c['name'] ?? c['category'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$percent%',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 8,
                                    backgroundColor: color.withOpacity(0.12),
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BANNER
// ─────────────────────────────────────────────────────────────

class _TopBanner extends StatelessWidget {
  const _TopBanner();

  String get _monthLabel {
    final now = DateTime.now();
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${months[now.month - 1]} ${now.year}';
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
                      child: const Icon(Icons.auto_awesome,
                          color: AppColors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Smart Spending',
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
                  _monthLabel,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'AI-Powered Insights',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Personalized suggestions based on your spending',
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
                Icons.psychology_outlined,
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
// AI SUGGESTION CARD
// ─────────────────────────────────────────────────────────────

class _AISuggestionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  const _AISuggestionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textDark,
                )),
            const SizedBox(height: 5),
            Text(body,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                  height: 1.4,
                )),

          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PREDICTION TILE
// ─────────────────────────────────────────────────────────────

class _PredictionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  const _PredictionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 10,
                  letterSpacing: 0.3,
                )),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Courier',
                  color: AppColors.textDark,
                )),
            const SizedBox(height: 3),
            Text(sub,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 9,
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// VERTICAL DIVIDER HELPER
// ─────────────────────────────────────────────────────────────

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 64,
      color: AppColors.primaryDark.withOpacity(0.1),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined,
              size: 36, color: AppColors.textLight.withOpacity(0.5)),
          const SizedBox(height: 10),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textLight, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}