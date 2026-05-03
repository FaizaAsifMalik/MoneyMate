import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/bill_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/income_screen.dart';
import 'screens/budget_screens.dart';
import 'screens/settings_screens.dart';
import 'screens/ai_screen.dart';
import 'screens/notifications_screen.dart';
import 'widgets/common_widgets.dart';

import 'services/notifications_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Prime notification service so the bell badge is ready on first screen
  NotificationService().refresh();
  runApp(const MoneyMateApp());
}

// ─────────────────────────────────────────────────────────────
// THEME NOTIFIER
// ─────────────────────────────────────────────────────────────

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  bool get isDark => value == ThemeMode.dark;

  void setDark() => value = ThemeMode.dark;
  void setLight() => value = ThemeMode.light;
}

// ─────────────────────────────────────────────────────────────
// THEME PROVIDER  (InheritedWidget so any screen can access it)
// ─────────────────────────────────────────────────────────────

class ThemeProvider extends InheritedNotifier<ThemeNotifier> {
  const ThemeProvider({
    super.key,
    required ThemeNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Retrieve the [ThemeNotifier] from the widget tree.
  static ThemeNotifier of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'No ThemeProvider found in widget tree');
    return provider!.notifier!;
  }
}

// ─────────────────────────────────────────────────────────────
// MAIN APP
// ─────────────────────────────────────────────────────────────

class MoneyMateApp extends StatefulWidget {
  const MoneyMateApp({super.key});

  @override
  State<MoneyMateApp> createState() => _MoneyMateAppState();
}

class _MoneyMateAppState extends State<MoneyMateApp> {
  late final ThemeNotifier _themeNotifier;

  @override
  void initState() {
    super.initState();
    _themeNotifier = ThemeNotifier();
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      notifier: _themeNotifier,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeNotifier,
        builder: (context, mode, _) {
          return MaterialApp(
            title: 'MoneyMate',
            debugShowCheckedModeBanner: false,

            themeMode: mode,
            theme: AppTheme.theme,
            darkTheme: AppTheme.darkTheme,

            initialRoute: '/login',

            routes: {
              // ── Auth ──────────────────────────────────────
              '/login': (_) => const LoginScreen(),
              '/forgot_password': (_) => const ForgotPasswordScreen(),
              '/reset_password': (_) => const ResetPasswordScreen(),
              '/create_account': (_) => const CreateAccountScreen(),
              '/email_confirmation': (_) => const EmailConfirmationScreen(),
              '/reset_pw_confirmation': (_) =>
                  const ResetPwConfirmationScreen(),
              '/create_acc_confirmation': (_) =>
                  const CreateAccConfirmationScreen(),

              // ── Main ──────────────────────────────────────
              '/dashboard': (_) => const DashboardScreen(),
              '/budget_dashboard': (_) => const BudgetDashboardScreen(),
              '/logout_success': (_) => const LogoutSuccessScreen(),

              // ── Bill ──────────────────────────────────────
              '/bill': (_) => const BillScreen(),

              // ── Expense ───────────────────────────────────
              '/expenses': (_) => const ExpenseScreen(),

              // ── Income ────────────────────────────────────
              '/income': (_) => const IncomeScreen(),

              // ── AI ────────────────────────────────────────
              '/ai_screen': (_) => const AIScreen(),

              // ── Budget ────────────────────────────────────
              // NOTE: EditBudgetScreen and AddBudgetCategoryScreen are no
              // longer registered here — they require runtime data (budget
              // map, onSave callback, etc.) and are opened via
              // Navigator.push(MaterialPageRoute(...)) inside
              // BudgetDashboardScreen directly.
              '/budget_goal': (_) => const BudgetGoalScreen(),
              '/other_goals': (_) => const GoalHistoryScreen(),

              '/con_acc': (_) => const SuccessScreen(
                    message: 'Goal successfully created!!',
                  ),

              '/con_cat': (_) => const SuccessScreen(
                    message: 'Budget successfully created!!',
                  ),

              // ── Settings ──────────────────────────────────
              '/account': (_) => const AccountScreen(),
              '/edit_account': (_) => const EditAccountScreen(),
              // Bell icon / sidebar → reminders screen
              '/notifications': (_) => const NotificationsRemindersScreen(),
              // Settings sidebar → notification toggles
              '/notification_settings': (_) => const NotificationSettingsScreen(),
              '/preferences': (_) => const PreferencesScreen(),
              '/help_support': (_) => const HelpSupportScreen(),
              '/about': (_) => const AboutScreen(),
              '/confirm_acc_delete': (_) => const ConfirmAccDeleteScreen(),
            },
          );
        },
      ),
    );
  }
}