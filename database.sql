-- MoneyMate Database Schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  passwordhash VARCHAR(255) NOT NULL,
  currency VARCHAR(10) DEFAULT 'USD',
  createdat TIMESTAMP DEFAULT NOW(),
  updatedat TIMESTAMP DEFAULT NOW()
);

-- Categories
CREATE TABLE categories (
  category_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(10) CHECK (type IN ('income', 'expense')) NOT NULL,
  icon VARCHAR(10) DEFAULT '📁',
  colour VARCHAR(20) DEFAULT '#607D8B',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Incomes
CREATE TABLE incomes (
  income_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  category_id INTEGER REFERENCES categories(category_id) ON DELETE SET NULL,
  amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  date DATE NOT NULL,
  description TEXT DEFAULT '',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Bills
CREATE TABLE bills (
  bill_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  due_date INTEGER NOT NULL CHECK (due_date BETWEEN 1 AND 31),
  frequency VARCHAR(10) CHECK (frequency IN ('monthly', 'yearly')) DEFAULT 'monthly',
  category_id INTEGER REFERENCES categories(category_id) ON DELETE SET NULL,
  is_paid BOOLEAN DEFAULT FALSE,
  next_due_date DATE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Expenses
CREATE TABLE expenses (
  expense_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  category_id INTEGER REFERENCES categories(category_id) ON DELETE SET NULL,
  bill_id INTEGER REFERENCES bills(bill_id) ON DELETE SET NULL,
  amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  date DATE NOT NULL,
  description TEXT DEFAULT '',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Budgets
CREATE TABLE budgets (
  budget_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  category_id INTEGER REFERENCES categories(category_id) ON DELETE CASCADE,
  limit_amount DECIMAL(12, 2) NOT NULL CHECK (limit_amount > 0),
  period VARCHAR(10) CHECK (period IN ('weekly', 'monthly', 'custom')) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT chk_dates CHECK (start_date < end_date)
);

-- Goals
CREATE TABLE goals (
  goal_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  target_amount DECIMAL(12, 2) NOT NULL CHECK (target_amount > 0),
  saved_amount DECIMAL(12, 2) DEFAULT 0 CHECK (saved_amount >= 0),
  deadline DATE NOT NULL,
  status VARCHAR(20) DEFAULT 'in progress' CHECK (status IN ('in progress', 'completed', 'failed')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
  notification_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_expenses_user_date ON expenses(user_id, date DESC);
CREATE INDEX idx_incomes_user_date ON incomes(user_id, date DESC);
CREATE INDEX idx_budgets_user ON budgets(user_id);
CREATE INDEX idx_goals_user ON goals(user_id);
CREATE INDEX idx_bills_user ON bills(user_id);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, is_read);