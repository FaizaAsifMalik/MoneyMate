import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bill_service.dart';
import '../services/goal_service.dart';

// ─────────────────────────────────────────────────────────────
// APP NOTIFICATION MODEL
// ─────────────────────────────────────────────────────────────

enum NotificationType { billDue, goalDeadline }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final int daysUntil; // negative = overdue
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.daysUntil,
    this.isRead = false,
  });
}

// ─────────────────────────────────────────────────────────────
// NOTIFICATION SERVICE  (app-wide singleton, ChangeNotifier)
// ─────────────────────────────────────────────────────────────

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ── State ──────────────────────────────────────────────────
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetched;

  // ── Preference flags (toggled from Settings > Notifications) ─
  bool billRemindersEnabled = true;
  bool goalAlertsEnabled = true;

  // ── SharedPreferences key prefix for persisting read state ──
  static const String _readPrefPrefix = 'notif_read_';

  // ── Thresholds ─────────────────────────────────────────────
  static const int _billWarningDays = 7;
  static const int _goalWarningDays = 14;

  // ── Public getters ─────────────────────────────────────────
  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  bool get isLoading => _isLoading;

  String? get error => _error;

  // ── Persist read IDs via SharedPreferences ─────────────────

  Future<Set<String>> _loadReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_readPrefPrefix));
      return keys.map((k) => k.replaceFirst(_readPrefPrefix, '')).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _persistReadId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_readPrefPrefix$id', true);
    } catch (_) {}
  }

  Future<void> _removeReadId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_readPrefPrefix$id');
    } catch (_) {}
  }

  Future<void> _clearAllReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((k) => k.startsWith(_readPrefPrefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  // ── Refresh ────────────────────────────────────────────────

  Future<void> refresh({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastFetched != null &&
        now.difference(_lastFetched!).inSeconds < 60) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final generated = <AppNotification>[];
    final today = DateTime(now.year, now.month, now.day);

    // Load persisted read IDs before building the list
    final readIds = await _loadReadIds();

    try {
      // ── Bill reminders ──────────────────────────────────────
      if (billRemindersEnabled) {
        try {
          final rawBills = await BillService.getBills();
          for (final map in rawBills) {
            final isPaid =
                map['is_paid'] == true || map['isPaid'] == true;
            if (isPaid) continue;

            final raw =
                (map['next_due_date'] ?? map['nextDueDate'] ?? '') as String;
            if (raw.isEmpty) continue;

            DateTime dueDate;
            try {
              dueDate = DateTime.parse(raw);
            } catch (_) {
              continue;
            }

            final days =
                DateTime(dueDate.year, dueDate.month, dueDate.day)
                    .difference(today)
                    .inDays;
            if (days > _billWarningDays) continue;

            final name = (map['name'] ?? 'Bill') as String;
            final amount = (map['amount'] is num
                    ? (map['amount'] as num)
                    : double.tryParse(
                            map['amount']?.toString() ?? '0') ??
                        0)
                .toInt();
            final id =
                (map['bill_id'] ?? map['id'] ?? 0).toString();
            final notifId = 'bill_$id';

            String title;
            String body;
            if (days < 0) {
              title = '⚠️ Overdue: $name';
              body =
                  'Rs. $amount was due ${-days} day${-days == 1 ? '' : 's'} ago. Mark it paid in Bills.';
            } else if (days == 0) {
              title = '🔔 Due Today: $name';
              body = 'Rs. $amount is due today! Head to Bills to pay it.';
            } else {
              title = '📅 Upcoming Bill: $name';
              body =
                  'Rs. $amount is due in $days day${days == 1 ? '' : 's'}.';
            }

            generated.add(AppNotification(
              id: notifId,
              type: NotificationType.billDue,
              title: title,
              body: body,
              timestamp: now,
              daysUntil: days,
              // Honour persisted read state; fall back to in-memory
              isRead: readIds.contains(notifId) ||
                  (_notifications
                      .where((n) => n.id == notifId)
                      .map((n) => n.isRead)
                      .firstOrNull ??
                      false),
            ));
          }
        } catch (_) {}
      }

      // ── Goal deadline reminders ─────────────────────────────
      if (goalAlertsEnabled) {
        try {
          final goals = await GoalService.getGoals();
          for (final goal in goals) {
            if (goal.deadline == null || goal.deadline!.isEmpty) continue;
            if (goal.targetAmount > 0 &&
                goal.savedAmount >= goal.targetAmount) continue;

            DateTime deadline;
            try {
              deadline = DateTime.parse(goal.deadline!);
            } catch (_) {
              continue;
            }

            final days =
                DateTime(deadline.year, deadline.month, deadline.day)
                    .difference(today)
                    .inDays;
            if (days > _goalWarningDays) continue;

            final progress = goal.targetAmount > 0
                ? (goal.savedAmount / goal.targetAmount * 100)
                    .clamp(0.0, 100.0)
                    .toStringAsFixed(0)
                : '0';
            final remaining = (goal.targetAmount - goal.savedAmount)
                .clamp(0.0, double.infinity);
            final notifId = 'goal_${goal.id}';

            String title;
            String body;
            if (days < 0) {
              title = '⚠️ Goal Missed: ${goal.title}';
              body =
                  'Deadline passed ${-days} day${-days == 1 ? '' : 's'} ago. At $progress% of Rs. ${goal.targetAmount.toStringAsFixed(0)}.';
            } else if (days == 0) {
              title = '🎯 Goal Deadline Today: ${goal.title}';
              body =
                  'Today is your deadline! Rs. ${remaining.toStringAsFixed(0)} still needed.';
            } else {
              title = '🎯 Goal Deadline Soon: ${goal.title}';
              body =
                  '$days day${days == 1 ? '' : 's'} left. Rs. ${remaining.toStringAsFixed(0)} still needed ($progress% saved).';
            }

            generated.add(AppNotification(
              id: notifId,
              type: NotificationType.goalDeadline,
              title: title,
              body: body,
              timestamp: now,
              daysUntil: days,
              isRead: readIds.contains(notifId) ||
                  (_notifications
                      .where((n) => n.id == notifId)
                      .map((n) => n.isRead)
                      .firstOrNull ??
                      false),
            ));
          }
        } catch (_) {}
      }

      generated.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
      _notifications = generated;
      _lastFetched = now;
    } catch (e) {
      _error = 'Could not load notifications. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mark read / dismiss ────────────────────────────────────

  void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx].isRead = true;
      _persistReadId(id); // fire-and-forget
      notifyListeners();
    }
  }

  void markAllRead() {
    bool changed = false;
    for (final n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        _persistReadId(n.id);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void dismiss(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _removeReadId(id);
    notifyListeners();
  }

  /// Call on logout to wipe all persisted read state.
  Future<void> reset() async {
    _notifications = [];
    _lastFetched = null;
    _error = null;
    await _clearAllReadIds();
    notifyListeners();
  }
}