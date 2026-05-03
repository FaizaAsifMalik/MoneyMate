import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/bill_service.dart';

class Bill {
  final int id;
  String name;
  int dueDay;        // day of month (1-31)
  String nextDueDate; // ISO date string for display & API (e.g. "2026-05-14")
  String frequency;  // 'monthly' or 'yearly'
  bool isPaid;
  int amount;

  Bill({
    required this.id,
    required this.name,
    required this.dueDay,
    required this.nextDueDate,
    required this.frequency,
    required this.isPaid,
    required this.amount,
  });

  /// Display-friendly due date, e.g. "May 14, 2026"
  String get dueDateDisplay {
    try {
      final d = DateTime.parse(nextDueDate);
      const months = [
        'January','February','March','April','May','June',
        'July','August','September','October','November','December'
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return nextDueDate;
    }
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: (map['bill_id'] ?? map['id']) as int,
      name: map['name'] as String,
      dueDay: (map['due_date'] as num).toInt(),
      nextDueDate: (map['next_due_date'] ?? map['nextDueDate'] ?? '') as String,
      frequency: (map['frequency'] ?? 'monthly') as String,
      isPaid: map['is_paid'] == true || map['isPaid'] == true,
      amount: (map['amount'] is num
          ? (map['amount'] as num)
          : double.parse(map['amount'].toString())).toInt(),
    );
  }
}

class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  List<Bill> _bills = [];
  bool _isLoading = true;
  String? _error;

  bool _showAddForm = false;
  bool _showPaid = false;
  final _descCtrl = TextEditingController();
  DateTime? _selectedDate;
  String _selectedFrequency = 'monthly';
  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    try {
      setState(() { _isLoading = true; _error = null; });
      final data = await BillService.getBills();
      setState(() {
        _bills = data.map(Bill.fromMap).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Bill> get _dueBills => _bills.where((b) => !b.isPaid).toList();
  List<Bill> get _paidBills => _bills.where((b) => b.isPaid).toList();

  int get _totalDueAmount =>
      _dueBills.fold(0, (sum, b) => sum + b.amount);
  int get _totalPaidAmount =>
      _paidBills.fold(0, (sum, b) => sum + b.amount);


  /// Formats a DateTime to ISO 8601 date string for the API (e.g. 2026-05-15)
  String _toIso(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Formats a DateTime for display (e.g. May 15, 2026)
  String _toDisplay(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _pickDate(BuildContext context, {DateTime? initial, required void Function(DateTime) onPicked}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }
  Future<void> _addBill() async {
    final amount = int.tryParse(_amountCtrl.text.trim());
    if (_descCtrl.text.isNotEmpty &&
        _selectedDate != null &&
        amount != null &&
        amount > 0) {
      try {
        final data = await BillService.createBill(
          name: _descCtrl.text.trim(),
          amount: amount.toDouble(),
          dueDate: _selectedDate!.day,
          frequency: _selectedFrequency,
          nextDueDate: _toIso(_selectedDate!),
        );
        setState(() {
          _bills.add(Bill.fromMap(data));
          _descCtrl.clear();
          _selectedDate = null;
          _selectedFrequency = 'monthly';
          _amountCtrl.clear();
          _showAddForm = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add bill: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all fields with a valid amount')),
      );
    }
  }

  Future<void> _togglePaid(Bill bill) async {
    try {
      if (!bill.isPaid) {
        await BillService.markAsPaid(bill.id);
      } else {
        await BillService.updateBill(bill.id, isPaid: false);
      }
      setState(() {
        final idx = _bills.indexOf(bill);
        _bills[idx] = Bill(
          id: bill.id,
          name: bill.name,
          dueDay: bill.dueDay,
          nextDueDate: bill.nextDueDate,
          frequency: bill.frequency,
          isPaid: !bill.isPaid,
          amount: bill.amount,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update bill: $e')),
      );
    }
  }

  void _editBill(Bill bill) {
    final nameCtrl = TextEditingController(text: bill.name);

    final amountCtrl =
        TextEditingController(text: bill.amount.toString());

    // Try to parse existing nextDueDate as DateTime for the picker
    DateTime? editDate;
    try {
      editDate = DateTime.parse(bill.nextDueDate);
    } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppColors.cardLight,
        title: const Text('Edit Bill',
            style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Description',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.textMid)),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Due Date',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.textMid)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: editDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setDialogState(() => editDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textMid),
                    const SizedBox(width: 8),
                    Text(
                      editDate != null ? _toDisplay(editDate!) : 'Select a date',
                      style: TextStyle(
                        fontSize: 14,
                        color: editDate != null ? AppColors.textDark : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Amount',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.textMid)),
            const SizedBox(height: 6),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                prefixStyle: const TextStyle(
                    color: AppColors.textMid,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMid),
            onPressed: () async {
              final newAmount =
                  int.tryParse(amountCtrl.text.trim()) ?? bill.amount;
              if (nameCtrl.text.trim().isNotEmpty && editDate != null) {
                try {
                  await BillService.updateBill(
                    bill.id,
                    name: nameCtrl.text.trim(),
                    dueDate: editDate!.day,
                    nextDueDate: _toIso(editDate!),
                    amount: newAmount.toDouble(),
                  );
                  setState(() {
                    final idx = _bills.indexOf(bill);
                    _bills[idx] = Bill(
                      id: bill.id,
                      name: nameCtrl.text.trim(),
                      dueDay: editDate!.day,
                      nextDueDate: _toIso(editDate!),
                      frequency: bill.frequency,
                      isPaid: bill.isPaid,
                      amount: newAmount,
                    );
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update bill: $e')),
                  );
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      ),
    );
  }

  void _deleteBill(Bill bill) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        message: 'Delete bill "${bill.name}"?',
        onYes: () async {
          try {
            await BillService.deleteBill(bill.id);
            setState(() => _bills.remove(bill));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete bill: $e')),
            );
          }
          Navigator.pop(context);
        },
        onNo: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final due = _dueBills;
    final paid = _paidBills;

    if (_isLoading) {
      return const SidebarScaffold(
        activeNav: 'Bill',
        onLogout: null,
        content: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SidebarScaffold(
        activeNav: 'Bill',
        onLogout: () {},
        content: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.accentRed, size: 40),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.textMid)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadBills, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return SidebarScaffold(
      activeNav: 'Bill',
      onLogout: () {},
      content: Column(
        children: [
          // ── Sticky Top Banner ──────────────────────────
          _TopBanner(
            totalBills: _bills.length,
            dueBills: due.length,
            paidBills: paid.length,
            totalDueAmount: _totalDueAmount,
            totalPaidAmount: _totalPaidAmount,
          ),

          // ── Scrollable Content ─────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatCard(
                          label: 'Total Bills',
                          value: '${_bills.length}',
                          subValue: null,
                          icon: Icons.receipt_long_outlined,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Due Bills',
                          value: '${due.length}',
                          subValue: 'Rs. $_totalDueAmount',
                          icon: Icons.pending_actions_outlined,
                          color: AppColors.accentRed,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Paid Bills',
                          value: '${paid.length}',
                          subValue: 'Rs. $_totalPaidAmount',
                          icon: Icons.check_circle_outline,
                          color: AppColors.accentGreen,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Text(
                          'DUE BILLS',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_totalDueAmount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentRed.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Rs. $_totalDueAmount',
                              style: const TextStyle(
                                  color: AppColors.accentRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        const Spacer(),
                        _IconBtn(
                          icon: Icons.add,
                          tooltip: 'Add bill',
                          onTap: () => setState(
                              () => _showAddForm = !_showAddForm),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if (_showAddForm) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppColors.accentGreen.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('New Bill',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.primaryDark)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _showAddForm = false;
                                    _descCtrl.clear();
                                    _selectedDate = null;
                                    _amountCtrl.clear();
                                  }),
                                  child: const Icon(Icons.close,
                                      size: 18,
                                      color: AppColors.textLight),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('Description',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.textMid)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _descCtrl,
                              decoration: InputDecoration(
                                hintText: 'e.g. Internet, Rent',
                                filled: true,
                                fillColor: AppColors.inputBg,
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    borderSide: BorderSide.none),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text('Due Date',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.textMid)),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => _pickDate(context, onPicked: (d) => setState(() => _selectedDate = d)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                decoration: BoxDecoration(
                                  color: AppColors.inputBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textMid),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedDate != null ? _toDisplay(_selectedDate!) : 'Select a date',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _selectedDate != null ? AppColors.textDark : AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text('Amount',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.textMid)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _amountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'e.g. 5000',
                                prefixText: 'Rs. ',
                                prefixStyle: const TextStyle(
                                    color: AppColors.textMid,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                                filled: true,
                                fillColor: AppColors.inputBg,
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    borderSide: BorderSide.none),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const SizedBox(height: 10),
                            const Text('Frequency',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.textMid)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.inputBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedFrequency,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                                  ],
                                  onChanged: (v) => setState(() => _selectedFrequency = v!),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            PinkButton(
                                label: 'Add Bill', onPressed: _addBill),
                          ],
                        ),
                      ),
                    ],

                    if (due.isEmpty)
                      _EmptyState(
                          message:
                              'No due bills — you\'re all caught up!')
                    else
                      _BillTable(
                        bills: due,
                        isPaidSection: false,
                        onToggle: _togglePaid,
                        onDelete: _deleteBill,
                        onEdit: _editBill,
                      ),

                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: () =>
                          setState(() => _showPaid = !_showPaid),
                      child: Row(
                        children: [
                          const Text('PAID BILLS',
                              style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${paid.length}',
                                style: const TextStyle(
                                    color: AppColors.accentGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (_totalPaidAmount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen
                                    .withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Rs. $_totalPaidAmount',
                                style: const TextStyle(
                                    color: AppColors.accentGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Icon(
                              _showPaid
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: AppColors.textLight,
                              size: 18),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (_showPaid) ...[
                      if (paid.isEmpty)
                        _EmptyState(
                            message: 'No bills marked as paid yet.')
                      else
                        _BillTable(
                          bills: paid,
                          isPaidSection: true,
                          onToggle: _togglePaid,
                          onDelete: _deleteBill,
                          onEdit: _editBill,
                        ),
                    ],

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
}

// ─────────────────────────────────────────────────────────────
// TOP BANNER (sticky)
// ─────────────────────────────────────────────────────────────

class _TopBanner extends StatelessWidget {
  final int totalBills;
  final int dueBills;
  final int paidBills;
  final int totalDueAmount;
  final int totalPaidAmount;

  const _TopBanner({
    required this.totalBills,
    required this.dueBills,
    required this.paidBills,
    required this.totalDueAmount,
    required this.totalPaidAmount,
  });

  static String _formatMonthYear(DateTime date) {
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return '${months[date.month - 1]} ${date.year}';
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
                      child: const Icon(Icons.receipt_long,
                          color: AppColors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Bills Overview',
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
                Text(_formatMonthYear(DateTime.now()),
                    style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 11,
                        letterSpacing: 2)),
                const SizedBox(height: 4),
                Text(
                  '$dueBills Due  •  $paidBills Paid',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'out of $totalBills total bills this month',
                  style: TextStyle(
                      color: AppColors.white.withOpacity(0.6),
                      fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _BannerStat(
                      label: 'Due Amount',
                      value: 'Rs. $totalDueAmount',
                      color: AppColors.accentRed,
                    ),
                    const SizedBox(width: 20),
                    _BannerStat(
                      label: 'Paid Amount',
                      value: 'Rs. $totalPaidAmount',
                      color: AppColors.accentGreen,
                    ),
                  ],
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
              const SizedBox(height: 12),
              Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.white.withOpacity(0.15), size: 64),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BannerStat(
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
// BILL TABLE
// ─────────────────────────────────────────────────────────────

class _BillTable extends StatelessWidget {
  final List<Bill> bills;
  final bool isPaidSection;
  final void Function(Bill) onToggle;
  final void Function(Bill) onDelete;
  final void Function(Bill) onEdit;

  const _BillTable({
    required this.bills,
    required this.isPaidSection,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isPaidSection
        ? AppColors.accentGreen.withOpacity(0.5)
        : AppColors.accentRed.withOpacity(0.5);
    final bgColor =
        isPaidSection ? AppColors.incomeBadge : AppColors.expenseBadge;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text('Bill',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textMid)),
                ),
                const Expanded(
                  flex: 3,
                  child: Text('Due Date',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textMid)),
                ),
                const Expanded(
                  flex: 2,
                  child: Text('Amount',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textMid)),
                ),
                const SizedBox(width: 8),
                Text(isPaidSection ? 'Paid' : 'Status',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textMid)),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          ...bills.asMap().entries.map((entry) {
            final idx = entry.key;
            final bill = entry.value;
            final isLast = idx == bills.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(bill.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textDark,
                                decoration: isPaidSection
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: AppColors.textLight)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(bill.dueDateDisplay,
                            style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 11)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Rs. ${bill.amount}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isPaidSection
                                ? AppColors.accentGreen
                                : AppColors.accentRed,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => onToggle(bill),
                        child: Icon(
                            bill.isPaid
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: bill.isPaid
                                ? AppColors.accentGreen
                                : AppColors.textLight,
                            size: 20),
                      ),
                      const SizedBox(width: 4),
                      _IconBtn(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit',
                          size: 16,
                          onTap: () => onEdit(bill)),
                      const SizedBox(width: 4),
                      _IconBtn(
                          icon: Icons.delete_outline,
                          tooltip: 'Delete',
                          size: 16,
                          color: AppColors.accentRed,
                          onTap: () => onDelete(bill)),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                      height: 1,
                      color: borderColor,
                      indent: 16,
                      endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subValue,
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
                    fontSize: 20,
                    fontFamily: 'Courier')),
            if (subValue != null) ...[
              const SizedBox(height: 2),
              Text(subValue!,
                  style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ],
        ),
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