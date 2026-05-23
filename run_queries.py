"""
Run all project SQL queries using DuckDB and export results.
DuckDB can query CSV files directly — perfect for portfolio demos.
"""
import duckdb
import pandas as pd

con = duckdb.connect()

# Load CSVs as tables
con.execute("CREATE TABLE users        AS SELECT * FROM read_csv_auto('/Users/mehekpandey/paytm_project/data/users.csv')")
con.execute("CREATE TABLE merchants    AS SELECT * FROM read_csv_auto('/Users/mehekpandey/paytm_project/data/merchants.csv')")
con.execute("CREATE TABLE transactions AS SELECT * FROM read_csv_auto('/Users/mehekpandey/paytm_project/data/transactions.csv')")

print("=" * 60)
print("PAYTM UPI TRANSACTION ANALYSIS — QUERY RESULTS")
print("=" * 60)

queries = {

    "Q1.1 Fraud Rate by Transaction Type": """
        SELECT txn_type,
               COUNT(*) AS total_txns,
               SUM(is_fraud_flag) AS fraud_txns,
               ROUND(SUM(is_fraud_flag)*100.0/COUNT(*),2) AS fraud_rate_pct,
               ROUND(SUM(CASE WHEN is_fraud_flag=1 THEN amount ELSE 0 END),2) AS fraud_amount
        FROM transactions
        GROUP BY txn_type
        ORDER BY fraud_rate_pct DESC
    """,

    "Q1.3 Fraud by Hour of Day": """
        SELECT EXTRACT(HOUR FROM CAST(txn_datetime AS TIMESTAMP)) AS txn_hour,
               COUNT(*) AS total_txns,
               SUM(is_fraud_flag) AS fraud_count,
               ROUND(AVG(amount),2) AS avg_amount,
               ROUND(SUM(is_fraud_flag)*100.0/COUNT(*),2) AS fraud_rate_pct
        FROM transactions
        GROUP BY EXTRACT(HOUR FROM CAST(txn_datetime AS TIMESTAMP))
        ORDER BY txn_hour
    """,

    "Q2.1 Monthly Active Users (MAU)": """
        SELECT DATE_TRUNC('month', CAST(txn_date AS DATE)) AS month,
               COUNT(DISTINCT sender_id) AS mau,
               COUNT(*) AS total_transactions,
               ROUND(SUM(amount),2) AS total_volume,
               ROUND(AVG(amount),2) AS avg_txn_value
        FROM transactions
        WHERE status='Success'
        GROUP BY DATE_TRUNC('month', CAST(txn_date AS DATE))
        ORDER BY month
    """,

    "Q2.2 MAU with MoM Growth": """
        WITH monthly AS (
            SELECT DATE_TRUNC('month', CAST(txn_date AS DATE)) AS month,
                   COUNT(DISTINCT sender_id) AS mau,
                   ROUND(SUM(amount),2) AS total_volume
            FROM transactions WHERE status='Success'
            GROUP BY DATE_TRUNC('month', CAST(txn_date AS DATE))
        )
        SELECT month, mau,
               LAG(mau) OVER (ORDER BY month) AS prev_mau,
               ROUND((mau - LAG(mau) OVER (ORDER BY month))*100.0
                     / NULLIF(LAG(mau) OVER (ORDER BY month),0), 2) AS mau_growth_pct,
               total_volume
        FROM monthly ORDER BY month
    """,

    "Q3.1 Merchant NTILE Segments": """
        WITH ms AS (
            SELECT t.merchant_id, m.merchant_name, m.category, m.merchant_tier,
                   COUNT(*) AS total_txns,
                   COUNT(DISTINCT t.sender_id) AS unique_customers,
                   ROUND(SUM(t.amount),2) AS total_revenue,
                   ROUND(AVG(t.amount),2) AS avg_txn_value
            FROM transactions t
            JOIN merchants m ON t.merchant_id = m.merchant_id
            WHERE t.status='Success' AND t.merchant_id IS NOT NULL
            GROUP BY t.merchant_id, m.merchant_name, m.category, m.merchant_tier
        )
        SELECT merchant_name, category, merchant_tier,
               total_txns, unique_customers, total_revenue, avg_txn_value,
               RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
               NTILE(4) OVER (ORDER BY total_revenue DESC) AS revenue_quartile,
               CASE NTILE(4) OVER (ORDER BY total_revenue DESC)
                   WHEN 1 THEN 'Top 25% - Premium'
                   WHEN 2 THEN 'Upper Mid'
                   WHEN 3 THEN 'Lower Mid'
                   WHEN 4 THEN 'Bottom 25%'
               END AS merchant_segment
        FROM ms ORDER BY total_revenue DESC LIMIT 15
    """,

    "Q4.1 Daily Running Total GMV": """
        SELECT txn_date,
               COUNT(*) AS daily_txns,
               ROUND(SUM(amount),2) AS daily_volume,
               ROUND(SUM(SUM(amount)) OVER (ORDER BY txn_date),2) AS running_total_gmv
        FROM transactions
        WHERE status='Success'
        GROUP BY txn_date ORDER BY txn_date
        LIMIT 30
    """,

    "Q5.1 User Tier Segmentation": """
        WITH user_spend AS (
            SELECT t.sender_id, u.user_name, u.city, u.state,
                   COUNT(*) AS total_txns,
                   ROUND(SUM(t.amount),2) AS total_spend
            FROM transactions t
            JOIN users u ON t.sender_id = u.user_id
            WHERE t.status='Success'
            GROUP BY t.sender_id, u.user_name, u.city, u.state
        )
        SELECT sender_id, user_name, city, state, total_txns, total_spend,
               ROUND(PERCENT_RANK() OVER (ORDER BY total_spend)*100, 2) AS spend_percentile,
               CASE WHEN PERCENT_RANK() OVER (ORDER BY total_spend) >= 0.90 THEN 'Platinum'
                    WHEN PERCENT_RANK() OVER (ORDER BY total_spend) >= 0.70 THEN 'Gold'
                    WHEN PERCENT_RANK() OVER (ORDER BY total_spend) >= 0.40 THEN 'Silver'
                    ELSE 'Bronze'
               END AS user_tier
        FROM user_spend ORDER BY total_spend DESC LIMIT 15
    """,

    "Q5.4 Bank Success Rate": """
        SELECT bank_name, COUNT(*) AS total_attempts,
               SUM(CASE WHEN status='Success' THEN 1 ELSE 0 END) AS successful,
               ROUND(SUM(CASE WHEN status='Success' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS success_rate_pct,
               ROUND(AVG(CASE WHEN status='Success' THEN amount END),2) AS avg_success_amount
        FROM transactions
        GROUP BY bank_name ORDER BY total_attempts DESC
    """,

    "Q6.1 Executive KPI Summary": """
        SELECT COUNT(*) AS total_transactions,
               COUNT(DISTINCT sender_id) AS total_users,
               ROUND(SUM(amount),2) AS total_gmv,
               ROUND(AVG(amount),2) AS avg_transaction_value,
               ROUND(SUM(CASE WHEN status='Success' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS success_rate_pct,
               SUM(is_fraud_flag) AS flagged_fraud_txns,
               ROUND(SUM(is_fraud_flag)*100.0/COUNT(*),2) AS fraud_rate_pct
        FROM transactions
    """,

    "Q6.2 Year-over-Year 2023 vs 2024": """
        SELECT EXTRACT(YEAR FROM CAST(txn_date AS DATE)) AS year,
               COUNT(*) AS total_txns,
               COUNT(DISTINCT sender_id) AS unique_users,
               ROUND(SUM(amount),2) AS total_gmv,
               ROUND(AVG(amount),2) AS avg_txn_value,
               SUM(is_fraud_flag) AS fraud_count
        FROM transactions WHERE status='Success'
        GROUP BY EXTRACT(YEAR FROM CAST(txn_date AS DATE))
        ORDER BY year
    """,
}

results_summary = []

for name, sql in queries.items():
    print(f"\n{'─'*60}")
    print(f"  {name}")
    print(f"{'─'*60}")
    df = con.execute(sql).df()
    print(df.to_string(index=False))
    results_summary.append({'query': name, 'rows': len(df), 'cols': len(df.columns)})

print(f"\n{'='*60}")
print("QUERIES EXECUTED SUCCESSFULLY")
print(f"{'='*60}")
for r in results_summary:
    print(f"  ✅  {r['query']:45s}  →  {r['rows']} rows × {r['cols']} cols")

con.close()
