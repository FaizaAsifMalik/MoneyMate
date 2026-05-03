# MoneyMate Frontend-Backend Integration Guide

## Overview
This guide explains how to use the integrated API services to connect your Flutter frontend to the Node.js backend.

## Backend Configuration

The backend API is available at: `http://localhost:3000/api`

**Base Services:**
- Auth: `/auth`
- Users: `/users`
- Categories: `/categories`
- Expenses: `/expenses`
- Incomes: `/incomes`
- Budgets: `/budgets`
- Goals: `/goals`
- Bills: `/bills`
- Notifications: `/notifications`
- AI: `/ai`

## Available Services

### 1. AuthService
Handles authentication and authorization.

```dart
import 'package:moneymate/services/auth_service.dart';

// Register a new user
final result = await AuthService.register(
  name: 'John Doe',
  email: 'john@example.com',
  password: 'password123',
);

// Login
final loginResult = await AuthService.login(
  email: 'john@example.com',
  password: 'password123',
);
// Token is automatically saved and used for subsequent requests

// Send OTP for password reset
await AuthService.sendOtp(email: 'john@example.com');

// Reset password with OTP
await AuthService.resetPassword(
  email: 'john@example.com',
  otp: '123456',
  newPassword: 'newPassword123',
);

// Check if authenticated
bool isAuth = AuthService.isAuthenticated();

// Logout
AuthService.logout();
```

### 2. ApiService (Base Service)
Centralized HTTP client with token management.

```dart
import 'package:moneymate/services/api_service.dart';

// Set token after login
ApiService.setToken(loginResult['token']);

// Perform authenticated requests
final data = await ApiService.get('expenses');
final postData = await ApiService.post('expenses', {...});
final putData = await ApiService.put('expenses/1', {...});
await ApiService.delete('expenses/1');

// Get current token
String? token = ApiService.getToken();

// Clear token on logout
ApiService.clearToken();
```

### 3. CategoryService
Manage transaction categories.

```dart
import 'package:moneymate/services/category_service.dart';

// Get all categories
final categories = await CategoryService.getCategories();

// Get categories by type
final expenseCategories = await CategoryService.getCategories(type: 'expense');
final incomeCategories = await CategoryService.getCategories(type: 'income');

// Get single category
final category = await CategoryService.getCategoryById(1);

// Create category
final newCategory = await CategoryService.createCategory(
  name: 'Groceries',
  type: 'expense',
  icon: '🛒',
  colour: '#FF6B6B',
);

// Update category
final updated = await CategoryService.updateCategory(
  1,
  name: 'Shopping',
  icon: '🏪',
);

// Delete category
await CategoryService.deleteCategory(1);
```

### 4. ExpenseService
Manage user expenses.

```dart
import 'package:moneymate/services/expense_service.dart';
import 'package:moneymate/models/expense_model.dart';

// Get all expenses
final expenses = await ExpenseService.getExpenses();

// Get expenses with filters
final filtered = await ExpenseService.getExpenses(
  startDate: '2024-01-01',
  endDate: '2024-12-31',
  categoryId: 1,
  limit: 20,
  offset: 0,
);

// Get single expense
final expense = await ExpenseService.getExpenseById(1);

// Create expense
final newExpense = await ExpenseService.addExpense(
  ExpenseModel(
    id: 0,
    amount: 50.0,
    description: 'Grocery shopping',
    categoryId: 1,
    date: '2024-01-15',
  ),
);

// Update expense
final updated = await ExpenseService.updateExpense(1, {
  'amount': 60.0,
  'description': 'Updated description',
});

// Delete expense
await ExpenseService.deleteExpense(1);

// Get expense summary by category
final summary = await ExpenseService.getSummary(
  startDate: '2024-01-01',
  endDate: '2024-12-31',
);

// Get monthly totals
final monthly = await ExpenseService.getMonthlyTotals();
```

### 5. IncomeService
Manage user income.

```dart
import 'package:moneymate/services/income_service.dart';
import 'package:moneymate/models/income_model.dart';

// Get all incomes
final incomes = await IncomeService.getIncomes();

// Get incomes with filters
final filtered = await IncomeService.getIncomes(
  startDate: '2024-01-01',
  endDate: '2024-12-31',
  categoryId: 2,
);

// Get single income
final income = await IncomeService.getIncomeById(1);

// Create income
final newIncome = await IncomeService.addIncome(
  IncomeModel(
    id: 0,
    amount: 3000.0,
    description: 'Monthly salary',
    categoryId: 2,
    categoryName: 'Salary',
    date: '2024-01-01',
  ),
);

// Update income
final updated = await IncomeService.updateIncome(1, {
  'amount': 3500.0,
});

// Delete income
await IncomeService.deleteIncome(1);

// Get monthly totals
final monthly = await IncomeService.getMonthlyTotals();

// Get summary
final summary = await IncomeService.getSummary(
  startDate: '2024-01-01',
  endDate: '2024-12-31',
);
```

### 6. GoalService
Manage financial goals.

```dart
import 'package:moneymate/services/goal_service.dart';
import 'package:moneymate/models/goal_model.dart';

// Get all goals
final goals = await GoalService.getGoals();

// Get single goal
final goal = await GoalService.getGoalById(1);

// Create goal
final newGoal = await GoalService.addGoal(
  GoalModel(
    id: 0,
    title: 'Save for vacation',
    targetAmount: 5000.0,
    savedAmount: 1200.0,
  ),
);

// Update goal
final updated = await GoalService.updateGoal(1, {
  'savedAmount': 1500.0,
});

// Delete goal
await GoalService.deleteGoal(1);
```

### 7. UserService
Manage user profile and settings.

```dart
import 'package:moneymate/services/user_service.dart';

// Get user profile
final profile = await UserService.getProfile();

// Update profile
final updated = await UserService.updateProfile(
  name: 'Jane Doe',
  email: 'jane@example.com',
  phone: '+1234567890',
  currency: 'USD',
);

// Update currency preference
await UserService.updateCurrency('EUR');

// Update profile picture
await UserService.updateProfilePicture('/path/to/image.jpg');
```

### 8. BudgetService
Manage budgets.

```dart
import 'package:moneymate/services/budget_service.dart';

// Get all budgets
final budgets = await BudgetService.getBudgets();

// Get single budget
final budget = await BudgetService.getBudgetById(1);

// Create budget
final newBudget = await BudgetService.createBudget(
  categoryId: 1,
  limit: 500.0,
  period: 'monthly',
  name: 'Groceries Budget',
);

// Update budget
final updated = await BudgetService.updateBudget(1, limit: 600.0);

// Delete budget
await BudgetService.deleteBudget(1);

// Check if budget is exceeded
final alert = await BudgetService.checkBudgetAlert(1);
```

### 9. BillService
Manage recurring bills and payments.

```dart
import 'package:moneymate/services/bill_service.dart';

// Get all bills
final bills = await BillService.getBills();

// Get pending bills
final pending = await BillService.getBills(status: 'pending');

// Get upcoming bills
final upcoming = await BillService.getUpcomingBills(days: 30);

// Get single bill
final bill = await BillService.getBillById(1);

// Create bill
final newBill = await BillService.createBill(
  name: 'Internet Bill',
  amount: 50.0,
  dueDate: '2024-02-01',
  category: 'Utilities',
  frequency: 'monthly',
);

// Update bill
final updated = await BillService.updateBill(1, amount: 55.0);

// Mark bill as paid
await BillService.markAsPaid(1);

// Delete bill
await BillService.deleteBill(1);
```

### 10. NotificationService
Manage notifications.

```dart
import 'package:moneymate/services/notification_service.dart';

// Get all notifications
final notifications = await NotificationService.getNotifications();

// Get unread notifications
final unread = await NotificationService.getNotifications(isRead: false);

// Get single notification
final notification = await NotificationService.getNotificationById(1);

// Get unread count
final count = await NotificationService.getUnreadCount();

// Mark notification as read
await NotificationService.markAsRead(1);

// Mark all as read
await NotificationService.markAllAsRead();

// Delete notification
await NotificationService.deleteNotification(1);
```

### 11. AIService
Get AI-powered insights and recommendations.

```dart
import 'package:moneymate/services/ai_service.dart';

// Get spending insights
final insights = await AIService.getSpendingInsights(
  startDate: '2024-01-01',
  endDate: '2024-12-31',
);

// Get budget recommendations
final recommendations = await AIService.getBudgetRecommendations();

// Get spending forecast
final forecast = await AIService.getSpendingForecast(months: 3);

// Get category analysis
final analysis = await AIService.getCategoryAnalysis(
  startDate: '2024-01-01',
  endDate: '2024-12-31',
);

// Get savings opportunities
final savings = await AIService.getSavingsOpportunities();
```

## Error Handling

All services throw exceptions on errors. Handle them appropriately:

```dart
try {
  final expenses = await ExpenseService.getExpenses();
} catch (e) {
  print('Error: $e');
  // Show error to user
}
```

## Example: Complete Login Flow

```dart
import 'package:moneymate/services/auth_service.dart';
import 'package:moneymate/services/user_service.dart';

void handleLogin(String email, String password) async {
  try {
    // Login
    final result = await AuthService.login(
      email: email,
      password: password,
    );
    
    // Token is automatically saved
    
    // Fetch user profile
    final profile = await UserService.getProfile();
    
    // Navigate to home
    Navigator.of(context).pushReplacementNamed('/home');
  } catch (e) {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login failed: $e')),
    );
  }
}

void handleLogout() {
  AuthService.logout();
  Navigator.of(context).pushReplacementNamed('/login');
}
```

## Token Persistence (Optional)

To persist tokens across app restarts, add `shared_preferences` to `pubspec.yaml` and modify `ApiService`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ... existing code ...

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }
}
```

Then call `ApiService.loadToken()` on app startup.

## Backend Requirements

Make sure your backend is running and accessible:

```bash
cd backend
npm install
npm run dev
# Server should be running on http://localhost:3000
```

## Testing

Use Postman or similar tools to test endpoints:

```
Base URL: http://localhost:3000/api

GET /health  # Check server status
POST /auth/register  # Register user
POST /auth/login  # Login
GET /expenses  # Get expenses (requires auth token)
```

---

For more information, refer to the individual service files in `lib/services/`.
