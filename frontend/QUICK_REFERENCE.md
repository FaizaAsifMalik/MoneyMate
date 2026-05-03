# 🎯 MoneyMate Frontend-Backend Integration - Quick Reference

## 📋 What's Been Done

Your Flutter frontend is now **fully connected** to your Node.js backend! All API services are implemented and ready to use.

## 🚀 Quick Start (5 minutes)

### 1. Start Backend
```bash
cd d:\backend (3)\backend
npm install
npm run dev
# Visit http://localhost:3000 to verify
```

### 2. Use Services in Your Screens

**Example 1: Login**
```dart
import 'package:moneymate/services/auth_service.dart';

void login() async {
  try {
    final result = await AuthService.login(
      email: 'user@example.com',
      password: 'password123',
    );
    print('Logged in! Token: ${result['token']}');
  } catch (e) {
    print('Error: $e');
  }
}
```

**Example 2: Get Expenses**
```dart
import 'package:moneymate/services/expense_service.dart';

void loadExpenses() async {
  try {
    final expenses = await ExpenseService.getExpenses();
    setState(() {
      this.expenses = expenses;
    });
  } catch (e) {
    print('Error: $e');
  }
}
```

**Example 3: Add Expense**
```dart
import 'package:moneymate/services/expense_service.dart';
import 'package:moneymate/models/expense_model.dart';

void addExpense() async {
  try {
    final expense = await ExpenseService.addExpense(
      ExpenseModel(
        id: 0,
        amount: 50.0,
        description: 'Groceries',
        categoryId: 1,
        date: DateTime.now().toString().split(' ')[0],
      ),
    );
    print('Expense added!');
  } catch (e) {
    print('Error: $e');
  }
}
```

## 📦 Available Services

### Core Services
| Service | Purpose | Key Methods |
|---------|---------|------------|
| **AuthService** | Login/Register/OTP | `login()`, `register()`, `sendOtp()`, `resetPassword()`, `logout()` |
| **ApiService** | Base HTTP Client | `get()`, `post()`, `put()`, `delete()`, `setToken()`, `clearToken()` |

### Data Services
| Service | Purpose | Key Methods |
|---------|---------|------------|
| **ExpenseService** | Manage expenses | `getExpenses()`, `addExpense()`, `updateExpense()`, `deleteExpense()` |
| **IncomeService** | Manage income | `getIncomes()`, `addIncome()`, `updateIncome()`, `deleteIncome()` |
| **CategoryService** | Manage categories | `getCategories()`, `createCategory()`, `updateCategory()`, `deleteCategory()` |
| **GoalService** | Manage financial goals | `getGoals()`, `addGoal()`, `updateGoal()`, `deleteGoal()` |
| **BudgetService** | Manage budgets | `getBudgets()`, `createBudget()`, `updateBudget()`, `deleteBudget()` |
| **BillService** | Manage bills | `getBills()`, `createBill()`, `updateBill()`, `deleteBill()`, `markAsPaid()` |

### User & Settings
| Service | Purpose | Key Methods |
|---------|---------|------------|
| **UserService** | User profile | `getProfile()`, `updateProfile()`, `updateCurrency()`, `updateProfilePicture()` |
| **NotificationService** | Notifications | `getNotifications()`, `markAsRead()`, `deleteNotification()`, `getUnreadCount()` |
| **AIService** | AI insights | `getSpendingInsights()`, `getBudgetRecommendations()`, `getSpendingForecast()` |

## 🔄 Token Management

Tokens are **automatically managed**. After login, all subsequent requests automatically include the token:

```dart
// After successful login, token is saved
await AuthService.login(email: 'user@example.com', password: 'pass123');

// All future requests automatically include token
final expenses = await ExpenseService.getExpenses(); // Token included! ✅

// On logout, token is cleared
AuthService.logout();
```

## 📝 Common Patterns

### Pattern 1: FutureBuilder in UI
```dart
FutureBuilder<List<ExpenseModel>>(
  future: ExpenseService.getExpenses(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    return ListView.builder(
      itemCount: snapshot.data?.length ?? 0,
      itemBuilder: (context, index) {
        return ListTile(title: Text(snapshot.data![index].description));
      },
    );
  },
)
```

### Pattern 2: Try-Catch
```dart
try {
  final expenses = await ExpenseService.getExpenses();
  setState(() {
    this.expenses = expenses;
  });
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

### Pattern 3: Refresh Data
```dart
Future<void> _refresh() async {
  setState(() {
    _expensesFuture = ExpenseService.getExpenses();
  });
}

// In UI:
RefreshIndicator(
  onRefresh: _refresh,
  child: ListView(...),
)
```

## 🎓 Learning Path

1. **Start Here**: Read `INTEGRATION_GUIDE.md` for complete examples
2. **See Example**: Check `lib/screens/expense_screen_example.dart`
3. **Implement**: Update your actual screens to use services
4. **Test**: Use Postman to verify endpoints (optional)

## 🧪 Testing Endpoints (Optional)

Use Postman or curl to test:

```bash
# Test backend is running
curl http://localhost:3000/health

# Register user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@example.com","password":"pass123"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"pass123"}'

# Get expenses (replace TOKEN with actual token)
curl http://localhost:3000/api/expenses \
  -H "Authorization: Bearer TOKEN"
```

## ⚠️ Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "Connection refused" | Backend not running. Run `npm run dev` in backend folder |
| "Unauthorized (401)" | Token expired. Login again |
| "Not Found (404)" | Wrong endpoint. Check service file for correct path |
| JSON decode error | Backend response format differs. Check network tab in DevTools |
| "Cannot find module" | Missing import. Check if file exists in services folder |

## 📂 File Structure

```
lib/
├── services/
│   ├── api_service.dart           ← Base HTTP client
│   ├── auth_service.dart          ← Authentication
│   ├── expense_service.dart       ← Expenses
│   ├── income_service.dart        ← Income
│   ├── category_service.dart      ← Categories
│   ├── goal_service.dart          ← Goals
│   ├── user_service.dart          ← User profile
│   ├── budget_service.dart        ← Budgets
│   ├── bill_service.dart          ← Bills
│   ├── notification_service.dart  ← Notifications
│   └── ai_service.dart            ← AI insights
├── config/
│   └── app_config.dart            ← Environment config
├── models/
│   ├── user_model.dart
│   ├── expense_model.dart
│   ├── income_model.dart
│   ├── category_model.dart
│   └── goal_model.dart
└── screens/
    └── expense_screen_example.dart ← Example implementation
```

## 🔌 Backend API Structure

```
http://localhost:3000/api/

├── /auth
│   ├── POST /register
│   ├── POST /login
│   ├── POST /send-otp
│   └── POST /reset-password
├── /users
│   ├── GET /profile
│   ├── PUT /profile
│   ├── PUT /currency
│   └── PUT /profile/picture
├── /categories
│   ├── GET /
│   ├── GET /:id
│   ├── POST /
│   ├── PUT /:id
│   └── DELETE /:id
├── /expenses
│   ├── GET /
│   ├── GET /summary
│   ├── GET /monthly
│   ├── GET /:id
│   ├── POST /
│   ├── PUT /:id
│   └── DELETE /:id
├── /incomes
│   ├── GET /
│   ├── GET /summary
│   ├── GET /monthly
│   ├── GET /:id
│   ├── POST /
│   ├── PUT /:id
│   └── DELETE /:id
├── /budgets
│   ├── GET /
│   ├── GET /:id
│   ├── GET /:id/alert
│   ├── POST /
│   ├── PUT /:id
│   └── DELETE /:id
├── /goals
│   ├── GET /
│   ├── GET /:id
│   ├── POST /
│   ├── PUT /:id
│   └── DELETE /:id
├── /bills
│   ├── GET /
│   ├── GET /upcoming
│   ├── GET /:id
│   ├── POST /
│   ├── PUT /:id
│   ├── PUT /:id/pay
│   └── DELETE /:id
├── /notifications
│   ├── GET /
│   ├── GET /unread/count
│   ├── GET /:id
│   ├── PUT /:id/read
│   ├── PUT /read-all
│   └── DELETE /:id
└── /ai
    ├── GET /insights
    ├── GET /recommendations/budget
    ├── GET /forecast
    ├── GET /analysis/categories
    └── GET /opportunities/savings
```

## 📖 Documentation Files

- **INTEGRATION_GUIDE.md** - Complete guide with code examples for all services
- **BACKEND_CONNECTION.md** - Backend setup and integration overview
- **lib/screens/expense_screen_example.dart** - Working example screen
- **lib/config/app_config.dart** - Environment configuration

## 🎯 Next Steps

1. ✅ Backend is ready at `http://localhost:3000/api`
2. 📝 Update your `login_screen.dart` to use `AuthService`
3. 📊 Update your `dashboard_screen.dart` to use services
4. 💰 Update your `expense_screen.dart` to use `ExpenseService`
5. 🧪 Test all screens

## 💡 Pro Tips

- **Use FutureBuilder** for loading states
- **Wrap in try-catch** for error handling
- **Show SnackBar** for user feedback
- **Use RefreshIndicator** for pull-to-refresh
- **Cache data** when appropriate to reduce API calls

## ❓ Need Help?

Refer to:
1. **INTEGRATION_GUIDE.md** - Detailed examples
2. **expense_screen_example.dart** - Working implementation
3. **Service files** - Well-commented code

---

**Status**: ✅ Fully integrated and ready to use!

Start implementing in your screens today! 🚀
