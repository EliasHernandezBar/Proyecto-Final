DROP SCHEMA IF EXISTS Coffee_Shop CASCADE;
CREATE SCHEMA Coffee_Shop;
SET search_path TO Coffee_Shop

-- Creación de la tabla Ventas (sales)
create table sales (
transaction_id bigint PRIMARY key,
transaction_date date not null,
transaction_time time not null,
transaction_qty int not null,
store_id int not null,
product_id bigint not null,
customer_id bigint not null,
employee_id bigint not null,
payment_methods_id bigint not null,
FOREIGN KEY (store_id) REFERENCES store (store_id) ON DELETE cascade,
FOREIGN KEY (product_id) REFERENCES producto (product_id) ON DELETE cascade,
FOREIGN KEY (customer_id) REFERENCES customer (customer_id) ON DELETE cascade,
FOREIGN KEY (employee_id) REFERENCES employee (employee_id) ON DELETE cascade,
FOREIGN KEY (payment_methods_id) REFERENCES payment_methods (payment_methods_id) ON DELETE cascade
)

-- Una vez cargados los datos, vamos a generar una nueva columna total
ALTER TABLE sales
ADD COLUMN total DECIMAL(10,2);
-- Actualizamos la tabla total multiplicando las unidades vendidas por el precio por unidad

UPDATE sales s
SET total = s.transaction_qty * p.unit_price
FROM producto p
WHERE p.product_id = s.product_id;



create table customer (
customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
name Varchar(30) not null,
email Varchar(100) not null,
phone Varchar(20) not null 
)

create table store (
store_id bigint PRIMARY key,
store_location Varchar(20) not null,
district Varchar(50) not null
)

create table producto (
product_id bigint PRIMARY key,
unit_price DECIMAL(10,2) NOT NULL CHECK(unit_price>= 0),
product_category Varchar(100),
product_type Varchar(100),
product_detail Varchar (100)
)

create table employee (
employee_id bigint PRIMARY key,
employee_name Varchar(40) not null,
phone Varchar(20) not null
)

create table payment_methods (
payment_methods_id bigint PRIMARY key,
name Varchar(20) not null 
);

select * from customer c ;
select * from employee e ;
select * from producto p;
select * from payment_methods pm;
select * from store s;
select * from sales;


