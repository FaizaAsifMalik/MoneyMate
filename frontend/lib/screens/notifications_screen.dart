import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/notifications_service.dart';

class NotificationsRemindersScreen extends StatefulWidget {
  const NotificationsRemindersScreen({super.key});

  @override
  State<NotificationsRemindersScreen> createState() =>
      _NotificationsRemindersScreenState();
}

class _NotificationsRemindersScreenState
    extends State<NotificationsRemindersScreen> {
  // Use the singleton — same instance as the bell icon
  final _service = NotificationService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
    // Force refresh every time the screen opens so data is fresh
    _service.refresh(force: true);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SidebarScaffold(
      activeNav: 'Dashboard',
      content: Column(
        children: [
          // ── Top Banner ─────────────────────────────────────────────
          _NotificationsBanner(
            unreadCount: _service.unreadCount,
            onMarkAllRead: _service.markAllRead,
            onRefresh: () => _service.refresh(force: true),
          ),

          // ── Content ────────────────────────────────────────────────
          Expanded(
            child: _service.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.primaryMid),
                    ),
                  )
                : _service.error != null
                    ? _ErrorState(
                        message: _service.error!,
                        onRetry: () => _service.refresh(force: true),
                      )
                    : _service.notifications.isEmpty
                        ? const _EmptyState()
                        : _NotificationList(service: _service),
          ),
        ],
      ),
    );
  }
}

// ── Top Banner ───────────────────────────────────────────────────────────────
class _NotificationsBanner extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onMarkAllRead;
  final VoidCallback onRefresh;

  const _NotificationsBanner({
    required this.unreadCount,
    required this.onMarkAllRead,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
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
                      child: const Icon(Icons.notifications_outlined,
                          color: AppColors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  unreadCount > 0
                      ? '$unreadCount unread reminder${unreadCount == 1 ? '' : 's'}'
                      : 'All caught up!',
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
                  GestureDetector(
                    onTap: onRefresh,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMid.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.refresh,
                          color: AppColors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ProfileAvatar(),
                ],
              ),
              if (unreadCount > 0) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onMarkAllRead,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMid.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Notification List ────────────────────────────────────────────────────────
class _NotificationList extends StatelessWidget {
  final NotificationService service;
  const _NotificationList({required this.service});

  @override
  Widget build(BuildContext context) {
    final items = service.notifications;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final notif = items[index];
        return _NotificationCard(
          notification: notif,
          onTap: () {
            service.markRead(notif.id);
            if (notif.type == NotificationType.billDue) {
              Navigator.pushReplacementNamed(context, '/bill');
            } else {
              Navigator.pushReplacementNamed(context, '/budget_dashboard');
            }
          },
          onDismiss: () => service.dismiss(notif.id),
        );
      },
    );
  }
}

// ── Notification Card ────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  Color get _accentColor {
    if (notification.daysUntil < 0) return AppColors.accentRed;
    if (notification.daysUntil == 0) return AppColors.accentPink;
    if (notification.daysUntil <= 3) return const Color(0xFFE67E22);
    return AppColors.primaryMid;
  }

  IconData get _icon {
    if (notification.type == NotificationType.billDue) {
      return Icons.receipt_long_outlined;
    }
    return Icons.flag_outlined;
  }

  String get _urgencyLabel {
    if (notification.daysUntil < 0) return 'OVERDUE';
    if (notification.daysUntil == 0) return 'TODAY';
    if (notification.daysUntil <= 3) return 'URGENT';
    return 'UPCOMING';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline,
            color: AppColors.accentRed, size: 22),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread
                ? AppColors.primaryDark.withOpacity(0.06)
                : AppColors.cardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnread
                  ? _accentColor.withOpacity(0.45)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: _accentColor, size: 20),
              ),
              const SizedBox(width: 12),

              // ── Text ──────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 13,
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _urgencyLabel,
                            style: TextStyle(
                              color: _accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification.type == NotificationType.billDue
                              ? 'View in Bills →'
                              : 'View in Budget →',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryMid.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: AppColors.primaryMid.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No reminders right now',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bills and goal deadline reminders\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error State ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_outlined,
              color: AppColors.accentRed, size: 40),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.accentRed, fontSize: 13)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMid,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}