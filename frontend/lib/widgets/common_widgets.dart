import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notifications_service.dart';

// ─────────────────────────────────────────────────────────────
// PROFILE IMAGE NOTIFIER  (app-wide singleton)
// ─────────────────────────────────────────────────────────────

class ProfileImageNotifier extends ValueNotifier<String?> {
  static final ProfileImageNotifier _instance =
      ProfileImageNotifier._internal();
  factory ProfileImageNotifier() => _instance;
  ProfileImageNotifier._internal() : super(null);
}

// ─────────────────────────────────────────────────────────────
// PROFILE AVATAR  (shown top-right on every screen)
// ─────────────────────────────────────────────────────────────

class ProfileAvatar extends StatelessWidget {
  final double radius;
  const ProfileAvatar({super.key, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: ProfileImageNotifier(),
      builder: (context, imagePath, _) {
        return GestureDetector(
          onTap: () => _showProfilePicOptions(context),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.primaryMid,
            backgroundImage:
                imagePath != null ? AssetImage(imagePath) : null,
            child: imagePath == null
                ? Icon(Icons.person,
                    size: radius * 1.1, color: AppColors.white)
                : null,
          ),
        );
      },
    );
  }

  void _showProfilePicOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardLight,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Profile Picture',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryDark),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ProfileOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Gallery picker will be connected to backend'),
                          backgroundColor: AppColors.primaryMid),
                    );
                  },
                ),
                _ProfileOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Camera will be connected to backend'),
                          backgroundColor: AppColors.primaryMid),
                    );
                  },
                ),
                _ProfileOption(
                  icon: Icons.delete_outline,
                  label: 'Remove',
                  color: AppColors.accentRed,
                  onTap: () {
                    ProfileImageNotifier().value = null;
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ProfileOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.primaryMid,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFICATION BELL ICON  (shown top-right on every screen)
// ─────────────────────────────────────────────────────────────

class NotificationBellIcon extends StatefulWidget {
  final VoidCallback? onTap;

  const NotificationBellIcon({super.key, this.onTap});

  @override
  State<NotificationBellIcon> createState() => _NotificationBellIconState();
}

class _NotificationBellIconState extends State<NotificationBellIcon> {
  final _service = NotificationService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_rebuild);
    // Kick off a background refresh so the badge is up to date
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
    final hasUnread = _service.hasUnread;
    return GestureDetector(
      onTap: widget.onTap ?? () => Navigator.pushNamed(context, '/notifications'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryMid.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.white,
              size: 20,
            ),
          ),
          if (hasUnread)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accentPink,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sidebar Navigation ─────────────────────────────────────────────────────
class AppSidebar extends StatelessWidget {
  final String activeItem;
  final VoidCallback onLogout;

  const AppSidebar({
    super.key,
    required this.activeItem,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final mainItems = [
      _NavEntry('Dashboard', Icons.dashboard_outlined, '/dashboard'),
      _NavEntry('Income', Icons.trending_up, '/income'),
      _NavEntry('Expenses', Icons.trending_down, '/expenses'),
      _NavEntry('Bill', Icons.receipt_outlined, '/bill'),
      _NavEntry('Smart Spending', Icons.auto_awesome_outlined, '/ai_screen'),
    ];

    final secondaryItems = [
      _NavEntry('Settings', Icons.settings_outlined, '/account'),
      _NavEntry('About', Icons.info_outline, '/about'),
    ];

    return Container(
      width: 130,
      color: AppColors.primaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          Column(
            children: const [
              Text('💰', style: TextStyle(fontSize: 36)),
              SizedBox(height: 4),
              Text(
                'MONEYMATE',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'CASH IN CONTROL',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 7,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Menu',
            style: TextStyle(color: AppColors.textLight, fontSize: 13),
          ),

          const Divider(color: AppColors.primaryMid, height: 16),

          ...mainItems.map(
            (e) => _NavItem(
              label: e.label,
              icon: e.icon,
              isActive: activeItem == e.label,
              isBold: true,
              onTap: () => _navigate(context, e, activeItem),
            ),
          ),

          const SizedBox(height: 8),

          ...secondaryItems.map(
            (e) => _NavItem(
              label: e.label,
              icon: e.icon,
              isActive: activeItem == e.label,
              isBold: false,
              onTap: () => _navigate(context, e, activeItem),
            ),
          ),

          const Spacer(),

          GestureDetector(
            onTap: onLogout,
            child: const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: AppColors.textDark, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _navigate(
      BuildContext context, _NavEntry entry, String activeItem) {
    if (activeItem == entry.label) return;
    Navigator.pushReplacementNamed(context, entry.route);
  }
}

class _NavEntry {
  final String label;
  final IconData icon;
  final String route;
  const _NavEntry(this.label, this.icon, this.route);
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isBold;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isBold,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        color: isActive ? AppColors.primaryMid : Colors.transparent,
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.textDark : AppColors.textLight,
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Success Screen ──────────────────────────────────────────────────────────
class SuccessScreen extends StatelessWidget {
  final String message;
  final String? backLabel;
  final VoidCallback? onBack;

  const SuccessScreen({
    super.key,
    required this.message,
    this.backLabel,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final VoidCallback handleBack = onBack ??
        () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (_) => false,
            );

    final String label = backLabel ?? ' Go to Login';

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),

            const SizedBox(height: 28),

            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.successGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.white,
                size: 34,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: handleBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMid,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Confirmation Dialog ─────────────────────────────────────────────────────
class ConfirmDialog extends StatelessWidget {
  final String message;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const ConfirmDialog({
    super.key,
    required this.message,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      // Constrain width so the dialog stays compact
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13,
                  fontFamily: 'Courier',
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: onYes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Yes',
                        style: TextStyle(
                            color: AppColors.textDark, fontSize: 13),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: onNo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                            color: AppColors.primaryDark, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sidebar Scaffold ────────────────────────────────────────────────────────
class SidebarScaffold extends StatelessWidget {
  final String activeNav;
  final Widget content;
  // onLogout kept for API compatibility but logout is always handled
  // internally so it fires from every screen consistently.
  final VoidCallback? onLogout;

  const SidebarScaffold({
    super.key,
    required this.activeNav,
    required this.content,
    this.onLogout,
  });

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => ConfirmDialog(
        message: 'Log out?',
        onYes: () {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/logout_success');
        },
        onNo: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            activeItem: activeNav,
            // Always use internal handler — ignores empty onLogout: () {}
            onLogout: () => _handleLogout(context),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

// ── Section Header ──────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Color bgColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.bgColor = AppColors.cardLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: bgColor,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Pink Button ─────────────────────────────────────────────────────────────
class PinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;

  const PinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Auth Layout ─────────────────────────────────────────────────────────────
class AuthLayout extends StatelessWidget {
  final Widget formContent;

  const AuthLayout({super.key, required this.formContent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── Left: form ──────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              color: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
              ),
              child: formContent,
            ),
          ),

          // ── Right: brand panel ──────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              color: AppColors.primaryLight,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primaryMid,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '💰',
                          style: TextStyle(fontSize: 46),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'MONEYMATE',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        fontFamily: 'Courier',
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'CASH IN CONTROL',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        letterSpacing: 2.5,
                        fontFamily: 'Courier',
                      ),
                    ),
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

// ── Labeled Input ───────────────────────────────────────────────────────────
class LabeledInput extends StatelessWidget {
  final String label;
  final bool obscure;
  final bool hasError;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const LabeledInput({
    super.key,
    required this.label,
    this.obscure = false,
    this.hasError = false,
    this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textLight, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.textDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: hasError ? AppColors.inputErrorBg : AppColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}