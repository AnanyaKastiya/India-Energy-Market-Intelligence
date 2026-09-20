
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
