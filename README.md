# Paytm UPI Transaction Analysis

This was my first proper SQL project. I wanted to work on something that felt
real rather than a generic sales dataset, and UPI transactions made sense
because I use Paytm almost every day. Figured if I am going to practice SQL
I might as well do it on data I actually understand.

---

## What I Built

A SQL analysis on 5,000 simulated UPI transactions covering fraud detection,
monthly active user tracking, merchant performance, and platform KPIs.

I generated the dataset myself using Python to make it feel realistic.
The transactions include P2P transfers, merchant payments, bill payments,
recharges, and wallet loads across 300 users and 80 merchants.

---

## What I Was Trying To Answer

These are the actual questions I wrote down before starting the SQL:

- Which transaction types get flagged as fraud most often
- Do late night transactions have higher fraud rates
- Which users are sending an unusually high number of transactions in a day
- How many users are active each month and is that number growing
- Are there more new users or returning users month over month
- Which merchants are in the top revenue quartile
- What does the cumulative GMV look like over time
- Which bank has the best success rate

I did not know all the SQL needed to answer these when I started.
The MAU with month-over-month growth was the hardest one to figure out.
LAG() makes sense once you see it working but writing it for the first
time took me a while.

---

## Dataset

Three tables. Kept it simple for the first project.

| Table | Rows | What it contains |
|-------|------|-----------------|
| transactions | 5,000 | UPI transactions Jan 2023 to Dec 2024 |
| users | 300 | Demographics, bank, KYC status |
| merchants | 80 | Category, city, tier |

The transactions table has a fraud flag column. I built the fraud logic
into the data generator so that high-value late-night transactions have
a higher chance of being flagged. This made the fraud analysis queries
more interesting to write.

---

## Folder Structure

```
paytm-upi-analysis/
|
|-- data/
|   |-- users.csv
|   |-- merchants.csv
|   |-- transactions.csv
|
|-- queries/
|   |-- paytm_analysis.sql
|
|-- generate_data.py
|-- run_queries.py
|-- README.md
```

---

## SQL Concepts I Used

I used this project specifically to practice window functions because
every SQL interview I read about mentions them and I had never used
them in a real context before.

CTEs to break complex queries into readable steps, LAG() for
month-over-month comparisons, NTILE(4) to segment merchants into
quartiles, PERCENT_RANK() to find where each user sits in the
spending distribution, SUM() OVER with ORDER BY for the running
GMV total, DATE_TRUNC for monthly aggregations, and COUNT DISTINCT
for unique user counts.

The fraud detection queries use z-score logic to find transactions
that are statistically far from a user's normal spending pattern.
That was new to me and took a few tries to get right.

---

## What I Found

Fraud rate is highest for P2M transactions at around 11%. That surprised
me. I expected P2P transfers to be riskier but merchant payments have
more surface area for fraud apparently.

Transactions between 2 AM and 3 AM have a fraud rate above 8% compared
to the daytime average of around 3%. The fraud flag logic I built into
the dataset reflects this and the SQL confirms it cleanly.

Insurance merchants dominate GMV because of high ticket sizes even though
they have fewer transactions. This is something I would not have noticed
without the NTILE quartile query.

Overall success rate came out at 86.44% and the fraud rate at 4.74%
which sits within the industry benchmark of 2 to 5 percent.

---

## How To Run

No database setup needed. DuckDB queries the CSV files directly.

```bash
pip3 install duckdb pandas
python3 generate_data.py
python3 run_queries.py
```

---

## What I Would Do Differently

The dataset is too clean. Real UPI transaction data would have failed
transactions with error codes, duplicate transaction IDs from retries,
and amounts that do not match across systems. I would add that
messiness next time to make the cleaning queries more realistic.

I also want to add a proper cohort analysis showing retention of users
who joined in each month. The new vs returning query I wrote is a
simplified version of that.

---

## What I Learned

Window functions clicked for me while writing the MAU growth query.
Once I understood that LAG() just looks at the previous row in a
partition it became obvious. Before that I was trying to do it with
subqueries which was getting messy.

NTILE was also new. The idea that you can divide any result set into
N equal buckets with one function is genuinely useful and I have
used it in every project since.

---

Mehak Pandey
pandeymehak.217@gmail.com
