CREATE TABLE IF NOT EXISTS Users (
    userid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    passwordHash VARCHAR(255) NOT NULL,
    savedPassword VARCHAR(255),
    currency VARCHAR(10),
    createdAt TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS Income (
    income_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    source VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    note TEXT
);

CREATE TABLE IF NOT EXISTS Category (
    category_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    icon VARCHAR(100),
    colour VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Expense (
    expense_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    date DATE NOT NULL,
    description TEXT,
    bill_id INT
);

CREATE TABLE IF NOT EXISTS Budget (
    budget_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    limit_amount NUMERIC(10, 2) NOT NULL,
    period VARCHAR(20) NOT NULL,       --'weekly', 'monthly', 'custom'
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS Goal (
    goal_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    target_amount NUMERIC(10, 2) NOT NULL,
    saved_amount NUMERIC(10, 2) DEFAULT 0,
    deadline DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'in progress'  --'in progress', 'completed', 'failed'
);

CREATE TABLE IF NOT EXISTS Emails (
    email_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    subject VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'sent'  --'sent', 'draft', 'failed'
);

CREATE TABLE IF NOT EXISTS Bills (
    bill_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    due_date DATE NOT NULL,
    recurrence VARCHAR(50) DEFAULT 'none', --'monthly', 'weekly', 'none'
    is_paid BOOLEAN DEFAULT FALSE,
    category_id INT
);

CREATE TABLE IF NOT EXISTS Notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,         --'reminder', 'alert', 'info'
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS AI_Insights (
    insight_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    type VARCHAR(50) NOT NULL,           --'suggestion', 'prediction', 'trend'
    content TEXT NOT NULL,
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Chart (
    chart_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    chart_type VARCHAR(50) NOT NULL,          -- 'bar', 'line', 'pie'
    metric VARCHAR(50) NOT NULL,              -- 'expense', 'income', 'cashflow', 'goal'
    category_id INT,
    data_range_start_date DATE NOT NULL,
    data_range_end_date DATE NOT NULL,
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS BudgetPrediction (
    prediction_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    predicted_amount NUMERIC(10, 2) NOT NULL,
    confidence NUMERIC(5, 2) NOT NULL,           -- e.g., 87.50 for 87.5%
    based_on_months INT NOT NULL,                -- how many months of data used
    predicted_for DATE NOT NULL,                 -- month/year for which prediction is made
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS AI_Suggestion (
    suggestion_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    type VARCHAR(50) NOT NULL,                   -- 'saving', 'budgeting', 'investment'
    content TEXT NOT NULL,
    priority INT DEFAULT 0,                       -- 1 = high, 2 = medium, 3 = low
    is_read BOOLEAN DEFAULT FALSE,
    based_on_history_from DATE,                  -- optional start date for historical data used
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS BudgetStrategy (
    strategy_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    strategy_type VARCHAR(50) NOT NULL,     --'saving plan', 'spending limit', 'investment plan'
    custom_rules TEXT,                       -- any custom rules or notes
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS TrendAnalysis (
    trend_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    period VARCHAR(50) NOT NULL,                 --'weekly', 'monthly'
    percentage_change NUMERIC(6,2) NOT NULL,    -- 12.50 for +12.5%
    direction VARCHAR(10) NOT NULL,             -- 'up' or 'down'
    compared VARCHAR(50) NOT NULL,              -- what it's compared against ('last month', 'last year')
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
--Foreign keys:
-- Income → Users
ALTER TABLE Income
ADD CONSTRAINT fk_income_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- Category → Users
ALTER TABLE Category
ADD CONSTRAINT fk_category_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- Expense → Users
ALTER TABLE Expense
ADD CONSTRAINT fk_expense_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- Expense → Category
ALTER TABLE Expense
ADD CONSTRAINT fk_expense_category
FOREIGN KEY (category_id) REFERENCES Category(category_id);

-- Budget → Users
ALTER TABLE Budget
ADD CONSTRAINT fk_budget_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- Budget → Category
ALTER TABLE Budget
ADD CONSTRAINT fk_budget_category
FOREIGN KEY (category_id) REFERENCES Category(category_id);

-- Goal → Users
ALTER TABLE Goal
ADD CONSTRAINT fk_goal_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- Emails → Users
ALTER TABLE Emails
ADD CONSTRAINT fk_email_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- Bills → Users
ALTER TABLE Bills
ADD CONSTRAINT fk_bills_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- Bills → Category
ALTER TABLE Bills
ADD CONSTRAINT fk_bills_category
FOREIGN KEY (category_id) REFERENCES Category(category_id);

-- Notifications → Users
ALTER TABLE Notifications
ADD CONSTRAINT fk_notifications_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- AI_Insights → Users
ALTER TABLE AI_Insights
ADD CONSTRAINT fk_ai_insights_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- Chart → Users
ALTER TABLE Chart
ADD CONSTRAINT fk_chart_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- Chart → Category
ALTER TABLE Chart
ADD CONSTRAINT fk_chart_category
FOREIGN KEY (category_id) REFERENCES Category(category_id);

-- BudgetPrediction → Users
ALTER TABLE BudgetPrediction
ADD CONSTRAINT fk_budgetprediction_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- BudgetPrediction → Category
ALTER TABLE BudgetPrediction
ADD CONSTRAINT fk_budgetprediction_category
FOREIGN KEY (category_id) REFERENCES Category(category_id);

-- AI_Suggestion → Users
ALTER TABLE AI_Suggestion
ADD CONSTRAINT fk_ai_suggestion_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- BudgetStrategy → Users
ALTER TABLE BudgetStrategy
ADD CONSTRAINT fk_budgetstrategy_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- TrendAnalysis → Users
ALTER TABLE TrendAnalysis
ADD CONSTRAINT fk_trendanalysis_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- TrendAnalysis → Category
ALTER TABLE TrendAnalysis
ADD CONSTRAINT fk_trendanalysis_category
FOREIGN KEY (category_id) REFERENCES Category(category_id);

--Unique Constraint:
-- Category: a user shouldn’t have two categories with the same name
ALTER TABLE Category
ADD CONSTRAINT unique_user_category_name UNIQUE (user_id, name);

-- Budget: a user can’t have two budgets for the same category and period
ALTER TABLE Budget
ADD CONSTRAINT unique_user_budget_category_period UNIQUE (user_id, category_id, period);

-- Goal: a user shouldn’t have two goals with the same title
ALTER TABLE Goal
ADD CONSTRAINT unique_user_goal_title UNIQUE (user_id, title);

-- Chart: a user shouldn’t generate duplicate charts for the same type, metric, and category over the same date range
ALTER TABLE Chart
ADD CONSTRAINT unique_user_chart UNIQUE (user_id, chart_type, metric, category_id, data_range_start_date, data_range_end_date);
