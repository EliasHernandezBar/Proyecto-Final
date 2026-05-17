-- Recomendación: trabajar dentro de un esquema
CREATE SCHEMA IF NOT EXISTS analitica;

---------------------------------------------------------------------------
-- 1) Vista detalle sales enriquecida
---------------------------------------------------------------------------
CREATE OR REPLACE VIEW analitica.v_fact_sales_enriched AS
SELECT
    fs.*,
    p.unit_price
FROM analitica.fact_sales fs
JOIN analitica.dim_product p
    ON fs.product_id = p.product_id
ORDER BY fs.transaction_id;


SELECT * 
FROM analitica.v_fact_sales_enriched limit 300;

SELECT * 
FROM analitica.v_fact_sales_enriched
WHERE transaction_date::text LIKE '2023-06-%'
LIMIT 2000;

---------------------------------------------------------------------------
-- 2) Vista KPI mensual (agregada por mes)
---------------------------------------------------------------------------
CREATE OR REPLACE VIEW analitica.v_kpi_sales_monthly AS
SELECT
  EXTRACT(YEAR FROM transaction_date) AS year,
  EXTRACT(MONTH FROM transaction_date) AS month,
  TO_CHAR(transaction_date, 'FMMonth') AS month_name,
  DATE_TRUNC('month', transaction_date) AS month_start,

  COUNT(DISTINCT transaction_id) AS orders,
  SUM(transaction_qty) AS units,
  SUM(total_amount) AS net_sales,

  SUM(total_amount) / NULLIF(COUNT(DISTINCT transaction_id), 0) AS aov,
  SUM(total_amount) / NULLIF(SUM(transaction_qty), 0) AS net_avg_price

FROM analitica.v_fact_sales_enriched
GROUP BY
  EXTRACT(YEAR FROM transaction_date),
  EXTRACT(MONTH FROM transaction_date),
  TO_CHAR(transaction_date, 'FMMonth'),
  DATE_TRUNC('month', transaction_date);

SELECT * 
FROM analitica.v_kpi_sales_monthly;

-----------------------------------------------------------------------------
-- 3) Vista KPI segmentación por producto 
-----------------------------------------------------------------------------

CREATE OR REPLACE VIEW analitica.v_kpi_sales_by_product AS
SELECT
  fs.product_id, p.product_category, p.product_type,

  COUNT(DISTINCT fs.transaction_id) AS orders,
  SUM(fs.transaction_qty) AS units,
  SUM(fs.total_amount) AS net_sales,

  SUM(fs.total_amount) / NULLIF(COUNT(DISTINCT fs.transaction_id), 0) AS aov

FROM analitica.v_fact_sales_enriched fs
JOIN analitica.dim_product p 
  ON p.product_id = fs.product_id

GROUP BY fs.product_id, p.product_category, p.product_type;

select * from analitica.v_kpi_sales_by_product;


-----------------------------------------------------------------------------
-- 4) Vista KPI segmentación por tienda 
-----------------------------------------------------------------------------

CREATE OR REPLACE VIEW analitica.v_kpi_sales_by_store AS
SELECT
  ds.store_location,

  COUNT(DISTINCT fs.transaction_id) AS orders,
  SUM(fs.transaction_qty) AS units,
  SUM(fs.total_amount) AS net_sales,

  ROUND(
    SUM(fs.total_amount) / NULLIF(COUNT(DISTINCT fs.transaction_id), 0),
    2
  ) AS aov,

  ROUND(
    SUM(fs.total_amount) / NULLIF(SUM(fs.transaction_qty), 0),
    2
  ) AS net_avg_price

FROM analitica.fact_sales fs
JOIN analitica.dim_store ds
  ON fs.store_id = ds.store_id

GROUP BY ds.store_location
ORDER BY net_sales DESC;


select * from analitica.v_kpi_sales_by_store;




-----------------------------------------------------------------------------
-- 5) Vista peparada específicamente para Machine Learning (ML) 
-----------------------------------------------------------------------------

CREATE OR REPLACE VIEW analitica.v_ml_sales AS
SELECT
    fs.transaction_id,
    fs.transaction_date,
    EXTRACT(MONTH FROM fs.transaction_date) AS month,
    EXTRACT(DOW FROM fs.transaction_date) AS weekday,
    fs.transaction_qty,
    fs.unit_price,
    fs.total_amount,
    ds.store_location,
    dp.product_category
FROM analitica.v_fact_sales_enriched fs
JOIN analitica.dim_store ds
    ON fs.store_id = ds.store_id
JOIN analitica.dim_product dp
    ON fs.product_id = dp.product_id;

select * from analitica.v_ml_sales limit 2000;

