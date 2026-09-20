-- =====================================================================
-- INDIA ENERGY & PETROLEUM MARKET INTELLIGENCE PLATFORM
-- Production SQL Analytical Queries Suite
-- Target Database: SQLite / ANSI SQL Compatible
-- =====================================================================

-- ---------------------------------------------------------------------
-- QUERY 1: 10-Year Import Dependency & National Crude Deficit Trajectory
-- Business Context: Tracks India's fundamental energy security challenge:
-- domestic production stagnation vs. expanding refinery crude intake.
-- ---------------------------------------------------------------------
SELECT 
    t.fiscal_year,
    ROUND(SUM(t.domestic_crude_production_mmt), 2) AS total_domestic_production_mmt,
    ROUND(SUM(t.refinery_crude_intake_mmt), 2) AS total_refinery_intake_mmt,
    ROUND(SUM(t.crude_oil_imports_mmt), 2) AS total_crude_imports_mmt,
    ROUND(SUM(t.crude_oil_imports_mmt) - SUM(t.domestic_crude_production_mmt), 2) AS net_crude_deficit_mmt,
    ROUND(AVG(t.crude_import_dependency_pct), 2) AS avg_import_dependency_pct
FROM fact_trade_and_prices t
GROUP BY t.fiscal_year
ORDER BY t.fiscal_year ASC;


-- ---------------------------------------------------------------------
-- QUERY 2: Macro Volatility: Indian Crude Basket Price vs. Forex Outflow
-- Business Context: Quantifies the double-whammy of high crude prices 
-- and USD/INR currency depreciation on India's foreign exchange bill.
-- ---------------------------------------------------------------------
SELECT 
    t.fiscal_year,
    ROUND(AVG(t.indian_crude_basket_usd_per_bbl), 2) AS avg_icb_price_usd_per_bbl,
    ROUND(AVG(t.usd_inr_exchange_rate), 2) AS avg_usd_inr_rate,
    ROUND(SUM(t.crude_import_bill_usd_million) / 1000.0, 2) AS total_import_bill_usd_billion,
    ROUND(SUM(t.crude_import_bill_inr_crore) / 100000.0, 2) AS total_import_bill_inr_lakh_crore,
    ROUND(
        (SUM(t.crude_import_bill_usd_million) - LAG(SUM(t.crude_import_bill_usd_million)) OVER (ORDER BY t.fiscal_year)) 
        / LAG(SUM(t.crude_import_bill_usd_million)) OVER (ORDER BY t.fiscal_year) * 100.0, 2
    ) AS yoy_import_bill_change_pct
FROM fact_trade_and_prices t
GROUP BY t.fiscal_year
ORDER BY t.fiscal_year ASC;


-- ---------------------------------------------------------------------
-- QUERY 3: Upstream Production Breakdown & 10-Year Decline Rates
-- Business Context: Analyzes which producer groups (ONGC, OIL, Pvt/JVs)
-- drove the structural decline in Indian domestic crude output.
-- ---------------------------------------------------------------------
WITH UpstreamSummary AS (
    SELECT 
        fiscal_year,
        company,
        source_type,
        SUM(crude_oil_production_tmt) AS annual_crude_tmt,
        SUM(natural_gas_production_mmscm) AS annual_gas_mmscm
    FROM fact_upstream_production
    WHERE fiscal_year IN ('FY 2014-15', 'FY 2023-24')
    GROUP BY fiscal_year, company, source_type
)
SELECT 
    u14.company,
    u14.source_type,
    ROUND(u14.annual_crude_tmt / 1000.0, 2) AS crude_fy15_mmt,
    ROUND(u24.annual_crude_tmt / 1000.0, 2) AS crude_fy24_mmt,
    ROUND(((u24.annual_crude_tmt - u14.annual_crude_tmt) / u14.annual_crude_tmt) * 100.0, 2) AS crude_10yr_change_pct,
    ROUND(u14.annual_gas_mmscm / 1000.0, 2) AS gas_fy15_bcm,
    ROUND(u24.annual_gas_mmscm / 1000.0, 2) AS gas_fy24_bcm,
    ROUND(((u24.annual_gas_mmscm - u14.annual_gas_mmscm) / u14.annual_gas_mmscm) * 100.0, 2) AS gas_10yr_change_pct
FROM UpstreamSummary u14
JOIN UpstreamSummary u24 
    ON u14.company = u24.company 
    AND u14.source_type = u24.source_type
    AND u14.fiscal_year = 'FY 2014-15' 
    AND u24.fiscal_year = 'FY 2023-24'
ORDER BY crude_fy15_mmt DESC;


-- ---------------------------------------------------------------------
-- QUERY 4: Deepwater Natural Gas Turnaround (Post-2021 Ramp-Up)
-- Business Context: Highlights the reversal of India's domestic gas 
-- decline driven by deepwater KG-D6 (RIL-BP) production starting 2021.
-- ---------------------------------------------------------------------
SELECT 
    d.fiscal_year,
    ROUND(SUM(CASE WHEN u.company = 'ONGC' THEN u.natural_gas_production_mmscm ELSE 0 END) / 1000.0, 2) AS ongc_gas_bcm,
    ROUND(SUM(CASE WHEN u.company = 'OIL India' THEN u.natural_gas_production_mmscm ELSE 0 END) / 1000.0, 2) AS oil_india_gas_bcm,
    ROUND(SUM(CASE WHEN u.company = 'Private / JV' THEN u.natural_gas_production_mmscm ELSE 0 END) / 1000.0, 2) AS pvt_jv_gas_bcm,
    ROUND(SUM(u.natural_gas_production_mmscm) / 1000.0, 2) AS total_india_gas_bcm
FROM fact_upstream_production u
JOIN dim_date d ON u.date = d.date
GROUP BY d.fiscal_year
ORDER BY d.fiscal_year ASC;


-- ---------------------------------------------------------------------
-- QUERY 5: Refining Utilization Benchmarking: PSU vs. Private vs. JV
-- Business Context: Shows why India is an export powerhouse, private 
-- refiners consistently run at >105% utilization with higher complexity.
-- ---------------------------------------------------------------------
SELECT 
    r.sector,
    COUNT(DISTINCT r.refinery_id) AS total_refineries,
    ROUND(SUM(r.capacity_mmtpa), 1) AS total_installed_capacity_mmtpa,
    ROUND(AVG(t.capacity_utilization_pct), 2) AS avg_capacity_utilization_pct,
    ROUND(MIN(t.capacity_utilization_pct), 2) AS min_monthly_utilization_pct,
    ROUND(MAX(t.capacity_utilization_pct), 2) AS max_monthly_utilization_pct,
    ROUND(SUM(t.crude_processed_tmt) / 1000.0, 2) AS total_10yr_crude_processed_mmt
FROM fact_refinery_throughput t
JOIN dim_refinery r ON t.refinery_id = r.refinery_id
GROUP BY r.sector
ORDER BY avg_capacity_utilization_pct DESC;


-- ---------------------------------------------------------------------
-- QUERY 6: Top 5 Refining Hubs by Cumulative 10-Year Crude Intake
-- Business Context: Identifies India's primary petroleum manufacturing hubs.
-- ---------------------------------------------------------------------
SELECT 
    t.refinery_name,
    t.operator,
    t.sector,
    r.state,
    r.capacity_mmtpa,
    ROUND(SUM(t.crude_processed_tmt) / 1000.0, 2) AS cumulative_crude_processed_mmt,
    ROUND(AVG(t.capacity_utilization_pct), 2) AS avg_utilization_pct
FROM fact_refinery_throughput t
JOIN dim_refinery r ON t.refinery_id = r.refinery_id
GROUP BY t.refinery_id, t.refinery_name, t.operator, t.sector, r.state, r.capacity_mmtpa
ORDER BY cumulative_crude_processed_mmt DESC
LIMIT 5;


-- ---------------------------------------------------------------------
-- QUERY 7: Petroleum Product Slate Structural Shift (Diesel vs Petrol vs LPG)
-- Business Context: Quantifies how the fuel mix changed between FY15 and FY24
-- (Petrol growing from ~13% to ~17.5% share, LPG rising via Ujjwala).
-- ---------------------------------------------------------------------
WITH ProductYearly AS (
    SELECT 
        c.fiscal_year,
        c.product_name,
        SUM(c.consumption_mmt) AS annual_volume_mmt,
        SUM(SUM(c.consumption_mmt)) OVER (PARTITION BY c.fiscal_year) AS total_demand_mmt
    FROM fact_product_consumption c
    GROUP BY c.fiscal_year, c.product_name
)
SELECT 
    fiscal_year,
    product_name,
    ROUND(annual_volume_mmt, 2) AS annual_consumption_mmt,
    ROUND((annual_volume_mmt / total_demand_mmt) * 100.0, 2) AS market_share_pct
FROM ProductYearly
WHERE product_name IN ('High Speed Diesel (HSD)', 'Motor Spirit (Petrol / MS)', 'Liquefied Petroleum Gas (LPG)', 'Aviation Turbine Fuel (ATF)')
  AND fiscal_year IN ('FY 2014-15', 'FY 2018-19', 'FY 2023-24')
ORDER BY fiscal_year ASC, market_share_pct DESC;


-- ---------------------------------------------------------------------
-- QUERY 8: Seasonal Cyclicality of Indian Fuel Demand (Monsoon vs Festive)
-- Business Context: Demonstrates domain understanding of Indian agriculture 
-- and monsoon impact on diesel (freight/tractors) and bitumen (road work).
-- ---------------------------------------------------------------------
SELECT 
    d.fiscal_quarter,
    CASE 
        WHEN d.fiscal_quarter = 'Q1' THEN 'Q1 (Apr-Jun): Pre-Monsoon Peak'
        WHEN d.fiscal_quarter = 'Q2' THEN 'Q2 (Jul-Sep): Monsoon Slump'
        WHEN d.fiscal_quarter = 'Q3' THEN 'Q3 (Oct-Dec): Post-Monsoon Festive Boom'
        WHEN d.fiscal_quarter = 'Q4' THEN 'Q4 (Jan-Mar): Agricultural Harvest Surge'
    END AS seasonal_narrative,
    ROUND(AVG(CASE WHEN c.product_name = 'High Speed Diesel (HSD)' THEN c.consumption_tmt END), 1) AS avg_monthly_diesel_tmt,
    ROUND(AVG(CASE WHEN c.product_name = 'Bitumen' THEN c.consumption_tmt END), 1) AS avg_monthly_bitumen_tmt,
    ROUND(AVG(CASE WHEN c.product_name = 'Motor Spirit (Petrol / MS)' THEN c.consumption_tmt END), 1) AS avg_monthly_petrol_tmt
FROM fact_product_consumption c
JOIN dim_date d ON c.date = d.date
GROUP BY d.fiscal_quarter
ORDER BY d.fiscal_quarter ASC;


-- ---------------------------------------------------------------------
-- QUERY 9: The "Refining Hub" Paradox: Gross Deficit vs. Net Product Export Generation
-- Business Context: Quantifies India's dual role as a crude importer 
-- and a multi-billion dollar refined fuel exporter.
-- ---------------------------------------------------------------------
SELECT 
    t.fiscal_year,
    ROUND(SUM(t.crude_oil_imports_mmt), 2) AS crude_imports_mmt,
    ROUND(SUM(t.product_exports_mmt), 2) AS refined_product_exports_mmt,
    ROUND(SUM(t.crude_import_bill_usd_million) / 1000.0, 2) AS crude_import_cost_usd_billion,
    ROUND(SUM(t.product_exports_usd_million) / 1000.0, 2) AS product_export_revenue_usd_billion,
    ROUND((SUM(t.product_exports_usd_million) / SUM(t.crude_import_bill_usd_million)) * 100.0, 2) AS export_offset_coverage_pct,
    ROUND(SUM(t.net_oil_trade_balance_usd_million) / 1000.0, 2) AS net_oil_trade_balance_usd_billion
FROM fact_trade_and_prices t
GROUP BY t.fiscal_year
ORDER BY t.fiscal_year ASC;


-- ---------------------------------------------------------------------
-- QUERY 10: Window Function: 12-Month Trailing Moving Average (TMA) & Shock Analysis
-- Business Context: Filters out monthly noise to uncover underlying diesel 
-- demand trends through the 2020 COVID shock and 2022 inflation recovery.
-- ---------------------------------------------------------------------
WITH MonthlyDiesel AS (
    SELECT 
        c.date,
        c.fiscal_year,
        c.consumption_tmt AS monthly_diesel_tmt,
        AVG(c.consumption_tmt) OVER (
            ORDER BY c.date 
            ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
        ) AS diesel_12m_trailing_avg_tmt
    FROM fact_product_consumption c
    WHERE c.product_name = 'High Speed Diesel (HSD)'
)
SELECT 
    date,
    fiscal_year,
    ROUND(monthly_diesel_tmt, 1) AS monthly_diesel_tmt,
    ROUND(diesel_12m_trailing_avg_tmt, 1) AS diesel_12m_tma_tmt,
    ROUND(((monthly_diesel_tmt - diesel_12m_trailing_avg_tmt) / diesel_12m_trailing_avg_tmt) * 100.0, 2) AS dev_from_trailing_avg_pct
FROM MonthlyDiesel
WHERE date IN ('2019-12-01', '2020-04-01', '2020-10-01', '2021-04-01', '2022-06-01', '2023-12-01', '2024-03-01')
ORDER BY date ASC;
