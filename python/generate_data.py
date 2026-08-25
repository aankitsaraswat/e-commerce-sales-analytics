import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

np.random.seed(42)
random.seed(42)

# ---------------------------------------------------------
# 1. PRODUCTS
# ---------------------------------------------------------
categories = {
    "Electronics": (800, 45000, 0.35),
    "Fashion": (299, 4999, 0.55),
    "Home & Kitchen": (199, 8999, 0.45),
    "Beauty & Personal Care": (99, 2999, 0.60),
    "Sports & Fitness": (299, 6999, 0.40),
    "Books": (99, 999, 0.25),
    "Toys & Baby": (149, 3499, 0.45),
    "Grocery": (49, 1499, 0.20),
}

product_name_pool = {
    "Electronics": ["Wireless Earbuds", "Bluetooth Speaker", "Smartwatch", "Power Bank 10000mAh",
                    "Laptop Stand", "USB-C Hub", "Gaming Mouse", "Mechanical Keyboard", "4K Webcam", "Smartphone Case"],
    "Fashion": ["Cotton T-Shirt", "Denim Jacket", "Running Shoes", "Formal Shirt", "Leather Wallet",
                "Sunglasses", "Backpack", "Analog Watch", "Sneakers", "Woolen Sweater"],
    "Home & Kitchen": ["Non-stick Cookware Set", "Electric Kettle", "Air Fryer", "Blender", "Bed Sheet Set",
                        "Table Lamp", "Storage Organizer", "Vacuum Cleaner", "Cutlery Set", "Curtains"],
    "Beauty & Personal Care": ["Face Serum", "Sunscreen SPF50", "Hair Dryer", "Electric Trimmer", "Lipstick Set",
                                "Moisturizer", "Perfume", "Shampoo Combo", "Face Wash", "Nail Care Kit"],
    "Sports & Fitness": ["Yoga Mat", "Adjustable Dumbbells", "Resistance Bands", "Cricket Bat", "Football",
                          "Fitness Tracker", "Skipping Rope", "Gym Bag", "Badminton Racket", "Protein Shaker"],
    "Books": ["Self-Help Bestseller", "Fiction Novel", "Cookbook", "Children's Story Set", "Biography",
              "Business Strategy Book", "Comic Book Bundle", "Poetry Collection", "History Book", "Travel Guide"],
    "Toys & Baby": ["Building Blocks Set", "Remote Control Car", "Baby Stroller", "Soft Toy", "Puzzle Set",
                     "Baby Feeding Bottle", "Educational Tablet", "Diaper Pack", "Kids Bicycle", "Board Game"],
    "Grocery": ["Basmati Rice 5kg", "Cooking Oil 1L", "Assorted Snacks Box", "Green Tea Pack", "Instant Noodles Pack",
                "Honey 500g", "Almonds 250g", "Coffee Powder", "Breakfast Cereal", "Spice Combo Pack"],
}

products = []
pid = 1
for cat, (low, high, discount_rate) in categories.items():
    for name in product_name_pool[cat]:
        for variant in range(1, 4):  # 3 variants per product name
            price = round(np.random.uniform(low, high), 2)
            cost = round(price * np.random.uniform(0.55, 0.75), 2)
            products.append({
                "product_id": f"P{pid:04d}",
                "product_name": f"{name}" + (f" - Variant {variant}" if variant > 1 else ""),
                "category": cat,
                "price": price,
                "cost": cost
            })
            pid += 1

products_df = pd.DataFrame(products)
print("Products:", len(products_df))

# ---------------------------------------------------------
# 2. CUSTOMERS
# ---------------------------------------------------------
indian_cities = [
    ("Mumbai", "Maharashtra"), ("Delhi", "Delhi"), ("Bengaluru", "Karnataka"),
    ("Hyderabad", "Telangana"), ("Ahmedabad", "Gujarat"), ("Chennai", "Tamil Nadu"),
    ("Kolkata", "West Bengal"), ("Pune", "Maharashtra"), ("Jaipur", "Rajasthan"),
    ("Lucknow", "Uttar Pradesh"), ("Aligarh", "Uttar Pradesh"), ("Surat", "Gujarat"),
    ("Indore", "Madhya Pradesh"), ("Nagpur", "Maharashtra"), ("Patna", "Bihar"),
    ("Kochi", "Kerala"), ("Chandigarh", "Chandigarh"), ("Coimbatore", "Tamil Nadu"),
]

first_names = ["Aarav","Vivaan","Aditya","Vihaan","Arjun","Reyansh","Ishaan","Sai","Krishna","Kabir",
               "Ananya","Diya","Saanvi","Aadhya","Myra","Anika","Pari","Riya","Ira","Sara",
               "Rohan","Karan","Neha","Pooja","Amit","Sunil","Priya","Kavya","Nikhil","Meera"]
last_names = ["Sharma","Verma","Gupta","Reddy","Iyer","Nair","Singh","Patel","Rao","Mehta",
              "Kapoor","Malhotra","Joshi","Chopra","Das","Bose","Pillai","Agarwal","Kulkarni","Shah"]

n_customers = 1600
signup_start = datetime(2022, 1, 1)
signup_end = datetime(2024, 9, 30)
signup_range_days = (signup_end - signup_start).days

customers = []
for i in range(1, n_customers + 1):
    city, state = random.choice(indian_cities)
    fname = random.choice(first_names)
    lname = random.choice(last_names)
    signup_date = signup_start + timedelta(days=random.randint(0, signup_range_days))
    segment = np.random.choice(["New", "Regular", "Loyal", "VIP"], p=[0.35, 0.35, 0.20, 0.10])
    customers.append({
        "customer_id": f"C{i:05d}",
        "customer_name": f"{fname} {lname}",
        "email": f"{fname.lower()}.{lname.lower()}{i}@example.com",
        "city": city,
        "state": state,
        "signup_date": signup_date.strftime("%Y-%m-%d"),
        "customer_segment": segment
    })

customers_df = pd.DataFrame(customers)
print("Customers:", len(customers_df))

# ---------------------------------------------------------
# 3. ORDERS  (with a deliberate Q3-2024 dip story for delivery delays)
# ---------------------------------------------------------
order_start = datetime(2023, 1, 1)
order_end = datetime(2024, 12, 31)
total_days = (order_end - order_start).days

n_orders = 4200
order_ids = [f"O{str(i).zfill(6)}" for i in range(1, n_orders + 1)]

# monthly weighting to create seasonality + a Q3 2024 dip (simulate a logistics problem story)
months = pd.date_range("2023-01-01", "2024-12-01", freq="MS")
month_weights = {}
for m in months:
    w = 1.0
    if m.month in (11, 12):       # festive season boost
        w = 1.6
    if m.month in (6, 7):          # mid-year sale bump
        w = 1.3
    if m.year == 2024 and m.month in (7, 8, 9):   # Q3 2024 dip (delivery delay issue)
        w = 0.55
    month_weights[m.strftime("%Y-%m")] = w

month_keys = list(month_weights.keys())
month_probs = np.array(list(month_weights.values()))
month_probs = month_probs / month_probs.sum()

status_choices = ["Delivered", "Delivered", "Delivered", "Delivered", "Shipped", "Cancelled", "Returned"]

orders = []
customer_ids = customers_df["customer_id"].tolist()
customer_signup = dict(zip(customers_df["customer_id"], pd.to_datetime(customers_df["signup_date"])))

for oid in order_ids:
    chosen_month = np.random.choice(month_keys, p=month_probs)
    year, mo = map(int, chosen_month.split("-"))
    day = random.randint(1, 28)
    order_date = datetime(year, mo, day)

    cust = random.choice(customer_ids)
    # avoid orders before signup
    while customer_signup[cust] > pd.Timestamp(order_date):
        cust = random.choice(customer_ids)

    status = random.choice(status_choices)
    orders.append({
        "order_id": oid,
        "customer_id": cust,
        "order_date": order_date.strftime("%Y-%m-%d"),
        "order_status": status
    })

orders_df = pd.DataFrame(orders)
print("Orders:", len(orders_df))

# ---------------------------------------------------------
# 4. ORDER_ITEMS  (~8000 rows -> main analysis table)
# ---------------------------------------------------------
target_items = 8000
order_items = []
item_id = 1
product_ids = products_df["product_id"].tolist()
product_price = dict(zip(products_df["product_id"], products_df["price"]))
product_category = dict(zip(products_df["product_id"], products_df["category"]))

remaining = target_items
order_id_list = orders_df["order_id"].tolist()
np.random.shuffle(order_id_list)

idx = 0
while remaining > 0:
    oid = order_id_list[idx % len(order_id_list)]
    idx += 1
    n_items_this_order = min(remaining, np.random.choice([1, 1, 2, 2, 3, 4], p=[0.35, 0.25, 0.2, 0.1, 0.07, 0.03]))
    chosen_products = random.sample(product_ids, k=n_items_this_order)
    for p in chosen_products:
        qty = np.random.choice([1, 1, 1, 2, 2, 3], p=[0.5, 0.2, 0.1, 0.12, 0.05, 0.03])
        discount_pct = np.random.choice([0, 0, 0, 5, 10, 15, 20], p=[0.4, 0.15, 0.1, 0.15, 0.1, 0.06, 0.04])
        unit_price = product_price[p]
        order_items.append({
            "order_item_id": f"OI{item_id:06d}",
            "order_id": oid,
            "product_id": p,
            "quantity": int(qty),
            "unit_price": unit_price,
            "discount_pct": discount_pct
        })
        item_id += 1
        remaining -= 1
        if remaining <= 0:
            break

order_items_df = pd.DataFrame(order_items)
print("Order Items:", len(order_items_df))

# recompute which orders actually have items (some orders may end up with none)
active_order_ids = order_items_df["order_id"].unique().tolist()
orders_df = orders_df[orders_df["order_id"].isin(active_order_ids)].reset_index(drop=True)
print("Orders with items:", len(orders_df))

# ---------------------------------------------------------
# 5. PAYMENTS
# ---------------------------------------------------------
order_totals = order_items_df.copy()
order_totals["line_total"] = order_totals["quantity"] * order_totals["unit_price"] * (1 - order_totals["discount_pct"]/100)
order_value = order_totals.groupby("order_id")["line_total"].sum().round(2).to_dict()

payment_types = ["UPI", "Credit Card", "Debit Card", "Net Banking", "Cash on Delivery"]
order_date_map = dict(zip(orders_df["order_id"], pd.to_datetime(orders_df["order_date"])))

payments = []
pay_id = 1
for oid in orders_df["order_id"]:
    pay_date = order_date_map[oid] + timedelta(days=random.randint(0, 1))
    payments.append({
        "payment_id": f"PAY{pay_id:06d}",
        "order_id": oid,
        "payment_type": np.random.choice(payment_types, p=[0.35, 0.25, 0.15, 0.15, 0.10]),
        "payment_value": order_value.get(oid, 0),
        "payment_date": pay_date.strftime("%Y-%m-%d")
    })
    pay_id += 1

payments_df = pd.DataFrame(payments)
print("Payments:", len(payments_df))

# ---------------------------------------------------------
# 6. REVIEWS (only for Delivered/Returned orders, with delivery delay -> lower score story)
# ---------------------------------------------------------
review_comments_positive = ["Great product, fast delivery!", "Excellent quality, will buy again.",
                             "Exactly as described. Very happy.", "Good value for money.", "Loved it!"]
review_comments_neutral = ["Product is okay, average quality.", "Delivery took longer than expected.",
                            "Decent but packaging could improve.", "Works fine, nothing special."]
review_comments_negative = ["Very late delivery, disappointed.", "Product quality not as expected.",
                             "Received a damaged item.", "Poor packaging, item was scratched.",
                             "Not worth the price."]

reviews = []
rev_id = 1
for _, row in orders_df.iterrows():
    if row["order_status"] not in ("Delivered", "Returned"):
        continue
    order_date = order_date_map[row["order_id"]]
    estimated_delivery = order_date + timedelta(days=random.randint(4, 7))

    # Q3 2024 orders get systematically delayed (the "story" of the dataset)
    is_q3_2024 = (order_date.year == 2024 and order_date.month in (7, 8, 9))
    if is_q3_2024:
        actual_delivery = estimated_delivery + timedelta(days=random.randint(3, 10))
    else:
        actual_delivery = estimated_delivery + timedelta(days=random.randint(-2, 3))

    delay_days = (actual_delivery - estimated_delivery).days

    if delay_days > 3:
        score = np.random.choice([1, 2, 3], p=[0.45, 0.35, 0.2])
        comment = random.choice(review_comments_negative)
    elif delay_days > 0:
        score = np.random.choice([2, 3, 4], p=[0.2, 0.4, 0.4])
        comment = random.choice(review_comments_neutral)
    else:
        score = np.random.choice([3, 4, 5], p=[0.1, 0.35, 0.55])
        comment = random.choice(review_comments_positive) if score >= 4 else random.choice(review_comments_neutral)

    reviews.append({
        "review_id": f"R{rev_id:06d}",
        "order_id": row["order_id"],
        "review_score": int(score),
        "review_comment": comment,
        "estimated_delivery_date": estimated_delivery.strftime("%Y-%m-%d"),
        "actual_delivery_date": actual_delivery.strftime("%Y-%m-%d"),
        "review_date": (actual_delivery + timedelta(days=random.randint(1, 4))).strftime("%Y-%m-%d")
    })
    rev_id += 1

reviews_df = pd.DataFrame(reviews)
print("Reviews:", len(reviews_df))

# ---------------------------------------------------------
# SAVE ALL
# ---------------------------------------------------------
out = "/home/claude/ecom_project/"
customers_df.to_csv(out + "customers.csv", index=False)
products_df.to_csv(out + "products.csv", index=False)
orders_df.to_csv(out + "orders.csv", index=False)
order_items_df.to_csv(out + "order_items.csv", index=False)
payments_df.to_csv(out + "payments.csv", index=False)
reviews_df.to_csv(out + "reviews.csv", index=False)

print("\nDone.")
print("Total rows across all tables:",
      len(customers_df)+len(products_df)+len(orders_df)+len(order_items_df)+len(payments_df)+len(reviews_df))
