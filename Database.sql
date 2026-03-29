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
