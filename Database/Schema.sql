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
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    source VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    note TEXT
);

CREATE TABLE IF NOT EXISTS Category (
    category_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('income','expense')),
    icon VARCHAR(100),
    colour VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Expense (
    expense_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    date DATE NOT NULL,
    description TEXT,
    bill_id INT
);

CREATE TABLE IF NOT EXISTS Budget (
    budget_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    limit_amount NUMERIC(10, 2) NOT NULL CHECK (limit_amount >= 0),
    period VARCHAR(20) NOT NULL CHECK (period IN ('weekly','monthly','custom')), 
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS Goal (
    goal_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    target_amount NUMERIC(10, 2) NOT NULL CHECK (target_amount >= 0),
    saved_amount NUMERIC(10, 2) DEFAULT 0 CHECK (saved_amount >= 0),
    deadline DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'in progress' CHECK (status IN ('in progress','completed','failed'))
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
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    due_date DATE NOT NULL,
    recurrence VARCHAR(50) DEFAULT 'none' CHECK (recurrence IN ('none','weekly','monthly')),
    is_paid BOOLEAN DEFAULT FALSE,
    category_id INT
);

CREATE TABLE IF NOT EXISTS Notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('reminder','alert','info')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS AI_Insights (
    insight_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('suggestion','prediction','trend')),
    content TEXT NOT NULL,
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Chart (
    chart_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    chart_type VARCHAR(50) NOT NULL CHECK (chart_type IN ('bar','line','pie')),
    metric VARCHAR(50) NOT NULL CHECK (metric IN ('expense','income','cashflow','goal')),
    category_id INT,
    data_range_start_date DATE NOT NULL,
    data_range_end_date DATE NOT NULL,
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS BudgetPrediction (
    prediction_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    predicted_amount NUMERIC(10, 2) NOT NULL CHECK (predicted_amount >= 0),
    confidence NUMERIC(5, 2) NOT NULL CHECK (confidence >= 0 AND confidence <= 100),     -- e.g., 87.50 for 87.5%
    based_on_months INT NOT NULL CHECK (based_on_months > 0),   -- how many months of data used
    predicted_for DATE NOT NULL,                 -- month/year for which prediction is made
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS AI_Suggestion (
    suggestion_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('saving','budgeting','investment')),
    content TEXT NOT NULL,
    priority INT DEFAULT 2 CHECK (priority IN (1,2,3)),
    is_read BOOLEAN DEFAULT FALSE,
    based_on_history_from DATE,          -- optional start date for historical data used
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
    period VARCHAR(50) NOT NULL CHECK (period IN ('weekly','monthly','yearly')),
    percentage_change NUMERIC(6,2) NOT NULL,    -- 12.50 for +12.5%
    direction VARCHAR(10) NOT NULL CHECK (direction IN ('up','down')),
    compared VARCHAR(50) NOT NULL,              -- what it's compared against ('last month', 'last year')
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
--Foreign keys:
-- Income -> Users
ALTER TABLE Income
ADD CONSTRAINT fk_income_user
FOREIGN KEY (user_id) REFERENCES Users(userid) ON DELETE CASCADE;

-- Category -> Users
ALTER TABLE Category
ADD CONSTRAINT fk_category_user
FOREIGN KEY (user_id) REFERENCES Users(userid) ON DELETE CASCADE;

-- Expense -> Users
ALTER TABLE Expense
ADD CONSTRAINT fk_expense_user
FOREIGN KEY (user_id) REFERENCES Users(userid) ON DELETE CASCADE;

-- Expense -> Category
ALTER TABLE Expense
ADD CONSTRAINT fk_expense_category
FOREIGN KEY (category_id) REFERENCES Category(category_id) ON DELETE CASCADE;

-- Budget -> Users
ALTER TABLE Budget
ADD CONSTRAINT fk_budget_user
FOREIGN KEY (user_id) REFERENCES Users(userid) ON DELETE CASCADE;

-- Budget -> Category
ALTER TABLE Budget
ADD CONSTRAINT fk_budget_category
FOREIGN KEY (category_id) REFERENCES Category(category_id) ON DELETE CASCADE;

-- Goal -> Users
ALTER TABLE Goal
ADD CONSTRAINT fk_goal_user
FOREIGN KEY (user_id) REFERENCES Users(userid) ON DELETE CASCADE;

-- Emails -> Users
ALTER TABLE Emails
ADD CONSTRAINT fk_email_user
FOREIGN KEY (user_id) REFERENCES Users(userid);

-- Bills -> Users
ALTER TABLE Bills
ADD CONSTRAINT fk_bills_user
FOREIGN KEY (user_id) REFERENCES Users(userid) ON DELETE CASCADE;

-- Bills -> Category
ALTER TABLE Bills
ADD CONSTRAINT fk_bills_category
FOREIGN KEY (category_id) REFERENCES Category(category_id) ON DELETE SET NULL;

-- Notifications -> Users
ALTER TABLE Notifications
ADD CONSTRAINT fk_notifications_user
FOREIGN KEY (user_id) REFERENCES Users(userid) ON DELETE CASCADE;

-- AI_Insights -> Users
ALTER TABLE AI_Insights
ADD CONSTRAINT fk_ai_insights_user
FOREIGN KEY (user_id) REFERENCES Users(userid) ON DELETE CASCADE;

-- Chart -> Users
ALTER TABLE Chart
ADD CONSTRAINT fk_chart_user
FOREIGN KEY (user_id) REFERENCES Users(userid) ON DELETE CASCADE;

-- Chart -> Category
ALTER TABLE Chart
ADD CONSTRAINT fk_chart_category
FOREIGN KEY (category_id) REFERENCES Category(category_id) ON DELETE SET NULL;

-- BudgetPrediction -> Users
ALTER TABLE BudgetPrediction
ADD CONSTRAINT fk_budgetprediction_user
FOREIGN KEY (user_id) REFERENCES Users(userid) ON DELETE CASCADE;

-- BudgetPrediction -> Category
ALTER TABLE BudgetPrediction
ADD CONSTRAINT fk_budgetprediction_category
FOREIGN KEY (category_id) REFERENCES Category(category_id) ON DELETE CASCADE;

-- AI_Suggestion -> Users
ALTER TABLE AI_Suggestion
ADD CONSTRAINT fk_ai_suggestion_user
FOREIGN KEY (user_id) REFERENCES Users(userid) ON DELETE CASCADE;

-- BudgetStrategy -> Users
ALTER TABLE BudgetStrategy
ADD CONSTRAINT fk_budgetstrategy_user
FOREIGN KEY (user_id) REFERENCES Users(userid) ON DELETE CASCADE;

-- TrendAnalysis -> Users
ALTER TABLE TrendAnalysis
ADD CONSTRAINT fk_trendanalysis_user
FOREIGN KEY (user_id) REFERENCES Users(userid) ON DELETE CASCADE;

-- TrendAnalysis -> Category
ALTER TABLE TrendAnalysis
ADD CONSTRAINT fk_trendanalysis_category
FOREIGN KEY (category_id) REFERENCES Category(category_id) ON DELETE CASCADE;

--Expense ->Bills
ALTER TABLE Expense
ADD CONSTRAINT fk_expense_bill
FOREIGN KEY (bill_id) REFERENCES Bills(bill_id) ON DELETE SET NULL;

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

--Check Contraint:
--Income
ALTER TABLE Income
ADD CONSTRAINT chk_income_amount_positive
CHECK (amount > 0);

--Expense
ALTER TABLE Expense
ADD CONSTRAINT chk_expense_amount_positive
CHECK (amount > 0);

--Budget
ALTER TABLE Budget
ADD CONSTRAINT chk_budget_limit_positive
CHECK (limit_amount > 0);

--Goal
ALTER TABLE Goal
ADD CONSTRAINT chk_goal_target_positive
CHECK (target_amount > 0);

ALTER TABLE Goal
ADD CONSTRAINT chk_goal_saved_non_negative
CHECK (saved_amount >= 0 AND saved_amount <= target_amount);

--Indexing:
--Users:
CREATE UNIQUE INDEX idx_users_email ON Users(email);

--Expense:
CREATE INDEX idx_expense_user_date 
ON Expense(user_id, date);

CREATE INDEX idx_expense_category 
ON Expense(category_id);

--Income:
CREATE INDEX idx_income_user_date 
ON Income(user_id, date);

--Category:
CREATE INDEX idx_category_user 
ON Category(user_id);

--Budget:
CREATE INDEX idx_budget_user_category 
ON Budget(user_id, category_id);

--Bills:
CREATE INDEX idx_bills_user 
ON Bills(user_id);

CREATE INDEX idx_bills_due_date 
ON Bills(due_date);

--Notifications:
CREATE INDEX idx_notifications_user_read 
ON Notifications(user_id, is_read);

--Goals:
CREATE INDEX idx_goal_user 
ON Goal(user_id);

--AI:
CREATE INDEX idx_ai_insights_user 
ON AI_Insights(user_id);

CREATE INDEX idx_ai_suggestion_user 
ON AI_Suggestion(user_id);

--Charts and trends:
CREATE INDEX idx_trend_user_category 
ON TrendAnalysis(user_id, category_id);

CREATE INDEX idx_chart_user 
ON Chart(user_id);
