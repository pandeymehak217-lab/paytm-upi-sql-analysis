"""
Generate a realistic Paytm UPI transaction dataset
~5000 rows — enough to look impressive, fast to query
"""
import pandas as pd
import random
from datetime import datetime, timedelta

random.seed(42)

# ── Config ──────────────────────────────────────────────
N_USERS        = 300
N_MERCHANTS    = 80
N_TRANSACTIONS = 5000
START_DATE     = datetime(2023, 1, 1)
END_DATE       = datetime(2024, 12, 31)

# ── Reference data ──────────────────────────────────────
STATES = [
    'Maharashtra', 'Karnataka', 'Delhi', 'Tamil Nadu', 'Telangana',
    'Gujarat', 'Rajasthan', 'West Bengal', 'Uttar Pradesh', 'Punjab',
    'Haryana', 'Kerala', 'Madhya Pradesh', 'Bihar', 'Odisha'
]
CITIES = {
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur'],
    'Karnataka':   ['Bengaluru', 'Mysuru', 'Mangaluru'],
    'Delhi':       ['New Delhi', 'Dwarka', 'Noida'],
    'Tamil Nadu':  ['Chennai', 'Coimbatore', 'Madurai'],
    'Telangana':   ['Hyderabad', 'Warangal', 'Nizamabad'],
    'Gujarat':     ['Ahmedabad', 'Surat', 'Vadodara'],
    'Rajasthan':   ['Jaipur', 'Jodhpur', 'Udaipur'],
    'West Bengal': ['Kolkata', 'Howrah', 'Durgapur'],
    'Uttar Pradesh':['Lucknow', 'Kanpur', 'Agra'],
    'Punjab':      ['Chandigarh', 'Ludhiana', 'Amritsar'],
    'Haryana':     ['Gurugram', 'Faridabad', 'Hisar'],
    'Kerala':      ['Kochi', 'Thiruvananthapuram', 'Kozhikode'],
    'Madhya Pradesh':['Bhopal', 'Indore', 'Gwalior'],
    'Bihar':       ['Patna', 'Gaya', 'Muzaffarpur'],
    'Odisha':      ['Bhubaneswar', 'Cuttack', 'Rourkela'],
}
MERCHANT_CATEGORIES = [
    'Food & Beverages', 'Grocery', 'Fuel', 'Recharge & Bills',
    'Shopping', 'Entertainment', 'Healthcare', 'Travel',
    'Education', 'Insurance'
]
MERCHANT_NAMES = {
    'Food & Beverages': ['Swiggy', 'Zomato', 'McDonald\'s', 'Domino\'s', 'Cafe Coffee Day', 'Haldiram\'s'],
    'Grocery':          ['BigBasket', 'Blinkit', 'DMart', 'Reliance Fresh', 'Spencer\'s'],
    'Fuel':             ['HPCL', 'BPCL', 'IndianOil', 'Reliance BP', 'Shell'],
    'Recharge & Bills': ['Airtel', 'Jio', 'BSNL', 'Tata Play', 'Adani Electricity'],
    'Shopping':         ['Flipkart', 'Amazon', 'Myntra', 'Ajio', 'Nykaa'],
    'Entertainment':    ['BookMyShow', 'Netflix', 'Hotstar', 'SonyLIV', 'PVR Cinemas'],
    'Healthcare':       ['Apollo Pharmacy', 'MedPlus', '1mg', 'PharmEasy', 'Manipal Hospitals'],
    'Travel':           ['IRCTC', 'MakeMyTrip', 'RedBus', 'Ola', 'Uber'],
    'Education':        ['BYJU\'S', 'Unacademy', 'Coursera India', 'Vedantu', 'upGrad'],
    'Insurance':        ['LIC', 'HDFC Life', 'SBI Life', 'PolicyBazaar', 'ICICI Prudential'],
}
TRANSACTION_TYPES = ['P2P', 'P2M', 'Bill Payment', 'Recharge', 'Wallet Load']
PAYMENT_MODES     = ['UPI', 'Wallet', 'UPI Lite']
BANKS             = ['SBI', 'HDFC', 'ICICI', 'Axis', 'Kotak', 'PNB', 'Bank of Baroda', 'Canara', 'Yes Bank', 'IDFC First']

# ── Generate users ──────────────────────────────────────
first_names = ['Amit','Priya','Rahul','Sneha','Vikram','Anjali','Rohit','Pooja',
               'Suresh','Kavya','Arjun','Meera','Deepak','Nisha','Kiran',
               'Sanjay','Divya','Rajesh','Sunita','Manoj','Aarav','Ishaan',
               'Ananya','Riya','Zara','Kartik','Aditya','Isha','Siddharth','Tanvi']
last_names  = ['Sharma','Patel','Singh','Gupta','Kumar','Verma','Joshi','Nair',
               'Reddy','Mehta','Shah','Iyer','Pillai','Rao','Malhotra',
               'Agarwal','Banerjee','Chatterjee','Mishra','Pandey']

users = []
for uid in range(1, N_USERS + 1):
    state = random.choice(STATES)
    city  = random.choice(CITIES[state])
    fname = random.choice(first_names)
    lname = random.choice(last_names)
    age   = random.randint(18, 55)
    users.append({
        'user_id':        f'U{uid:04d}',
        'user_name':      f'{fname} {lname}',
        'age':            age,
        'gender':         random.choice(['M', 'F']),
        'city':           city,
        'state':          state,
        'linked_bank':    random.choice(BANKS),
        'registration_date': (START_DATE - timedelta(days=random.randint(30, 730))).strftime('%Y-%m-%d'),
        'kyc_status':     random.choices(['Verified', 'Pending', 'Not Done'], weights=[75, 15, 10])[0],
    })
users_df = pd.DataFrame(users)

# ── Generate merchants ───────────────────────────────────
merchants = []
for mid in range(1, N_MERCHANTS + 1):
    cat   = random.choice(MERCHANT_CATEGORIES)
    state = random.choice(STATES)
    city  = random.choice(CITIES[state])
    merchants.append({
        'merchant_id':       f'M{mid:03d}',
        'merchant_name':     random.choice(MERCHANT_NAMES[cat]),
        'category':          cat,
        'city':              city,
        'state':             state,
        'merchant_tier':     random.choices(['Gold', 'Silver', 'Bronze'], weights=[20, 40, 40])[0],
    })
merchants_df = pd.DataFrame(merchants)

# ── Generate transactions ────────────────────────────────
def random_date(start, end):
    delta = end - start
    return start + timedelta(seconds=random.randint(0, int(delta.total_seconds())))

def transaction_amount(txn_type, category=''):
    if txn_type == 'P2P':
        return round(random.uniform(50, 10000), 2)
    if txn_type == 'Recharge':
        return round(random.choice([19, 49, 99, 149, 199, 299, 399, 599, 999]), 2)
    if txn_type == 'Bill Payment':
        return round(random.uniform(200, 5000), 2)
    if txn_type == 'Wallet Load':
        return round(random.choice([100, 200, 500, 1000, 2000, 5000]), 2)
    # P2M
    amounts = {
        'Food & Beverages': (80, 800),
        'Grocery':          (200, 3000),
        'Fuel':             (300, 3000),
        'Shopping':         (200, 8000),
        'Entertainment':    (100, 1500),
        'Healthcare':       (100, 5000),
        'Travel':           (200, 15000),
        'Education':        (500, 20000),
        'Insurance':        (500, 50000),
        'Recharge & Bills': (99, 999),
    }
    lo, hi = amounts.get(category, (50, 2000))
    return round(random.uniform(lo, hi), 2)

transactions = []
for tid in range(1, N_TRANSACTIONS + 1):
    txn_type   = random.choices(TRANSACTION_TYPES, weights=[25, 40, 15, 12, 8])[0]
    sender     = random.choice(users)
    receiver   = random.choice(users) if txn_type == 'P2P' else None
    merchant   = random.choice(merchants) if txn_type in ('P2M', 'Bill Payment', 'Recharge') else None
    category   = merchant['category'] if merchant else ''
    amount     = transaction_amount(txn_type, category)
    txn_date   = random_date(START_DATE, END_DATE)
    # fraud logic: high amount, odd hours, mismatch state
    is_fraud = 0
    if amount > 8000 and txn_date.hour in range(1, 5):
        is_fraud = random.choices([0, 1], weights=[60, 40])[0]
    elif amount > 15000:
        is_fraud = random.choices([0, 1], weights=[70, 30])[0]
    elif txn_type == 'P2M' and merchant and sender['state'] != merchant['state']:
        is_fraud = random.choices([0, 1], weights=[90, 10])[0]
    status = 'Failed' if (is_fraud and random.random() < 0.3) else random.choices(
        ['Success', 'Failed', 'Pending'], weights=[88, 8, 4])[0]
    transactions.append({
        'txn_id':          f'TXN{tid:06d}',
        'txn_date':        txn_date.strftime('%Y-%m-%d'),
        'txn_time':        txn_date.strftime('%H:%M:%S'),
        'txn_datetime':    txn_date.strftime('%Y-%m-%d %H:%M:%S'),
        'txn_type':        txn_type,
        'sender_id':       sender['user_id'],
        'receiver_id':     receiver['user_id'] if receiver else None,
        'merchant_id':     merchant['merchant_id'] if merchant else None,
        'merchant_category': category,
        'amount':          amount,
        'payment_mode':    random.choice(PAYMENT_MODES),
        'bank_name':       sender['linked_bank'],
        'status':          status,
        'is_fraud_flag':   is_fraud,
        'device_type':     random.choices(['Android', 'iOS', 'Web'], weights=[65, 25, 10])[0],
    })

transactions_df = pd.DataFrame(transactions)

# ── Save CSVs ────────────────────────────────────────────
users_df.to_csv('/Users/mehekpandey/paytm_project/data/users.csv', index=False)
merchants_df.to_csv('/Users/mehekpandey/paytm_project/data/merchants.csv', index=False)
transactions_df.to_csv('/Users/mehekpandey/paytm_project/data/transactions.csv', index=False)

print(f"✅ Users:        {len(users_df)} rows")
print(f"✅ Merchants:    {len(merchants_df)} rows")
print(f"✅ Transactions: {len(transactions_df)} rows")
print(f"\nFraud txns:  {transactions_df['is_fraud_flag'].sum()}")
print(f"Success txns: {(transactions_df['status']=='Success').sum()}")
print(f"Date range:  {transactions_df['txn_date'].min()} → {transactions_df['txn_date'].max()}")
