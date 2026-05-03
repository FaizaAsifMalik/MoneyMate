import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../main.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';    
import '../services/notifications_service.dart';
import '../models/user_model.dart';
// ─────────────────────────────────────────────────────────────
// NOTIFICATION STATE  (persists across navigations in-session)
// ─────────────────────────────────────────────────────────────

class NotificationSettings {
  static final NotificationSettings _instance =
      NotificationSettings._internal();
  factory NotificationSettings() => _instance;
  NotificationSettings._internal();

  bool budgetAlerts = false;
  bool billReminders = false;
  bool linkEmail = false;
  bool weeklyReport = false;
  bool goalMilestones = false;
}

// ─────────────────────────────────────────────────────────────
// ACCOUNT SCREEN
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// CURRENCY NOTIFIER  (app-wide, persists in-session)
// ─────────────────────────────────────────────────────────────

class CurrencyNotifier extends ValueNotifier<String> {
  static final CurrencyNotifier _instance = CurrencyNotifier._internal();
  factory CurrencyNotifier() => _instance;
  CurrencyNotifier._internal() : super('PKR');

  String get symbol {
    switch (value) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return 'Rs.';
    }
  }

  String get label {
    switch (value) {
      case 'USD':
        return 'USD – US Dollar';
      case 'EUR':
        return 'EUR – Euro';
      case 'GBP':
        return 'GBP – Pound Sterling';
      default:
        return 'PKR – Pakistani Rupee';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// SETTINGS SCAFFOLD
// ─────────────────────────────────────────────────────────────

class SettingsScaffold extends StatelessWidget {
  final String activeSettings;
  final Widget content;

  const SettingsScaffold({
    super.key,
    required this.activeSettings,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      'Account',
      'Notifications',
      'Preferences',
      'Help and support',
    ];

    return SidebarScaffold(
      activeNav: 'Settings',
      onLogout: () {},
      content: Row(
        children: [
          Container(
            width: 130,
            color: AppColors.primaryLight,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                ...items.map(
                  (item) => GestureDetector(
                    onTap: () {
                      switch (item) {
                        case 'Account':
                          Navigator.pushNamed(context, '/account');
                          break;
                        case 'Notifications':
                          Navigator.pushNamed(context, '/notification_settings');
                          break;
                        case 'Preferences':
                          Navigator.pushNamed(context, '/preferences');
                          break;
                        case 'Help and support':
                          Navigator.pushNamed(context, '/help_support');
                          break;
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      color: activeSettings == item
                          ? AppColors.primaryDark
                          : Colors.transparent,
                      child: Text(
                        item,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: activeSettings == item
                              ? AppColors.white
                              : AppColors.white.withOpacity(0.75),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACCOUNT SCREEN
// ─────────────────────────────────────────────────────────────

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoading = true;
  String? _error;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final user = await UserService.getProfile();
      if (mounted) setState(() { _user = user; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      activeSettings: 'Account',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsBanner(
            icon: Icons.person_outline,
            title: 'Account',
            subtitle: 'Manage your profile information',
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: const TextStyle(color: AppColors.accentRed),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                                onPressed: _loadProfile,
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.primaryMid,
                            child: Text(
                              (_user?.name ?? '?').isNotEmpty
                                  ? (_user!.name[0].toUpperCase())
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 36,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.accentPink,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.white, width: 2),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.edit,
                                  size: 13, color: AppColors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const _SectionLabel(label: 'Profile Details'),
                    const SizedBox(height: 10),

                    _InfoTile(label: 'Full Name', value: _user?.name ?? '—'),
                    const SizedBox(height: 10),
                    _InfoTile(label: 'Email', value: _user?.email ?? '—'),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.pushNamed(context, '/edit_account');
                          _loadProfile();
                        },
                        icon: const Icon(Icons.edit_outlined,
                            size: 16, color: AppColors.white),
                        label: const Text('Edit Account',
                            style: TextStyle(color: AppColors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMid,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => ConfirmDialog(
                              message:
                                  'Delete your account?\nThis cannot be undone.',
                              onYes: () async {
                                Navigator.pop(context);
                                try {
                                  await UserService.deleteAccount();
                                  ApiService.clearToken();
                                  if (context.mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/confirm_acc_delete',
                                      (_) => false,
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to delete account. Please try again.',
                                        ),
                                        backgroundColor: AppColors.accentRed,
                                      ),
                                    );
                                  }
                                }
                              },
                              onNo: () => Navigator.pop(context),
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.accentRed),
                        label: const Text('Delete Account'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentRed,
                          side:
                              const BorderSide(color: AppColors.accentRed),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
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

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(10),
        border: Border(
            left: BorderSide(color: AppColors.primaryMid, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textLight, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EDIT ACCOUNT SCREEN
// ─────────────────────────────────────────────────────────────

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  bool _isLoading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final user = await UserService.getProfile();
      if (mounted) {
        _nameCtrl.text = user.name;
        _emailCtrl.text = user.email;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await UserService.updateProfile(name: name, email: email);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account updated successfully!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      activeSettings: 'Account',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsBanner(
            icon: Icons.edit_outlined,
            title: 'Edit Account',
            subtitle: 'Update your profile information',
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.accentRed)))
                    : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'Profile Details'),
                    const SizedBox(height: 12),

                    _EditField(label: 'Full Name', controller: _nameCtrl),
                    const SizedBox(height: 14),
                    _EditField(
                        label: 'Email',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMid,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white))
                                : const Text('Save Changes',
                                    style: TextStyle(color: AppColors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textMid,
                              side: const BorderSide(
                                  color: AppColors.primaryLight),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
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

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFICATION SETTINGS SCREEN  (toggles / preferences)
// ─────────────────────────────────────────────────────────────

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _prefs = NotificationSettings();

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      activeSettings: 'Notifications',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsBanner(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage how and when MoneyMate notifies you',
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'Alert Preferences'),
                    const SizedBox(height: 12),

                    _NotifTile(
                      title: 'Budget Alerts',
                      subtitle:
                          'Get notified when you exceed a budget limit.',
                      icon: Icons.pie_chart_outline,
                      value: _prefs.budgetAlerts,
                      onChanged: (v) =>
                          setState(() => _prefs.budgetAlerts = v),
                    ),
                    _NotifTile(
                      title: 'Bill Reminders',
                      subtitle:
                          'Reminders before upcoming bill due dates.',
                      icon: Icons.receipt_outlined,
                      value: _prefs.billReminders,
                      onChanged: (v) =>
                          setState(() => _prefs.billReminders = v),
                    ),
                    _NotifTile(
                      title: 'Link Email',
                      subtitle:
                          'Receive notifications via email as well.',
                      icon: Icons.email_outlined,
                      value: _prefs.linkEmail,
                      onChanged: (v) =>
                          setState(() => _prefs.linkEmail = v),
                    ),
                    _NotifTile(
                      title: 'Weekly Report',
                      subtitle: 'A summary of your spending every week.',
                      icon: Icons.bar_chart_outlined,
                      value: _prefs.weeklyReport,
                      onChanged: (v) =>
                          setState(() => _prefs.weeklyReport = v),
                    ),
                    _NotifTile(
                      title: 'Goal Milestones',
                      subtitle:
                          'Celebrate when you hit a savings goal.',
                      icon: Icons.flag_outlined,
                      value: _prefs.goalMilestones,
                      onChanged: (v) =>
                          setState(() => _prefs.goalMilestones = v),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Sync toggle states into NotificationService
                          final svc = NotificationService();
                          svc.billRemindersEnabled = _prefs.billReminders;
                          svc.goalAlertsEnabled = _prefs.goalMilestones;
                          // Force a fresh fetch with the new settings
                          svc.refresh(force: true);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Notification preferences saved!'),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMid,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Preferences',
                            style: TextStyle(color: AppColors.white)),
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

class _NotifTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: value
            ? Border.all(
                color: AppColors.primaryMid.withOpacity(0.4))
            : null,
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (value ? AppColors.primaryMid : AppColors.textLight)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color:
                  value ? AppColors.primaryMid : AppColors.textLight,
              size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textDark)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textLight)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryMid,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PREFERENCES SCREEN
// ─────────────────────────────────────────────────────────────

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _currency = CurrencyNotifier();

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ThemeProvider.of(context);

    return SettingsScaffold(
      activeSettings: 'Preferences',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsBanner(
            icon: Icons.tune_outlined,
            title: 'Preferences',
            subtitle: 'Customise your MoneyMate experience',
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'Appearance'),
                    const SizedBox(height: 10),

                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeNotifier,
                      builder: (context, mode, _) {
                        final isDark = mode == ThemeMode.dark;
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardLight,
                            borderRadius: BorderRadius.circular(12),
                            border: isDark
                                ? Border.all(
                                    color: AppColors.primaryMid
                                        .withOpacity(0.4))
                                : null,
                          ),
                          child: SwitchListTile(
                            secondary: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.primaryMid
                                        : AppColors.textLight)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined,
                                color: isDark
                                    ? AppColors.primaryMid
                                    : AppColors.textLight,
                                size: 20,
                              ),
                            ),
                            title: const Text('Dark Mode',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textDark)),
                            subtitle: Text(
                              isDark
                                  ? 'Dark theme active'
                                  : 'Light theme active',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight),
                            ),
                            value: isDark,
                            onChanged: (v) {
                              if (v) {
                                themeNotifier.setDark();
                              } else {
                                themeNotifier.setLight();
                              }
                            },
                            activeColor: AppColors.primaryMid,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    const _SectionLabel(label: 'Currency'),
                    const SizedBox(height: 10),

                    ValueListenableBuilder<String>(
                      valueListenable: _currency,
                      builder: (context, curr, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.cardLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: curr,
                              isExpanded: true,
                              icon: const Icon(Icons.expand_more,
                                  color: AppColors.primaryLight),
                              items: const [
                                DropdownMenuItem(
                                    value: 'PKR',
                                    child:
                                        Text('PKR – Pakistani Rupee')),
                                DropdownMenuItem(
                                    value: 'USD',
                                    child: Text('USD – US Dollar')),
                                DropdownMenuItem(
                                    value: 'EUR',
                                    child: Text('EUR – Euro')),
                                DropdownMenuItem(
                                    value: 'GBP',
                                    child:
                                        Text('GBP – Pound Sterling')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  _currency.value = v;
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),
                    ValueListenableBuilder<String>(
                      valueListenable: _currency,
                      builder: (context, curr, _) => Text(
                        'Currency symbol will appear as "${_currency.symbol}" throughout the app.',
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 11),
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Preferences saved!'),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMid,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Preferences',
                            style: TextStyle(color: AppColors.white)),
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

// ─────────────────────────────────────────────────────────────
// HELP & SUPPORT SCREEN
// ─────────────────────────────────────────────────────────────

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      const _FAQ(
        q: 'How do I add a budget category?',
        a: 'Go to Budget Dashboard → Add Category. Fill in the name and monthly limit, then tap Save.',
      ),
      const _FAQ(
        q: 'Can I edit a transaction after adding it?',
        a: 'Yes — open the Expenses or Income screen, tap the edit icon on the transaction row, make your changes, and tap Save.',
      ),
      const _FAQ(
        q: 'How do I reset my password?',
        a: 'On the Login screen tap "Forgot Password", enter your email, and follow the instructions sent to your inbox.',
      ),
      const _FAQ(
        q: 'Is my data backed up?',
        a: 'MoneyMate stores data locally on your device. Export your data regularly from Preferences → Export.',
      ),
      const _FAQ(
        q: 'How do Smart Spending suggestions work?',
        a: 'The AI analyses your past spending patterns and recommends ways to reduce costs and hit your savings goals faster.',
      ),
    ];

    return SettingsScaffold(
      activeSettings: 'Help and support',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsBanner(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Have a question? We\'ve got you covered',
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ContactCard(
                      icon: Icons.email_outlined,
                      label: 'Email Us',
                      sub: 'support@moneymate.app',
                      onTap: () {},
                    ),

                    const SizedBox(height: 28),

                    const _SectionLabel(
                        label: 'Frequently Asked Questions'),
                    const SizedBox(height: 12),

                    ...faqs.map((faq) => _FAQTile(faq: faq)),
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

class _FAQ {
  final String q;
  final String a;
  const _FAQ({required this.q, required this.a});
}

class _FAQTile extends StatefulWidget {
  final _FAQ faq;
  const _FAQTile({required this.faq});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: _open
            ? Border.all(
                color: AppColors.primaryMid.withOpacity(0.3))
            : null,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.faq.q,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textDark)),
                  ),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primaryLight,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(widget.faq.a,
                  style: const TextStyle(
                      color: AppColors.textMid,
                      fontSize: 12,
                      height: 1.5)),
            ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryMid,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(sub,
                    style: TextStyle(
                        color: AppColors.white.withOpacity(0.7),
                        fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios,
                color: AppColors.white.withOpacity(0.4), size: 14),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────

class _SettingsBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryMid,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier')),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: AppColors.white.withOpacity(0.6),
                        fontSize: 12)),
              ],
            ),
          ),
          const NotificationBellIcon(),
          const SizedBox(width: 10),
          ProfileAvatar(),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textLight,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ABOUT SCREEN
// ─────────────────────────────────────────────────────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SidebarScaffold(
      activeNav: 'About',
      onLogout: () {},
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Text('💰', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text(
              'MONEYMATE',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
                letterSpacing: 2,
              ),
            ),
            const Text(
              'CASH IN CONTROL',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Version 1.0.0',
                  style: TextStyle(
                      color: AppColors.textMid, fontSize: 12)),
            ),
            const SizedBox(height: 32),
            const Text('About MoneyMate',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark)),
            const SizedBox(height: 12),
            const Text(
              'MoneyMate is a personal finance manager designed to help you take control of your money. '
              'Track income, manage expenses, set budgets, pay bills on time, and get AI-powered smart spending insights — all in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMid, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 32),
            _AboutRow(label: 'Developer', value: 'ZFF Team'),
            _AboutRow(
                label: 'Contact', value: 'support@moneymate.app'),
            const SizedBox(height: 32),
            const Text('© 2026 MoneyMate. All rights reserved.',
                style: TextStyle(
                    color: AppColors.textLight, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textLight, fontSize: 13))),
          Expanded(
              flex: 3,
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONFIRM ACCOUNT DELETE SCREEN
// ─────────────────────────────────────────────────────────────

class ConfirmAccDeleteScreen extends StatelessWidget {
  const ConfirmAccDeleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                    color: AppColors.accentRed,
                    shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever,
                    color: AppColors.white, size: 38),
              ),
              const SizedBox(height: 24),
              const Text('Account Deleted',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier')),
              const SizedBox(height: 12),
              Text(
                'Your account has been permanently deleted.\nWe\'re sorry to see you go.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.white.withOpacity(0.75),
                    fontSize: 14,
                    height: 1.5),
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (_) => false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPink,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Back to Login',
                    style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}