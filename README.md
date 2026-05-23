# 💳 Paytm UPI Transaction Analysis
### SQL Portfolio Project | Data Analyst | 2024

[![SQL](https://img.shields.io/badge/SQL-PostgreSQL%20%7C%20MySQL%20%7C%20DuckDB-blue)]()
[![Dataset](https://img.shields.io/badge/Dataset-5%2C000%20Transactions-green)]()
[![Status](https://img.shields.io/badge/Status-Complete-brightgreen)]()

---

## 📌 Project Overview

**Business Context:**  
India's UPI ecosystem processes over 10 billion transactions monthly. Paytm, one of India's largest fintech platforms, needs robust analytics to detect fraud, track user engagement, and maximise merchant revenue. This project simulates that real-world analytics environment.

**Goal:** Build a complete SQL analytics solution covering fraud detection, user engagement, merchant performance, and executive KPIs — skills that get data analysts hired at fintech companies.

---

## 🎯 Key Business Questions Answered

| # | Question | SQL Concept Used |
|---|----------|-----------------|
| 1 | Which transaction types have the highest fraud rate? | GROUP BY, CASE |
| 2 | Are high-value late-night transactions fraud signals? | EXTRACT(HOUR), Window Fn |
| 3 | Which users show suspicious transaction velocity? | CTEs, daily aggregation |
| 4 | How many Monthly Active Users (MAU) does Paytm have? | DATE_TRUNC, COUNT DISTINCT |
| 5 | What is the Month-over-Month MAU growth? | LAG() Window Function |
| 6 | Who are new vs returning users each month? | CTEs, CASE, JOIN |
| 7 | Which merchants belong to top revenue quartile? | NTILE(4), RANK() |
| 8 | What is the cumulative GMV (running total)? | SUM() OVER (ORDER BY) |
| 9 | What is each user's spending percentile? | PERCENT_RANK() |
| 10 | Which bank has the best transaction success rate? | Conditional aggregation |

---

## 🗂️ Project Structure

```
paytm-upi-analysis/
│
├── data/
│   ├── users.csv           # 300 users with demographics
│   ├── merchants.csv       # 80 merchants across 10 categories
│   └── transactions.csv    # 5,000 UPI transactions (Jan 2023 – Dec 2024)
│
├── queries/
│   └── paytm_analysis.sql  # All SQL queries with comments
│
├── generate_data.py        # Python script to regenerate dataset
├── run_queries.py          # Run all queries via DuckDB (no DB setup needed)
└── README.md
```

---

## 📊 Dataset Schema

### `transactions` table
| Column | Type | Description |
|--------|------|-------------|
| txn_id | VARCHAR | Unique transaction ID |
| txn_date | DATE | Transaction date |
| txn_datetime | TIMESTAMP | Full datetime |
| txn_type | VARCHAR | P2P / P2M / Bill Payment / Recharge / Wallet Load |
| sender_id | VARCHAR | FK → users |
| receiver_id | VARCHAR | FK → users (P2P only) |
| merchant_id | VARCHAR | FK → merchants (P2M only) |
| merchant_category | VARCHAR | Food, Grocery, Travel, etc. |
| amount | DECIMAL | Transaction amount in INR |
| payment_mode | VARCHAR | UPI / Wallet / UPI Lite |
| bank_name | VARCHAR | Sender's linked bank |
| status | VARCHAR | Success / Failed / Pending |
| is_fraud_flag | INT | 1 = flagged, 0 = clean |
| device_type | VARCHAR | Android / iOS / Web |

### `users` table — 300 rows
`user_id`, `user_name`, `age`, `gender`, `city`, `state`, `linked_bank`, `registration_date`, `kyc_status`

### `merchants` table — 80 rows
`merchant_id`, `merchant_name`, `category`, `city`, `state`, `merchant_tier`

---

## 🔑 Key Findings

### Fraud Analysis
- **P2M transactions** have the highest fraud rate at **10.98%** — merchant payments need stricter monitoring
- Fraud spikes at **2–3 AM** (8%+ fraud rate) vs daytime average of ~3%
- P2P transfers flag as fraudulent mainly on **high-value night transactions**

### User Engagement
- Platform averages **~135 MAU** consistently across 24 months
- **MoM growth** is volatile (−15% to +20%) — retention strategy needed
- Oct 2023 & Oct 2024 are peak months (~149–150 MAU) — festive season effect

### Merchant Revenue
- **Insurance category dominates** GMV due to high ticket sizes (₹10K–₹50K)
- **Top 25% merchants** (NTILE 1) contribute disproportionately to total revenue
- **IRCTC, Uber, RedBus** are top travel merchants

### Platform KPIs
- **Total GMV:** ₹2.05 Crores across 5,000 transactions
- **Overall success rate:** 86.44%
- **Fraud rate:** 4.74% (industry benchmark: 2–5%)
- **Avg transaction value:** ₹4,112

---

## 🚀 How to Run This Project

### Option 1: DuckDB (Recommended — Zero Setup)
```bash
# Install Python dependencies
pip install duckdb pandas

# Generate the dataset
python generate_data.py

# Run all queries
python run_queries.py
```

### Option 2: PostgreSQL
```bash
# 1. Create database
createdb paytm_analysis

# 2. Connect and create tables
psql paytm_analysis -f queries/paytm_analysis.sql

# 3. Load CSV data
\copy users FROM 'data/users.csv' CSV HEADER;
\copy merchants FROM 'data/merchants.csv' CSV HEADER;
\copy transactions FROM 'data/transactions.csv' CSV HEADER;
```

### Option 3: MySQL
```sql
-- Load data using LOAD DATA INFILE or MySQL Workbench import wizard
-- Then run queries from paytm_analysis.sql
```

---

## 💼 SQL Concepts Demonstrated

```
✅ CTEs (WITH clause)              ✅ Window Functions
✅ LAG() / LEAD()                  ✅ RANK() / DENSE_RANK()
✅ NTILE() — quartile segmentation ✅ PERCENT_RANK()
✅ SUM() OVER (ORDER BY) — running totals
✅ DATE_TRUNC / EXTRACT            ✅ COUNT DISTINCT
✅ CASE WHEN logic                 ✅ Multi-table JOINs
✅ Conditional aggregation         ✅ Subqueries
✅ NULLIF / ISNULL error handling  ✅ Statistical outlier detection
```

---

## 📝 Resume Bullet Points (Copy-Paste Ready)

> - Designed and executed **SQL analysis on 5,000+ Paytm UPI transactions** (Jan 2023–Dec 2024) covering fraud detection, MAU tracking, and merchant performance
> - Built **fraud detection queries** using statistical z-score analysis and transaction velocity monitoring with CTEs and Window Functions, flagging 237 suspicious transactions (4.74% fraud rate)
> - Tracked **Monthly Active Users (MAU)** using DATE_TRUNC and COUNT DISTINCT; computed MoM growth with LAG() to surface a 20.49% peak in March 2023
> - Segmented **80 merchants into revenue quartiles** using NTILE(4) and RANK(), revealing Insurance category contributes 35%+ of total GMV
> - Calculated **running cumulative GMV** and 7-day rolling averages using SUM() OVER (ORDER BY date) for executive dashboard reporting
> - Tiered **300 users by spending percentile** using PERCENT_RANK() to identify Platinum/Gold segments for targeted marketing campaigns

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|------|---------|
| **SQL (PostgreSQL syntax)** | All analysis queries |
| **DuckDB** | Local SQL engine — run without any DB server |
| **Python + Pandas** | Dataset generation |
| **GitHub** | Version control & portfolio hosting |

---

## 👤 About

**[Your Name]** — Fresher Data Analyst  
📧 your.email@gmail.com  
🔗 LinkedIn: linkedin.com/in/yourprofile  
💻 GitHub: github.com/yourusername

*This project is part of a Data Analyst portfolio. Dataset is synthetically generated to simulate real Paytm UPI transaction patterns.*

---
⭐ *If this project helped you, please star the repo!*
