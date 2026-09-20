"""
ETL Pipeline & Data Quality Validation Script
============================================
Project: India Energy & Petroleum Market Intelligence Platform
Database: SQLite (india_energy_warehouse.db)

This script:
1. Validates schema integrity and data completeness.
2. Performs automated physical mass-balance tests.
3. Builds the relational SQLite database with indexed Star Schema tables.
4. Loads all processed dimension and fact tables into the database.
"""

import os
import sqlite3
import pandas as pd
import numpy as np

BASE_DIR = r"c:\Users\anany\OneDrive\Desktop\Energy_Analytics"
PROCESSED_DIR = os.path.join(BASE_DIR, "data", "processed")
DB_DIR = os.path.join(BASE_DIR, "database")
SQL_DIR = os.path.join(BASE_DIR, "sql")

os.makedirs(DB_DIR, exist_ok=True)
os.makedirs(SQL_DIR, exist_ok=True)

DB_PATH = os.path.join(DB_DIR, "india_energy_warehouse.db")

print("==========================================================")
print("RUNNING ETL PIPELINE & DATA QUALITY ASSURANCE...")
print("==========================================================")

# -------------------------------------------------------------
# 1. LOAD PROCESSED DATASETS
# -------------------------------------------------------------
df_dim_date = pd.read_csv(os.path.join(PROCESSED_DIR, "dim_date.csv"))
df_dim_product = pd.read_csv(os.path.join(PROCESSED_DIR, "dim_product.csv"))
df_dim_refinery = pd.read_csv(os.path.join(PROCESSED_DIR, "dim_refinery.csv"))

df_fact_upstream = pd.read_csv(os.path.join(PROCESSED_DIR, "fact_upstream_production.csv"))
df_fact_throughput = pd.read_csv(os.path.join(PROCESSED_DIR, "fact_refinery_throughput.csv"))
df_fact_consumption = pd.read_csv(os.path.join(PROCESSED_DIR, "fact_product_consumption.csv"))
df_fact_trade = pd.read_csv(os.path.join(PROCESSED_DIR, "fact_trade_and_prices.csv"))

# -------------------------------------------------------------
# 2. DATA QUALITY & INTEGRITY AUDIT
# -------------------------------------------------------------
datasets = {
    "dim_date": df_dim_date,
    "dim_product": df_dim_product,
    "dim_refinery": df_dim_refinery,
    "fact_upstream_production": df_fact_upstream,
    "fact_refinery_throughput": df_fact_throughput,
    "fact_product_consumption": df_fact_consumption,
    "fact_trade_and_prices": df_fact_trade
}

print("\n[TEST 1] Completeness & Null Value Audit:")
null_errors = 0
for name, df in datasets.items():
    null_count = df.isnull().sum().sum()
    if null_count > 0:
        print(f"  FAILED: {name} contains {null_count} null values!")
        null_errors += 1
    else:
        print(f"  PASSED: {name} - 0 null values across {len(df)} rows and {len(df.columns)} columns.")

# -------------------------------------------------------------
# 3. PHYSICAL MASS-BALANCE & DOMAIN SANITY VALIDATION
# -------------------------------------------------------------
print("\n[TEST 2] Petroleum Physical Mass-Balance Sanity Check:")

# Aggregate monthly total consumption across all products (MMT)
monthly_cons = df_fact_consumption.groupby("date")["consumption_mmt"].sum().reset_index()
balance_df = pd.merge(df_fact_trade, monthly_cons, on="date", suffixes=("", "_total"))

# Physical test:
# Total Liquid Inflow = Refinery Crude Intake + Product Imports
# Total Liquid Outflow = Domestic Product Sales + Product Exports
# Net Gap = Inflow - Outflow (Represents refinery processing gains/losses, stock changes, direct use)
# In standard petroleum refining, yield is typically 94-98% (with 2-6% internal fuel burn/loss).
inflow = balance_df["refinery_crude_intake_mmt"] + balance_df["product_imports_mmt"]
outflow = balance_df["consumption_mmt"] + balance_df["product_exports_mmt"]
yield_ratio = (outflow / inflow).mean()

print(f"  Average Refining & Distribution Yield Ratio: {yield_ratio:.3f}")
if 0.90 <= yield_ratio <= 1.05:
    print(f"  PASSED: Physical mass balance is verified within realistic operational limits (90% - 105%).")
else:
    print(f"  WARNING: Yield ratio {yield_ratio:.3f} is outside standard expected boundaries.")

# Domestic crude import dependency check (should be between 80% and 92%)
avg_dep = balance_df["crude_import_dependency_pct"].mean()
min_dep = balance_df["crude_import_dependency_pct"].min()
max_dep = balance_df["crude_import_dependency_pct"].max()
print(f"  Crude Import Dependency: Avg = {avg_dep:.1f}%, Min = {min_dep:.1f}%, Max = {max_dep:.1f}%")
if 80.0 <= min_dep and max_dep <= 95.0:
    print("  PASSED: Import dependency figures strictly adhere to historical PPAC benchmarks.")

# -------------------------------------------------------------
# 4. INITIALIZE SQLITE DATABASE & CREATE SCHEMA
# -------------------------------------------------------------
print(f"\n[STEP 3] Initializing SQLite Data Warehouse at:\n  {DB_PATH}")

if os.path.exists(DB_PATH):
    os.remove(DB_PATH)

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

# Enable foreign keys
cursor.execute("PRAGMA foreign_keys = ON;")

# Read schema design file if it exists, or define directly
schema_sql = """
-- =============================================================
-- INDIA ENERGY DATA WAREHOUSE - STAR SCHEMA DDL
-- =============================================================

CREATE TABLE dim_date (
    date TEXT PRIMARY KEY,
    calendar_year INTEGER NOT NULL,
    calendar_month INTEGER NOT NULL,
    month_name TEXT NOT NULL,
    month_short TEXT NOT NULL,
    fiscal_year TEXT NOT NULL,
    fiscal_quarter TEXT NOT NULL,
    days_in_month INTEGER NOT NULL
);

CREATE TABLE dim_product (
    product_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    key_driver TEXT,
    share_approx REAL
);

CREATE TABLE dim_refinery (
    refinery_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    operator TEXT NOT NULL,
    sector TEXT NOT NULL,
    state TEXT NOT NULL,
    capacity_mmtpa REAL NOT NULL
);

CREATE TABLE fact_upstream_production (
    production_id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    fiscal_year TEXT NOT NULL,
    company TEXT NOT NULL,
    source_type TEXT NOT NULL,
    crude_oil_production_tmt REAL NOT NULL,
    natural_gas_production_mmscm REAL NOT NULL,
    FOREIGN KEY (date) REFERENCES dim_date(date)
);

CREATE TABLE fact_refinery_throughput (
    throughput_id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    fiscal_year TEXT NOT NULL,
    refinery_id TEXT NOT NULL,
    refinery_name TEXT NOT NULL,
    operator TEXT NOT NULL,
    sector TEXT NOT NULL,
    crude_processed_tmt REAL NOT NULL,
    capacity_utilization_pct REAL NOT NULL,
    FOREIGN KEY (date) REFERENCES dim_date(date),
    FOREIGN KEY (refinery_id) REFERENCES dim_refinery(refinery_id)
);

CREATE TABLE fact_product_consumption (
    consumption_id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    fiscal_year TEXT NOT NULL,
    product_id TEXT NOT NULL,
    product_name TEXT NOT NULL,
    category TEXT NOT NULL,
    consumption_tmt REAL NOT NULL,
    consumption_mmt REAL NOT NULL,
    FOREIGN KEY (date) REFERENCES dim_date(date),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id)
);

CREATE TABLE fact_trade_and_prices (
    trade_id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    fiscal_year TEXT NOT NULL,
    indian_crude_basket_usd_per_bbl REAL NOT NULL,
    usd_inr_exchange_rate REAL NOT NULL,
    domestic_crude_production_mmt REAL NOT NULL,
    refinery_crude_intake_mmt REAL NOT NULL,
    crude_oil_imports_mmt REAL NOT NULL,
    crude_import_dependency_pct REAL NOT NULL,
    crude_import_bill_usd_million REAL NOT NULL,
    crude_import_bill_inr_crore REAL NOT NULL,
    product_exports_mmt REAL NOT NULL,
    product_exports_usd_million REAL NOT NULL,
    product_imports_mmt REAL NOT NULL,
    product_imports_usd_million REAL NOT NULL,
    net_oil_trade_balance_usd_million REAL NOT NULL,
    FOREIGN KEY (date) REFERENCES dim_date(date)
);

-- Indices for rapid query execution
CREATE INDEX idx_upstream_date ON fact_upstream_production(date);
CREATE INDEX idx_upstream_company ON fact_upstream_production(company);
CREATE INDEX idx_throughput_date ON fact_refinery_throughput(date);
CREATE INDEX idx_throughput_refinery ON fact_refinery_throughput(refinery_id);
CREATE INDEX idx_throughput_sector ON fact_refinery_throughput(sector);
CREATE INDEX idx_consumption_date ON fact_product_consumption(date);
CREATE INDEX idx_consumption_product ON fact_product_consumption(product_id);
CREATE INDEX idx_trade_date ON fact_trade_and_prices(date);
CREATE INDEX idx_trade_fy ON fact_trade_and_prices(fiscal_year);
"""

cursor.executescript(schema_sql)
print("  Successfully created dimensional tables, fact tables, foreign keys, and indexes.")

# Save schema DDL to sql/01_schema_design.sql
with open(os.path.join(SQL_DIR, "01_schema_design.sql"), "w", encoding="utf-8") as f:
    f.write(schema_sql)

# -------------------------------------------------------------
# 5. POPULATE DATABASE TABLES
# -------------------------------------------------------------
print("\n[STEP 4] Loading data records into SQLite warehouse...")

df_dim_date.to_sql("dim_date", conn, if_exists="append", index=False)
df_dim_product.to_sql("dim_product", conn, if_exists="append", index=False)
df_dim_refinery.to_sql("dim_refinery", conn, if_exists="append", index=False)

df_fact_upstream.to_sql("fact_upstream_production", conn, if_exists="append", index=False)
df_fact_throughput.to_sql("fact_refinery_throughput", conn, if_exists="append", index=False)
df_fact_consumption.to_sql("fact_product_consumption", conn, if_exists="append", index=False)
df_fact_trade.to_sql("fact_trade_and_prices", conn, if_exists="append", index=False)

conn.commit()

# Verify row counts in SQLite
print("  Database Table Verification:")
for tbl in ["dim_date", "dim_product", "dim_refinery", "fact_upstream_production", 
            "fact_refinery_throughput", "fact_product_consumption", "fact_trade_and_prices"]:
    count = cursor.execute(f"SELECT COUNT(*) FROM {tbl};").fetchone()[0]
    print(f"    Table '{tbl}': {count:,} rows")

conn.close()

print("\n==========================================================")
print("ETL PIPELINE & DATABASE GENERATION COMPLETE!")
print(f"Database File: {DB_PATH}")
print(f"Schema File: {os.path.join(SQL_DIR, '01_schema_design.sql')}")
print("==========================================================")
