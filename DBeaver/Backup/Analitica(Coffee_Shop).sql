-- =========================================================
-- 0) Crear/usar schema analiticas
-- =========================================================
CREATE SCHEMA IF NOT EXISTS analitica;
SET search_path TO analitica, coffee_shop;

-- =========================================================
-- 1) Limpiar (si existieran versiones previas)
-- =========================================================
DROP TABLE IF EXISTS analitica.dim_customer   CASCADE;
DROP TABLE IF EXISTS analitica.dim_employee   CASCADE;
DROP TABLE IF EXISTS analitica.dim_payment_methods    CASCADE;
DROP TABLE IF EXISTS analitica.dim_product    CASCADE;
DROP TABLE IF EXISTS analitica.dim_store     CASCADE;
DROP TABLE IF EXISTS analitica.fact_sales     CASCADE;



-- =========================================================
-- 2) Dimensiones (CTAS)
-- =========================================================

-- 2.1) customer
CREATE TABLE analitica.dim_customer AS
SELECT DISTINCT
    c."customer_id"   AS customer_id,
    c."name"        AS name,
    c."email"       AS email,
    c."phone"       AS phone
FROM coffee_shop.customer c;

select * from analitica.dim_customer ;

ALTER TABLE analitica.dim_customer
  ADD CONSTRAINT pk_dim_customer PRIMARY KEY (customer_id);

-- 2.2) store
CREATE TABLE analitica.dim_store AS
SELECT DISTINCT
    st."store_id"          AS store_id,
    st."store_location"  AS store_location,
    st."district"        AS district
FROM coffee_shop.store st;

select * from analitica.dim_store ;

ALTER TABLE analitica.dim_store
  ADD CONSTRAINT pk_dim_store PRIMARY KEY (store_id);

-- 2.3) producto
CREATE TABLE analitica.dim_product AS
SELECT DISTINCT
    p."product_id"          AS product_id,
    p."unit_price"  AS unit_price,
    p."product_category"        AS product_category,
    p."product_type"			AS product_type,
    p."product_detail"			AS product_detail
FROM coffee_shop.producto p;

select * from analitica.dim_product;

ALTER TABLE analitica.dim_product
  ADD CONSTRAINT pk_dim_product PRIMARY KEY (product_id);

-- 2.4) employee
CREATE TABLE analitica.dim_employee AS
SELECT DISTINCT
    e."employee_id"          AS employee_id,
    e."employee_name"  AS employee_name,
    e."phone"        AS phone
FROM coffee_shop.employee e;

select * from analitica.dim_employee;

ALTER TABLE analitica.dim_employee
  ADD CONSTRAINT pk_dim_employee PRIMARY KEY (employee_id);

-- 2.5) payment_methods
CREATE TABLE analitica.dim_payment_methods AS
SELECT DISTINCT
    pm."payment_methods_id"          AS payment_methods_id,
    pm."name"        AS name
    
FROM coffee_shop.payment_methods pm;

select * from analitica.dim_payment_methods;

ALTER TABLE analitica.dim_payment_methods
  ADD CONSTRAINT pk_dim_payment_methods PRIMARY KEY (payment_methods_id);


-- =========================================================
-- 3) Hechos (CTAS) - fact_sales
--    Crear una columna 'total' con el total de cada venta
--    Introducir el total a cada transacción/venta
-- =========================================================
CREATE TABLE analitica.fact_sales AS
SELECT
s."transaction_id"          AS transaction_id,
s."transaction_date"		AS transaction_date,
s."transaction_time"		AS transaction_time,
s."transaction_qty"			AS transaction_qty,
s."store_id"				as store_id,
s."product_id"				as product_id,
s."customer_id"				as customer_id,
s."employee_id"				as employee_id,
s."payment_methods_id"		as payment_methods_id
from coffee_shop.sales s;

select * from analitica.fact_sales limit 100;

-- Una vez cargados los datos, vamos a generar una nueva columna total
ALTER TABLE analitica.fact_sales
ADD COLUMN total_amount DECIMAL(10,2);
-- Actualizamos la tabla total multiplicando las unidades vendidas por el precio por unidad
UPDATE analitica.fact_sales s
SET total_amount = s.transaction_qty * p.unit_price
FROM producto p
WHERE p.product_id = s.product_id;

-- Índices útiles para joins analíticos
CREATE INDEX ix_fact_sales_customer   ON analitica.fact_sales (customer_id);
CREATE INDEX ix_fact_sales_producto    ON analitica.fact_sales (product_id);
CREATE INDEX ix_fact_sales_employee   ON analitica.fact_sales (employee_id);
CREATE INDEX ix_fact_sales_store     ON analitica.fact_sales (store_id);
CREATE INDEX ix_fact_sales_payment_methods   ON analitica.fact_sales (payment_methods_id);
-- =========================================================
-- 4) Llaves Foráneas (FKs)
-- =========================================================
ALTER TABLE analitica.fact_sales
  ADD CONSTRAINT fk_fact_customer
      FOREIGN KEY (customer_id)
      REFERENCES analitica.dim_customer (customer_id);

--FOREIGN KEY (costumer_id) REFERENCES customer (customer_id) ON DELETE cascade,


ALTER TABLE analitica.fact_sales
  ADD CONSTRAINT fk_fact_producto
      FOREIGN KEY (product_id)
      REFERENCES analitica.dim_product (product_id);

--FOREIGN KEY (product_id) REFERENCES producto (product_id) ON DELETE cascade,


ALTER TABLE analitica.fact_sales
  ADD CONSTRAINT fk_fact_employee
      FOREIGN KEY (employee_id)
      REFERENCES analitica.dim_employee (employee_id);

--FOREIGN KEY (employee_id) REFERENCES employee (employee_id) ON DELETE cascade,


ALTER TABLE analitica.fact_sales
  ADD CONSTRAINT fk_fact_store
      FOREIGN KEY (store_id)
      REFERENCES analitica.dim_store (store_id);

--FOREIGN KEY (store_id) REFERENCES store (store_id) ON DELETE cascade,

ALTER TABLE analitica.fact_sales
  ADD CONSTRAINT fk_fact_payment_methods
      FOREIGN KEY (payment_methods_id)
      REFERENCES analitica.dim_payment_methods (payment_methods_id);


--FOREIGN KEY (payment_methods_id) REFERENCES payment_methods (payment_methods_id) ON DELETE cascade

-- =========================================================
-- 5) (Opcional) Verificación rápida
-- =========================================================
select * from analitica.dim_customer   LIMIT 5;
select * from analitica.dim_employee;
select * from analitica.dim_product   LIMIT 5;
select * from analitica.dim_payment_methods;
select * from analitica.dim_store;
select * from analitica.fact_sales;