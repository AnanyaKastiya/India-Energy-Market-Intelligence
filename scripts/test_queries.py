"""
SQL Test Runner Script
======================
Executes all 10 analytical queries from sql/02_analytical_queries.sql
against database/india_energy_warehouse.db and displays sample results.
"""

import sqlite3

DB_PATH = r"c:\Users\anany\OneDrive\Desktop\Energy_Analytics\database\india_energy_warehouse.db"
SQL_FILE = r"c:\Users\anany\OneDrive\Desktop\Energy_Analytics\sql\02_analytical_queries.sql"

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

with open(SQL_FILE, "r", encoding="utf-8") as f:
    sql_content = f.read()

# Split by semicolon and extract only non-empty queries
raw_queries = sql_content.split(";")
queries = [q.strip() for q in raw_queries if q.strip()]

query_titles = [
    "Query 1: 10-Year Import Dependency & National Crude Deficit",
    "Query 2: Macro Volatility: ICB Price vs Forex Outflow",
    "Query 3: Upstream Production Breakdown & 10-Year Decline Rates",
    "Query 4: Deepwater Natural Gas Turnaround (Post-2021)",
    "Query 5: Refining Utilization Benchmarking: PSU vs Private vs JV",
    "Query 6: Top 5 Refining Hubs by Cumulative 10-Year Intake",
    "Query 7: Petroleum Product Slate Structural Shift",
    "Query 8: Seasonal Cyclicality of Indian Fuel Demand",
    "Query 9: The 'Refining Hub' Paradox: Gross Deficit vs Net Export",
    "Query 10: 12-Month Trailing Moving Average & Shock Analysis"
]

print(f"Total Queries Found: {len(queries)}")

all_passed = True
for idx, q in enumerate(queries):
    title = query_titles[idx] if idx < len(query_titles) else f"Query {idx+1}"
    print(f"\n--------------------------------------------------------")
    print(f"EXECUTING: {title}")
    print(f"--------------------------------------------------------")
    try:
        cursor.execute(q)
        rows = cursor.fetchall()
        col_names = [description[0] for description in cursor.description]
        print(f"Columns: {col_names}")
        print(f"Returned {len(rows)} rows. Sample row 1:")
        if rows:
            print(" ", rows[0])
        print("RESULT: SUCCESS")
    except Exception as e:
        print(f"RESULT: ERROR - {e}")
        all_passed = False

conn.close()

if all_passed:
    print("\n========================================================")
    print("ALL 10 ANALYTICAL SQL QUERIES EXECUTED SUCCESSFULLY!")
    print("========================================================")
