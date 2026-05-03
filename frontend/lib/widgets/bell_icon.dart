

import 'package:flutter/material.dart';
import '../services/notifications_service.dart';
import '../theme/app_theme.dart';

class NotificationBellIcon extends StatefulWidget {
  const NotificationBellIcon({super.key});

  @override
  State<NotificationBellIcon> createState() => _NotificationBellIconState();
}

class _NotificationBellIconState extends State<NotificationBellIcon> {
  final _service = NotificationService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_rebuild);
    // Kick off a background refresh if needed (respects the 60-second throttle)
    _service.refresh();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = _service.unreadCount;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/notifications'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bell icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryMid.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.white,
              size: 20,
            ),
          ),

          // Badge — only shown when there are unread notifications
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentRed,
                  shape: count < 10 ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: count >= 10 ? BorderRadius.circular(8) : null,
                  border: Border.all(color: AppColors.primaryDark, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
