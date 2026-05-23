-- ============================================================
--  PAYTM UPI TRANSACTION ANALYSIS
--  SQL Project for Data Analyst Portfolio
--  Author  : [Your Name]
--  Tools   : PostgreSQL / MySQL / DuckDB
--  Dataset : 5,000 UPI transactions | 300 users | 80 merchants
--  Period  : Jan 2023 – Dec 2024
-- ============================================================

-- ─────────────────────────────────────────────────────────────
--  SECTION 0: SCHEMA SETUP
--  Run this first to create tables and load data
-- ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS users (
    user_id           VARCHAR(10) PRIMARY KEY,
    user_name         VARCHAR(100),
    age               INT,
    gender            CHAR(1),
    city              VARCHAR(50),
    state             VARCHAR(50),
    linked_bank       VARCHAR(50),
    registration_date DATE,
    kyc_status        VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS merchants (
    merchant_id     VARCHAR(10) PRIMARY KEY,
    merchant_name   VARCHAR(100),
    category        VARCHAR(50),
    city            VARCHAR(50),
    state           VARCHAR(50),
    merchant_tier   VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS transactions (
    txn_id             VARCHAR(15) PRIMARY KEY,
    txn_date           DATE,
    txn_time           TIME,
    txn_datetime       TIMESTAMP,
    txn_type           VARCHAR(20),
    sender_id          VARCHAR(10),
    receiver_id        VARCHAR(10),
    merchant_id        VARCHAR(10),
    merchant_category  VARCHAR(50),
    amount             DECIMAL(12,2),
    payment_mode       VARCHAR(20),
    bank_name          VARCHAR(50),
    status             VARCHAR(20),
    is_fraud_flag      INT,          -- 1 = flagged as fraud, 0 = clean
    device_type        VARCHAR(20)
);

-- ─────────────────────────────────────────────────────────────
--  SECTION 1: FRAUD DETECTION
--  Business Goal: Detect anomalous / fraudulent transactions
--  Skills : CASE, Window Functions, Anomaly Flags, CTEs
-- ─────────────────────────────────────────────────────────────

-- Q1.1  Overall fraud rate by transaction type
-- Shows which transaction types carry highest fraud risk
SELECT
    txn_type,
    COUNT(*)                                           AS total_txns,
    SUM(is_fraud_flag)                                 AS fraud_txns,
    ROUND(SUM(is_fraud_flag) * 100.0 / COUNT(*), 2)   AS fraud_rate_pct,
    ROUND(SUM(CASE WHEN is_fraud_flag = 1 THEN amount ELSE 0 END), 2) AS fraud_amount
FROM transactions
GROUP BY txn_type
ORDER BY fraud_rate_pct DESC;


-- Q1.2  High-risk transactions: amount > 2 std deviations above mean
-- Uses window function to detect statistical outliers per category
WITH stats AS (
    SELECT
        merchant_category,
        AVG(amount)    AS avg_amount,
        STDDEV(amount) AS std_amount
    FROM transactions
    WHERE status = 'Success'
    GROUP BY merchant_category
),
flagged AS (
    SELECT
        t.txn_id,
        t.txn_datetime,
        t.sender_id,
        t.merchant_category,
        t.amount,
        s.avg_amount,
        s.std_amount,
        ROUND((t.amount - s.avg_amount) / NULLIF(s.std_amount, 0), 2) AS z_score,
        t.is_fraud_flag
    FROM transactions t
    JOIN stats s ON t.merchant_category = s.merchant_category
    WHERE t.status = 'Success'
)
SELECT *
FROM flagged
WHERE z_score > 2
ORDER BY z_score DESC
LIMIT 20;


-- Q1.3  Fraud transactions in late-night hours (1 AM – 5 AM)
-- Night-time high-value transactions are a classic fraud signal
SELECT
    EXTRACT(HOUR FROM txn_datetime)    AS txn_hour,
    COUNT(*)                           AS total_txns,
    SUM(is_fraud_flag)                 AS fraud_count,
    ROUND(AVG(amount), 2)              AS avg_amount,
    ROUND(SUM(is_fraud_flag) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM transactions
GROUP BY EXTRACT(HOUR FROM txn_datetime)
ORDER BY txn_hour;


-- Q1.4  Users with suspiciously high transaction velocity
-- More than 10 transactions in a single day = anomaly flag
WITH daily_txns AS (
    SELECT
        sender_id,
        txn_date,
        COUNT(*)       AS txn_count,
        SUM(amount)    AS daily_spend
    FROM transactions
    WHERE status = 'Success'
    GROUP BY sender_id, txn_date
)
SELECT
    d.sender_id,
    u.user_name,
    u.city,
    d.txn_date,
    d.txn_count,
    ROUND(d.daily_spend, 2) AS daily_spend,
    CASE WHEN d.txn_count > 10 THEN 'HIGH VELOCITY - REVIEW'
         WHEN d.txn_count > 6  THEN 'MODERATE'
         ELSE 'NORMAL'
    END AS risk_label
FROM daily_txns d
JOIN users u ON d.sender_id = u.user_id
WHERE d.txn_count > 6
ORDER BY d.txn_count DESC, d.daily_spend DESC;


-- ─────────────────────────────────────────────────────────────
--  SECTION 2: MONTHLY ACTIVE USERS (MAU)
--  Business Goal: Track user engagement over time
--  Skills : DATE_TRUNC, COUNT DISTINCT, Window Functions
-- ─────────────────────────────────────────────────────────────

-- Q2.1  Monthly Active Users (MAU) — users who made ≥1 transaction
SELECT
    DATE_TRUNC('month', txn_date)      AS month,
    COUNT(DISTINCT sender_id)          AS mau,
    COUNT(*)                           AS total_transactions,
    ROUND(SUM(amount), 2)              AS total_volume,
    ROUND(AVG(amount), 2)              AS avg_txn_value
FROM transactions
WHERE status = 'Success'
GROUP BY DATE_TRUNC('month', txn_date)
ORDER BY month;


-- Q2.2  MAU with Month-over-Month Growth Rate
-- Uses LAG() to compare current vs previous month
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', txn_date) AS month,
        COUNT(DISTINCT sender_id)     AS mau,
        ROUND(SUM(amount), 2)         AS total_volume
    FROM transactions
    WHERE status = 'Success'
    GROUP BY DATE_TRUNC('month', txn_date)
)
SELECT
    month,
    mau,
    LAG(mau) OVER (ORDER BY month)     AS prev_month_mau,
    ROUND(
        (mau - LAG(mau) OVER (ORDER BY month)) * 100.0
        / NULLIF(LAG(mau) OVER (ORDER BY month), 0),
    2)                                  AS mau_growth_pct,
    total_volume,
    ROUND(
        (total_volume - LAG(total_volume) OVER (ORDER BY month)) * 100.0
        / NULLIF(LAG(total_volume) OVER (ORDER BY month), 0),
    2)                                  AS volume_growth_pct
FROM monthly
ORDER BY month;


-- Q2.3  New vs Returning users per month
-- Identifies if growth is coming from new acquisition or retention
WITH first_txn AS (
    SELECT
        sender_id,
        MIN(txn_date) AS first_txn_date
    FROM transactions
    WHERE status = 'Success'
    GROUP BY sender_id
),
monthly_users AS (
    SELECT
        DATE_TRUNC('month', t.txn_date) AS month,
        t.sender_id,
        CASE WHEN DATE_TRUNC('month', f.first_txn_date) = DATE_TRUNC('month', t.txn_date)
             THEN 'New' ELSE 'Returning'
        END AS user_type
    FROM transactions t
    JOIN first_txn f ON t.sender_id = f.sender_id
    WHERE t.status = 'Success'
    GROUP BY DATE_TRUNC('month', t.txn_date), t.sender_id,
             DATE_TRUNC('month', f.first_txn_date)
)
SELECT
    month,
    COUNT(DISTINCT CASE WHEN user_type = 'New'       THEN sender_id END) AS new_users,
    COUNT(DISTINCT CASE WHEN user_type = 'Returning' THEN sender_id END) AS returning_users,
    COUNT(DISTINCT sender_id)                                             AS total_mau
FROM monthly_users
GROUP BY month
ORDER BY month;


-- ─────────────────────────────────────────────────────────────
--  SECTION 3: HIGH-VALUE MERCHANT REPORT USING NTILE()
--  Business Goal: Tier merchants by revenue contribution
--  Skills : NTILE(), RANK(), SUM, Aggregation
-- ─────────────────────────────────────────────────────────────

-- Q3.1  Merchant performance ranking with NTILE quartiles
WITH merchant_stats AS (
    SELECT
        t.merchant_id,
        m.merchant_name,
        m.category,
        m.merchant_tier,
        COUNT(*)                             AS total_txns,
        COUNT(DISTINCT t.sender_id)          AS unique_customers,
        ROUND(SUM(t.amount), 2)              AS total_revenue,
        ROUND(AVG(t.amount), 2)              AS avg_txn_value,
        ROUND(MAX(t.amount), 2)              AS max_txn_value
    FROM transactions t
    JOIN merchants m ON t.merchant_id = m.merchant_id
    WHERE t.status = 'Success'
      AND t.merchant_id IS NOT NULL
    GROUP BY t.merchant_id, m.merchant_name, m.category, m.merchant_tier
)
SELECT
    merchant_name,
    category,
    merchant_tier,
    total_txns,
    unique_customers,
    total_revenue,
    avg_txn_value,
    RANK()  OVER (ORDER BY total_revenue DESC)          AS revenue_rank,
    NTILE(4) OVER (ORDER BY total_revenue DESC)         AS revenue_quartile,
    -- Quartile label
    CASE NTILE(4) OVER (ORDER BY total_revenue DESC)
        WHEN 1 THEN '🥇 Top 25% — Premium'
        WHEN 2 THEN '🥈 Upper Mid'
        WHEN 3 THEN '🥉 Lower Mid'
        WHEN 4 THEN '📉 Bottom 25%'
    END AS merchant_segment,
    ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 2) AS revenue_share_pct
FROM merchant_stats
ORDER BY total_revenue DESC;


-- Q3.2  Top 5 merchants per category
-- Uses RANK() with PARTITION — a favourite interview question!
WITH ranked AS (
    SELECT
        m.category,
        m.merchant_name,
        ROUND(SUM(t.amount), 2)              AS total_revenue,
        COUNT(*)                             AS txn_count,
        RANK() OVER (
            PARTITION BY m.category
            ORDER BY SUM(t.amount) DESC
        ) AS category_rank
    FROM transactions t
    JOIN merchants m ON t.merchant_id = m.merchant_id
    WHERE t.status = 'Success'
      AND t.merchant_id IS NOT NULL
    GROUP BY m.category, m.merchant_name
)
SELECT *
FROM ranked
WHERE category_rank <= 5
ORDER BY category, category_rank;


-- Q3.3  Category-wise contribution to total GMV
SELECT
    merchant_category,
    COUNT(*)                                               AS txn_count,
    ROUND(SUM(amount), 2)                                  AS category_gmv,
    ROUND(SUM(amount) * 100.0 / SUM(SUM(amount)) OVER (), 2) AS gmv_share_pct,
    ROUND(AVG(amount), 2)                                  AS avg_ticket_size
FROM transactions
WHERE status = 'Success'
  AND merchant_id IS NOT NULL
GROUP BY merchant_category
ORDER BY category_gmv DESC;


-- ─────────────────────────────────────────────────────────────
--  SECTION 4: RUNNING TRANSACTION TOTAL
--  Business Goal: Track cumulative GMV (Gross Merchandise Value)
--  Skills : SUM() OVER (ORDER BY date), Running totals
-- ─────────────────────────────────────────────────────────────

-- Q4.1  Daily running total of transaction volume
SELECT
    txn_date,
    COUNT(*)                                              AS daily_txns,
    ROUND(SUM(amount), 2)                                 AS daily_volume,
    ROUND(SUM(SUM(amount)) OVER (ORDER BY txn_date), 2)   AS running_total_gmv,
    ROUND(AVG(amount), 2)                                 AS avg_txn_value
FROM transactions
WHERE status = 'Success'
GROUP BY txn_date
ORDER BY txn_date;


-- Q4.2  Running total by user — lifetime spend tracker
-- Useful to identify high-CLV (Customer Lifetime Value) users
SELECT
    sender_id,
    txn_date,
    txn_id,
    amount,
    ROUND(SUM(amount) OVER (
        PARTITION BY sender_id
        ORDER BY txn_date, txn_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS running_user_spend,
    ROW_NUMBER() OVER (
        PARTITION BY sender_id ORDER BY txn_date, txn_id
    ) AS user_txn_number
FROM transactions
WHERE status = 'Success'
ORDER BY sender_id, txn_date, txn_id
LIMIT 50;  -- Remove LIMIT for full result


-- Q4.3  7-day rolling average transaction volume (trend smoothing)
WITH daily AS (
    SELECT
        txn_date,
        SUM(amount)  AS daily_volume,
        COUNT(*)     AS daily_count
    FROM transactions
    WHERE status = 'Success'
    GROUP BY txn_date
)
SELECT
    txn_date,
    daily_volume,
    daily_count,
    ROUND(AVG(daily_volume) OVER (
        ORDER BY txn_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_7d_avg_volume,
    ROUND(AVG(daily_count) OVER (
        ORDER BY txn_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 1) AS rolling_7d_avg_count
FROM daily
ORDER BY txn_date;


-- ─────────────────────────────────────────────────────────────
--  SECTION 5: USER SEGMENTATION & BEHAVIOUR
--  Business Goal: Understand user spending patterns
--  Skills : PERCENT_RANK(), CASE, CTEs, GROUP BY
-- ─────────────────────────────────────────────────────────────

-- Q5.1  User spending percentile using PERCENT_RANK()
-- Identify top spenders for premium product targeting
WITH user_spend AS (
    SELECT
        t.sender_id,
        u.user_name,
        u.city,
        u.state,
        u.age,
        COUNT(*)             AS total_txns,
        ROUND(SUM(t.amount), 2) AS total_spend
    FROM transactions t
    JOIN users u ON t.sender_id = u.user_id
    WHERE t.status = 'Success'
    GROUP BY t.sender_id, u.user_name, u.city, u.state, u.age
)
SELECT
    sender_id,
    user_name,
    city,
    state,
    age,
    total_txns,
    total_spend,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_spend) * 100, 2) AS spend_percentile,
    CASE
        WHEN PERCENT_RANK() OVER (ORDER BY total_spend) >= 0.90 THEN '💎 Platinum'
        WHEN PERCENT_RANK() OVER (ORDER BY total_spend) >= 0.70 THEN '🥇 Gold'
        WHEN PERCENT_RANK() OVER (ORDER BY total_spend) >= 0.40 THEN '🥈 Silver'
        ELSE                                                          '🥉 Bronze'
    END AS user_tier
FROM user_spend
ORDER BY total_spend DESC;


-- Q5.2  State-wise transaction analysis
SELECT
    u.state,
    COUNT(DISTINCT t.sender_id)    AS active_users,
    COUNT(*)                       AS total_txns,
    ROUND(SUM(t.amount), 2)        AS total_volume,
    ROUND(AVG(t.amount), 2)        AS avg_txn_value,
    ROUND(SUM(t.amount) / COUNT(DISTINCT t.sender_id), 2) AS avg_spend_per_user
FROM transactions t
JOIN users u ON t.sender_id = u.user_id
WHERE t.status = 'Success'
GROUP BY u.state
ORDER BY total_volume DESC;


-- Q5.3  Device preference & payment mode split
SELECT
    device_type,
    payment_mode,
    COUNT(*)                                               AS txn_count,
    ROUND(SUM(amount), 2)                                  AS total_volume,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)    AS txn_share_pct
FROM transactions
WHERE status = 'Success'
GROUP BY device_type, payment_mode
ORDER BY txn_count DESC;


-- Q5.4  Bank performance — success rate & avg transaction
SELECT
    bank_name,
    COUNT(*)                                              AS total_attempts,
    SUM(CASE WHEN status = 'Success' THEN 1 ELSE 0 END)  AS successful,
    SUM(CASE WHEN status = 'Failed'  THEN 1 ELSE 0 END)  AS failed,
    ROUND(SUM(CASE WHEN status = 'Success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
                                                          AS success_rate_pct,
    ROUND(AVG(CASE WHEN status = 'Success' THEN amount END), 2) AS avg_success_amount
FROM transactions
GROUP BY bank_name
ORDER BY total_attempts DESC;


-- ─────────────────────────────────────────────────────────────
--  SECTION 6: BUSINESS KPI DASHBOARD QUERIES
--  These are the 5 key numbers any analyst would report
-- ─────────────────────────────────────────────────────────────

-- Q6.1  Executive Summary KPIs (single result row)
SELECT
    COUNT(*)                                               AS total_transactions,
    COUNT(DISTINCT sender_id)                              AS total_users,
    ROUND(SUM(amount), 2)                                  AS total_gmv,
    ROUND(AVG(amount), 2)                                  AS avg_transaction_value,
    ROUND(SUM(CASE WHEN status = 'Success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
                                                           AS overall_success_rate,
    SUM(is_fraud_flag)                                     AS flagged_fraud_txns,
    ROUND(SUM(is_fraud_flag) * 100.0 / COUNT(*), 2)        AS fraud_rate_pct
FROM transactions;


-- Q6.2  Year-over-Year comparison (2023 vs 2024)
SELECT
    EXTRACT(YEAR FROM txn_date) AS year,
    COUNT(*)                    AS total_txns,
    COUNT(DISTINCT sender_id)   AS unique_users,
    ROUND(SUM(amount), 2)       AS total_gmv,
    ROUND(AVG(amount), 2)       AS avg_txn_value,
    SUM(is_fraud_flag)          AS fraud_count
FROM transactions
WHERE status = 'Success'
GROUP BY EXTRACT(YEAR FROM txn_date)
ORDER BY year;


-- Q6.3  Peak hours analysis (best time to send push notifications)
SELECT
    EXTRACT(HOUR FROM txn_datetime)    AS hour_of_day,
    COUNT(*)                           AS txn_count,
    ROUND(SUM(amount), 2)              AS volume,
    ROUND(AVG(amount), 2)              AS avg_amount,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS popularity_rank
FROM transactions
WHERE status = 'Success'
GROUP BY EXTRACT(HOUR FROM txn_datetime)
ORDER BY hour_of_day;
