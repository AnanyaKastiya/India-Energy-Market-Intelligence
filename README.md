# India Energy & Petroleum Market Intelligence Platform
**An End-to-End Analytics & Economic Modeling System for India's Petroleum Value Chain**

![Data Source](https://img.shields.io/badge/Data_Source-PPAC_MoPNG-blue)
![Stack](https://img.shields.io/badge/Stack-Python_|_SQL_|_Advanced_Excel-orange)
![Target Role](https://img.shields.io/badge/Target-Rystad_Energy_Analyst-navy)

---

## Executive Summary

This project delivers an enterprise-grade market intelligence platform analyzing **10 years of monthly historical data (April 2014 – March 2024 / FY15 – FY24, 120 months)** across India's entire petroleum value chain:
* **Upstream**: Domestic crude oil and natural gas extraction (ONGC Offshore/Onshore, OIL India, Private/JVs).
* **Midstream**: Crude throughput and capacity utilization across all 21 Indian refineries (PSU vs. Private like Reliance Jamnagar and Nayara).
* **Downstream**: Consumption trends across 9 refined petroleum products (Diesel/HSD, Petrol/MS, LPG, ATF, Bitumen, Petcoke).
* **Macro & Trade**: Indian Crude Basket (ICB) pricing, USD/INR foreign exchange exposure, and crude import bills.

The solution integrates **Python automated ETL**, a relational **SQLite Star Schema warehouse**, and a self-contained **Executive Excel Financial Model with an embedded Visual Analytics Dashboard**.

---

## Repository Structure

```text
Energy_Analytics/
├── data/
│   ├── raw/                           # Raw PPAC 10-year monthly time-series (120 months)
│   │   ├── ppac_crude_import_bill_and_prices.csv
│   │   ├── ppac_upstream_crude_gas_production.csv
│   │   ├── ppac_refinery_crude_throughput.csv
│   │   └── ppac_petroleum_product_consumption.csv
│   └── processed/                     # Clean dimensional tables formatted for SQL & BI tools
│       ├── dim_date.csv
│       ├── dim_product.csv
│       ├── dim_refinery.csv
│       ├── fact_upstream_production.csv
│       ├── fact_refinery_throughput.csv
│       ├── fact_product_consumption.csv
│       └── fact_trade_and_prices.csv
├── scripts/
│   ├── 01_data_extraction.py          # Extraction and historical time-series compilation
│   ├── 02_etl_pipeline.py             # Data quality assurance, mass balance test & DB loader
│   ├── 03_build_excel_model.py        # Generates the multi-tab executive Excel workbook with charts
│   └── test_queries.py                # SQL test runner verifying analytical queries
├── sql/
│   ├── 01_schema_design.sql           # Star Schema DDL with primary/foreign keys & indexes
│   └── 02_analytical_queries.sql      # 10 production-grade SQL analytical consulting queries
├── database/
│   └── india_energy_warehouse.db      # Live relational SQLite database (659 KB)
├── models/
│   └── India_Petroleum_Macro_Monitor_Updated.xlsx  # Multi-tab executive Excel model with embedded charts
└── README.md                          # Full project documentation & resume bullet points
```

---

## The Self-Contained Excel Model (`models/India_Petroleum_Macro_Monitor_Updated.xlsx`)

The entire project deliverable is accessible via a single, consulting-grade Excel workbook containing **5 comprehensive tabs**:

1. **`Executive_Dashboard`**:
   * Summary KPI Cards: Latest Import Dependency (90.7%), Current Indian Crude Basket Benchmark (\$84.5/bbl), Annual Forex Outflow (\$132.4B), and Total Refining Intake (256.8 MMTPA).
   * 10-Year Annual Macro Ledger with accounting number formatting, bold totals, and 10-year averages.
   * Embedded Area Chart (Energy Deficit) and Column Chart (Annual Forex Bill).
2. **`Visual_Analytics` (Embedded Executive Charts)**:
   * **Chart 1: The Energy Security Deficit (Stacked Area Chart)**: Plots domestic production stagnation vs. surging imports over 10 years.
   * **Chart 2: Macro Volatility & Annual Import Bill (Clustered Column Chart)**: Correlates global oil price shocks with India's fiscal bill.
   * **Chart 3: Downstream Fuel Demand Split (Doughnut Chart)**: Visualizes High-Speed Diesel's anchor share (~38-40%) vs. Petrol and LPG.
   * **Chart 4: India's Top Refining Hubs (Horizontal Bar Chart)**: Compares 10-year cumulative throughput across top facilities (Reliance Jamnagar, Nayara, Paradip, Panipat, Kochi).
3. **`Sensitivity_Model` (The Two-Way What-If Engine)**:
   * **Matrix 1**: Annual Import Bill in **USD Billion** across oil prices (\$60 to \$120/bbl) and volume deviations (±10%).
   * **Matrix 2**: Annual Import Bill in **INR Lakh Crore** across oil prices and USD/INR exchange rates (₹75 to ₹90/\$).
   * *Key Takeaways*:
     * Every **+\$1/bbl** expands annual import bill by **~\$1.7 Billion USD (~₹14,100 Crore)**.
     * Every **+₹1/\$** depreciation inflates the annual oil bill by **~₹13,500 Crore**.
4. **`Refining_Balance_Sheet`**:
   * Proves India's **Refining Self-Sufficiency Index (>115%)**, showing how 255+ MMTPA refining capacity generates large diesel and ATF exports to buffer against crude deficits.
5. **`Product_Demand_Mix`**:
   * 10-year consumption matrix across 9 refined fuels with automated row totals and CAGR trends.

---

## Technical Highlights & Methodologies

### 1. Python Data Pipeline & Mass Balance Testing
* Ingested multi-year monthly time-series, standardized calendar vs. Indian fiscal year conventions (April–March), and classified fuels into standard refining fractions (*Light Distillates, Middle Distillates, Heavy Ends*).
* Built an automated **Physical Mass-Balance Validation Test**:
  $$\text{Refinery Crude Intake} + \text{Product Imports} \approx \text{Domestic Sales} + \text{Product Exports} + \Delta\text{Inventories} + \text{Refinery Loss}$$
  Verified an average operational yield ratio of **0.921 (92.1%)**, adhering to standard refinery fuel burn and distribution margins.

### 2. Relational SQL Star Schema Warehouse
* Designed dimensional model (`dim_date`, `dim_product`, `dim_refinery`) linked to fact tables (`fact_upstream_production`, `fact_refinery_throughput`, `fact_product_consumption`, `fact_trade_and_prices`).
* Created indexed tables in SQLite with zero null values across 4,300+ total rows.
* Developed 10 production analytical queries utilizing advanced SQL techniques:
  * **Window Functions**: `SUM() OVER(PARTITION BY ...)`, `AVG() OVER (ROWS BETWEEN 11 PRECEDING AND CURRENT ROW)` for 12-month trailing moving averages.
  * **YoY / Lag Logic**: `LAG()` for Year-over-Year growth tracking and quarterly seasonality analysis.

---

## Resume Bullet Points

```markdown
India Petroleum & Refining Market Intelligence Platform | Python, SQL, Advanced Excel Modeling
• Architected an end-to-end energy intelligence platform analyzing 10 years of official PPAC monthly data (FY15–FY24) across upstream extraction, 21 refineries, and 9 refined petroleum products.
• Engineered automated Python ETL pipelines performing physical mass-balance validation (92.1% liquid yield verification) and deployed a relational SQLite Star Schema data warehouse with 10 production analytical queries.
• Developed an executive Excel financial model featuring dynamic two-way sensitivity matrices simulating the impact of oil price (±$10/bbl = ±$1.7B) and forex (±₹1/$ = ±₹13,500 Cr) shocks on India’s import bill.
• Designed a self-contained Executive Visual Analytics dashboard in Excel with embedded charts modeling India's 85% to 90.7% import dependency trajectory, fuel slate shifts (diesel dominance), and refining export economics.
```
