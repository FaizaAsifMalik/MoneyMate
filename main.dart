import 'package:flutter/material.dart';

void main() {
  runApp(const MoneyMateApp());
}

const Color primaryColor = Color(0xFF704C5E);
const Color secondaryColor = Color(0xFFB88C9E);
const Color lightPink = Color(0xFFF1C8DB);
const Color greenColor = Color(0xFF558B6E);
const Color textFieldColor = Color(0xFFD9D9D9);
const Color selectedColor = Color(0xFF8C6378);

class MoneyMateApp extends StatelessWidget {
  const MoneyMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String hint;
  final bool obscure;

  const CustomTextField({
    super.key,
    required this.hint,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: textFieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            color: hover ? secondaryColor : lightPink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Login'),
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FlutterLogo(size: 100),
                const SizedBox(height: 30),
                const CustomTextField(hint: 'Username'),
                const SizedBox(height: 20),
                const CustomTextField(hint: 'Password', obscure: true),
                const SizedBox(height: 25),
                CustomButton(
                  text: 'Login',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text('Forgot Password'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateAccountScreen(),
                      ),
                    );
                  },
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Forgot Password',
      children: [
        const CustomTextField(hint: 'Enter Email'),
        const SizedBox(height: 20),
        CustomButton(
          text: 'Send Mail',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MessageScreen(
                  message: 'Email Sent Successfully',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Reset Password',
      children: [
        const CustomTextField(hint: 'Password', obscure: true),
        const SizedBox(height: 20),
        const CustomTextField(hint: 'Confirm Password', obscure: true),
        const SizedBox(height: 20),
        CustomButton(
          text: 'Reset',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MessageScreen(
                  message: 'Password Reset Successfully',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create Account',
      children: [
        const CustomTextField(hint: 'Username'),
        const SizedBox(height: 20),
        const CustomTextField(hint: 'Email'),
        const SizedBox(height: 20),
        const CustomTextField(hint: 'Password', obscure: true),
        const SizedBox(height: 20),
        const CustomTextField(hint: 'Confirm Password', obscure: true),
        const SizedBox(height: 20),
        CustomButton(
          text: 'Create Account',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MessageScreen(
                  message: 'Account Created Successfully',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class MessageScreen extends StatelessWidget {
  final String message;

  const MessageScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              message,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(title),
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class SideNav extends StatelessWidget {
  const SideNav({super.key});

  Widget item(BuildContext context, String title, Widget screen) {
    return ListTile(
      hoverColor: selectedColor,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: primaryColor,
      child: Column(
        children: [
          const SizedBox(height: 40),
          const FlutterLogo(size: 80),
          const SizedBox(height: 20),
          item(context, 'Dashboard', const DashboardScreen()),
          item(context, 'Income', const IncomeScreen()),
          item(context, 'Expenses', const ExpensesScreen()),
          item(context, 'Bills', const BillsScreen()),
          item(context, 'Account', const AccountScreen()),
          item(context, 'Notifications', const NotificationsScreen()),
          item(context, 'Preferences', const PreferencesScreen()),
          item(context, 'Help & Support', const HelpScreen()),
          item(context, 'About', const AboutScreen()),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Dashboard',
      child: ListView(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BudgetDashboardScreen(),
                ),
              );
            },
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Budget', style: TextStyle(fontSize: 28)),
                    SizedBox(height: 10),
                    Text('Monthly Income: \$5000'),
                    Text('Monthly Expenses: \$3200'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const LinearProgressIndicator(value: 0.7),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(height: 150,
                  decoration: BoxDecoration(
                    color: lightPink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'Recent Activity',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: greenColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'Trends',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Bills',
      child: ListView(
        children: [
          Row(
            children: [
              billCard('Total Bills', '15'),
              billCard('Due Bills', '4'),
              billCard('Paid Bills', '11'),
            ],
          ),
          const SizedBox(height: 20),
          billTile(
            'Electricity Bill',
            'Due in 3 days',
            'Due Date: May 5',
          ),
          billTile(
            'Internet Bill',
            'Paid on Apr 20',
            'Due Date: Apr 18',
          ),
        ],
      ),
    );
  }

  Widget billCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(10),
        height: 120,
        decoration: BoxDecoration(
          color: lightPink,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget billTile(String title, String subtitle, String trailing) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(trailing),
      ),
    );
  }
}

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  Widget categoryTile(String name, String percent, String amount) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text('$percent spent'),
        trailing: Text(amount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Expenses',
      child: ListView(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'Pie Chart',
                style: TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: greenColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'Bar Chart',
                style: TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: lightPink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'Line Chart',
                style: TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 20),
          categoryTile('Shopping', '30%', '\$600'),
          categoryTile('Food', '20%', '\$400'),
          categoryTile('Health', '10%', '\$200'),
          categoryTile('Transport', '15%', '\$300'),
          categoryTile('Utilities', '15%', '\$300'),
          categoryTile('Other', '10%', '\$200'),
        ],
      ),
    );
  }
}

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  Widget incomeCard(String title, String value) {
    return Expanded(
      child: Container(
        height: 120,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: lightPink,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 26),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Income',
      child: ListView(
        children: [
          Row(
            children: [
              incomeCard('Average Income', '\$5000'),
              incomeCard('Highest Income', '\$9000'),
            ],
          ),
          const SizedBox(height: 20),
          const Card(
            child: ListTile(
              title: Text('Job'),
              subtitle: LinearProgressIndicator(value: 0.7),
              trailing: Text('70%'),
            ),
          ),
          const Card(
            child: ListTile(
              title: Text('Freelancing'),
              subtitle: LinearProgressIndicator(value: 0.3),
              trailing: Text('30%'),
            ),
          ),
          const SizedBox(height: 20),
          const ListTile(
            title: Text('April 1'),
            trailing: Text('\$300'),
          ),
          const ListTile(
            title: Text('April 12'),
            trailing: Text('\$500'),
          ),
        ],
      ),
    );
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Account',
      child: ListView(
        children: [
          const CircleAvatar(
            radius: 60,
            child: Icon(Icons.person, size: 60),
          ),
          const SizedBox(height: 20),
          const Text(
            'Zara',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 10),
          const Text('zara@gmail.com'),
          const SizedBox(height: 10),
          const Text('********'),
          const SizedBox(height: 30),
          CustomButton(
            text: 'Edit Account',
            onPressed: () {},
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Delete Account',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'Are you sure you want to delete account?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  bool budgetAlerts = true;
  bool billReminders = true;
  bool linkEmail = false;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Notifications',
      child: ListView(
        children: [
          SwitchListTile(
            value: budgetAlerts,
            title: const Text('Budget Alerts'),
            onChanged: (value) {
              setState(() {
                budgetAlerts = value;
              });
            },
          ),
          SwitchListTile(
            value: billReminders,
            title: const Text('Bill Reminders'),
            onChanged: (value) {
              setState(() {
                billReminders = value;
              });
            },
          ),
          SwitchListTile(
            value: linkEmail,
            title: const Text('Link Another Email'),
            onChanged: (value) {
              setState(() {
                linkEmail = value;
              });
            },
          ),
        ],
      ),
    );
  }
}

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() =>
      _PreferencesScreenState();
}

class _PreferencesScreenState
    extends State<PreferencesScreen> {
  bool darkTheme = false;
  bool aiInsights = true;
  bool budgetPrediction = true;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Preferences',
      child: ListView(
        children: [
          SwitchListTile(
            value: darkTheme,
            title: const Text('Dark Theme'),
            onChanged: (value) {
              setState(() {
                darkTheme = value;
              });
            },
          ),
          SwitchListTile(
            value: aiInsights,
            title: const Text('AI Insights'),
            onChanged: (value) {
              setState(() {
                aiInsights = value;
              });
            },
          ),
          SwitchListTile(
            value: budgetPrediction,
            title: const Text('Budget Prediction'),
            onChanged: (value) {
              setState(() {
                budgetPrediction = value;
              });
            },
          ),
        ],
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Help & Support',
      child: ListView(
        children: const [
          Card(
            child: ListTile(
              title: Text('How do I edit my account?'),
              subtitle: Text(
                'Go to Account screen and click Edit Account',
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Can I recover my account?'),
              subtitle: Text('No'),
            ),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'About',
      child: const Center(
        child: Text(
          'MoneyMate is a personal finance management system that helps users track income and expenses in an organized way.',
          style: TextStyle(fontSize: 24),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class BudgetDashboardScreen extends StatelessWidget {
  const BudgetDashboardScreen({super.key});

  Widget budgetTile(
    String category,
    double progress,
    String left,
  ) {
    return Card(
      child: ListTile(
        title: Text(category),
        subtitle: LinearProgressIndicator(value: progress),
        trailing: Text(left),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Budget Dashboard',
      child: ListView(
        children: [
          budgetTile('Food', 0.6, '\$400 left'),
          budgetTile('Shopping', 0.3, '\$700 left'),
          budgetTile('Health', 0.5, '\$200 left'),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Add Budget Goal',
            onPressed: () {},
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SmartSpendingScreen(),
                ),
              );
            },
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                color: lightPink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'AI Suggestions',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SmartSpendingScreen(),
                ),
              );
            },
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'AI Predictions',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SmartSpendingScreen extends StatelessWidget {
  const SmartSpendingScreen({super.key});

  Widget predictionBar(String title, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: value),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Smart Spending',
      child: ListView(
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'AI Suggestion: Reduce shopping expenses by 10%',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(height: 20),
          predictionBar('Food', 0.7),
          predictionBar('Shopping', 0.8),
          predictionBar('Transport', 0.5),
          predictionBar('Health', 0.4),
        ],
      ),
    );
  }
}

class MainLayout extends StatelessWidget {
  final String title;
  final Widget child;

  const MainLayout({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SideNav(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}