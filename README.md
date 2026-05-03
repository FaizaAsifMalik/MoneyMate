# MoneyMate

MoneyMate is a personal finance management app built with Flutter and a hosted Node.js/Express backend. It lets users track expenses, manage bills, set budgets, and get AI-powered spending insights — all in a clean, real-time dashboard.

## Authors

Zara Usman, Fatima Qadeer, Faiza Asif

## Features

- **Expense Tracking** — Log and categorize expenses with Pie, Bar, and Line chart views
- **Income Tracking** — Log and categorize income sources
- **Bill Management** — Track due and paid bills with recurring frequency support
- **Budget Predictions** — AI-generated spending forecasts and category breakdowns
- **Smart Spending** — AI-powered spending suggestions and budget predictions
- **Category Management** — Create, edit, and color-code expense categories
- **Goal Tracking** — Set savings goals and track contributions
- **Real-time Dashboard** — Live stats: total spent, highest transaction, transaction count
- **Email Notifications** — Automated bill reminders via Nodemailer
- **In-App Notifications** — Budget alerts, bill reminders, and goal completions
- **Currency Support** — Multi-currency support with live conversion

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Node.js, Express, JavaScript |
| Database | PostgreSQL (Neon) |
| AI | Claude API |
| Auth | JWT + OTP Email Verification |
| Notifications | Nodemailer + In-App |
| Hosting | Vercel |

## Repository Structure

```
MoneyMate/
├── server.js
├── package.json
├── package-lock.json
├── .env
├── Database/Information
├── database.sql
├── README.md
├── src/
└── frontend/
```

## Design Patterns Implemented

| Pattern | Location |
|---|---|
| Factory | `src/factories/` |
| Repository | `src/repositories/` |
| Observer | `src/observers/` |
| Strategy | `src/strategies/` |
| State | `src/state/` |
| Template | `src/templates/` |
| Adapter | `src/adapters/` |
| Iterator | `src/iterators/` |
| Singleton | `src/services/ServiceContainer.js` |

## SOLID Principles

| Principle | Implementation |
|---|---|
| **Single Responsibility** | Each class has one job — repositories only do CRUD, services only handle business logic, controllers only handle HTTP |
| **Open/Closed** | Strategies and templates are open for extension without modifying existing code |
| **Liskov Substitution** | All repositories extend `BaseRepository` and can be used interchangeably |
| **Interface Segregation** | `IRepository` and `IAnalysisStrategy` define minimal interfaces for each layer |
| **Dependency Inversion** | Services depend on `RepositoryFactory` abstractions, not concrete repository classes |

## Prerequisites

- Flutter SDK 3.x+
- Node.js 20+
- npm
- PostgreSQL database
- Gemini API key (for AI insights)

## Setup

### Backend

```bash
cd backend
npm install
```

Create a `.env` file in the backend directory:

```env
DATABASE_URL=your_neon_postgres_connection_string
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=14d
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_gmail_address
EMAIL_PASSWORD=your_gmail_app_password
EMAIL_FROM=MoneyMate <noreply@moneymate.com>
CURRENCY_API_KEY=your_exchangerate_api_key
CURRENCY_API_URL=https://v6.exchangerate-api.com/v6
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
AI_SERVICE_ENABLED=true
AI_ANALYSIS_THRESHOLD_MONTHS=3
PORT=3000
NODE_ENV=development
```

### Frontend (Flutter)

```bash
flutter pub get
```

The backend URL is pre-configured to `https://money-mate-ub8a.vercel.app/api`. To point to a local backend, update the `baseUrl` constant in the service files.

## Running the App

**Terminal 1 — Backend:**

```bash
cd backend
npm run dev
```

Backend runs at: `http://localhost:3000`

**Terminal 2 — Flutter:**

```bash
flutter run
```

## API Overview

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/expenses` | List expenses (filterable by date, category) |
| POST | `/api/expenses` | Create an expense |
| PUT | `/api/expenses/:id` | Update an expense |
| DELETE | `/api/expenses/:id` | Delete an expense |
| GET | `/api/bills` | List all bills |
| POST | `/api/bills` | Create a bill |
| PATCH | `/api/bills/:id/pay` | Mark a bill as paid |
| DELETE | `/api/bills/:id` | Delete a bill |
| GET | `/api/categories` | List categories |
| POST | `/api/categories` | Create a category |
| GET | `/api/ai/insights` | Get AI spending insights |

## Notes

- Bills use a **day-of-month** integer for `dueDate` (1–31) and a separate `nextDueDate` ISO string for the next actual occurrence
- Recurring bills (`monthly` / `yearly`) automatically calculate the next due date when marked as paid
- Budget alerts fire automatically when spending reaches 80% of the limit
- All dates are accepted in `MM-DD-YYYY` format from the frontend and stored as `YYYY-MM-DD` in the database
- Business logic lives entirely in the service layer — repositories only perform CRUD operations
