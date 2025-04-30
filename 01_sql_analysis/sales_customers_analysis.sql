
CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);

TRUNCATE TABLE gold.dim_customers;

LOAD DATA INFILE 'C:\Users\adria\OneDrive\Documentos\MySQL Adriana\Data with Bara\sql-data-analytics-project\datasets\csv-files\gold.dim_customers.csv' INTO TABLE gold.dim_customers
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

BULK INSERT gold.dim_customers
FROM 'C:\Users\adria\OneDrive\Documentos\MySQL Adriana\Data with Bara\sql-data-analytics-project\datasets\csv-files\gold.dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);

TRUNCATE TABLE gold.dim_products;

BULK INSERT gold.dim_products
FROM 'C:\Users\adria\OneDrive\Documentos\MySQL Adriana\Data with Bara\sql-data-analytics-project\datasets\csv-files\gold.dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);

TRUNCATE TABLE gold.fact_sales;

BULK INSERT gold.fact_sales
FROM 'C:\Users\adria\OneDrive\Documentos\MySQL Adriana\Data with Bara\sql-data-analytics-project\datasets\csv-files\gold.fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
--------------------------------------------------------------------------------------------------------------------------------------------
/*CHANGE OVER TIME (TRENDS)
	1. Behaviour of the business over time*/

SELECT 
	YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
	SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY order_year, order_month
ORDER BY order_year, order_month ASC;

/*CUMULATIVE ANALYSIS
	1. Calculate the total sales per month
	2. Running total of sales over time*/

SELECT
	order_year,
    order_month,
    total_sales,
    SUM(total_sales) OVER (PARTITION BY order_year ORDER BY order_year, order_month) AS running_total_sales,
    AVG(avg_price) OVER (PARTITION BY order_year ORDER BY order_year, order_month) AS moving_avg_price
FROM
(
SELECT
	YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    AVG(price) AS avg_price
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
) t
;

/*PERFORMANCE ANALYSIS: Compare current value to target value
	1. Analyze the yearly performance of products by comparing each product's sales to both its average sales performance and the previous year's sales*/

WITH yearly_product_sales AS (
SELECT
YEAR(f.order_date) AS order_year,
SUM(f.sales_amount) AS current_sales,
p.product_name
FROM fact_sales AS f
	LEFT JOIN dim_products AS p
    ON f.product_key = p.product_key
WHERE order_date IS NOT NULL
GROUP BY YEAR(f.order_date), p.product_name
)

SELECT 
	order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
    current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS difference_average,
CASE
	WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above avg'
	WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below avg'
	ELSE 'Avg'
END avg_change,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS difference_year,
CASE
	WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increased'
	WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decreased'
	ELSE 'No Change'
END previous_year_change
FROM yearly_product_sales
ORDER BY product_name, order_year
;

/*PART-TO-WHOLE: Proportional analysis
	1. Which category contribute the most to overall sales?*/

WITH category_sales AS (
SELECT
	category,
	SUM(sales_amount) AS total_sales
FROM fact_sales AS f
	LEFT JOIN dim_products AS p
	ON p.product_key = f.product_key
GROUP BY category)

SELECT
	category,
	total_sales,
	SUM(total_sales) OVER () AS overall_sales,
	CONCAT(ROUND((total_sales / SUM(total_sales) OVER ()) * 100, 2), '%') AS percentage_total
FROM category_sales
ORDER BY total_sales DESC;

/*DATA SEGMENTATION: Group the data based on a specific range to help understand the correlation between two measures
	1. Segment products into cost ranges and count how many products fall into each segment*/

WITH product_segments AS (
SELECT
	product_key,
    product_name,
    cost,
CASE    
    WHEN cost < 100 THEN 'Below 100'
    WHEN cost BETWEEN 100 AND 500 THEN '100-500'
    WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
    ELSE 'Above 1000'
END cost_range
FROM dim_products)

SELECT
	cost_range,
	COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

/*Group customers into 3 segments based on their spending behavior:
	1. VIP: at least 12 months of history and spending more than 5000
	2. Regular: at least 12 months of history but spending 5000 or less
    3. lifespan less than 12 months   
And find the total number of customers by each group*/

WITH customer_spending AS (
SELECT
	c.customer_key,
	SUM(f.sales_amount) AS total_spent,
	MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    TIMESTAMPDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
    FROM fact_sales AS f
		LEFT JOIN dim_customers AS c
		ON f.customer_key = c.customer_key
GROUP BY c.customer_key
)

SELECT
	customer_segment,
    COUNT(customer_key) AS total_customers
    FROM (
    	SELECT
		customer_key,
		CASE
			WHEN lifespan >= 12 AND total_spent > 5000 THEN 'VIP'
			WHEN lifespan >= 12 AND total_spent <= 5000 THEN 'Regular'
			ELSE 'New'
		END customer_segment
		FROM customer_spending) t
	GROUP BY customer_segment
    ORDER BY total_customers DESC;
    
/*all info customer's lifespan*/
SELECT
	customer_key,
    SUM(sales_amount) AS total_spent,
	COUNT(customer_key) AS total_customers,
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    TIMESTAMPDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan,
	CASE
		WHEN TIMESTAMPDIFF(month, MIN(order_date), MAX(order_date)) >= 12 AND SUM(sales_amount) > 5000 THEN 'VIP'
		WHEN TIMESTAMPDIFF(month, MIN(order_date), MAX(order_date)) >= 12 AND SUM(sales_amount) <= 5000 THEN 'Regular'
		ELSE 'New'
	END customer_segment
	FROM fact_sales
	GROUP BY customer_key
    ORDER BY total_customers DESC;

/*CUSTOMER REPORT: Consolidates key customer metrics and behaviors
	1. Gathers essential fields such as names, ages, and trasaction details
    2. Segments customers into categories and age groups
    3. Aggregates customer level metrics: total orders, total sales, total quantity purchased, total products, lifespan
    4. Calculates valuable KPIs: recency (months since last order), average order value, and average monthly spend*/

/*CREATE VIEW AFTER ANALYSIS*/
CREATE VIEW gold.report_customers AS

WITH base_query AS (
/*	1. Base query: Retrieves core columns from tables*/
SELECT
	f.order_number,
    f.product_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    c.customer_key,
    c.customer_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    TIMESTAMPDIFF(year, c.birthdate, CURDATE()) AS age
FROM fact_sales AS f
	LEFT JOIN dim_customers AS c
    ON f.customer_key = c.customer_key
WHERE order_date IS NOT NULL
)

, customer_aggregation AS (
/*	2. Customer aggregations: Summarizes key metrics at the customer level*/
SELECT
	customer_key,
    customer_number,
    customer_name,
    age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	TIMESTAMPDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
WHERE customer_key IS NOT NULL
GROUP BY
	customer_key,
    customer_number,
    customer_name,
    age
)

/*	3. Aggregate customer level metrics*/
SELECT
	customer_key,
    customer_number,
    customer_name,
    age,
    CASE
		WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
		ELSE '50 and above'
    END AS age_group,
    CASE
		WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
		WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
		ELSE 'New'
	END AS customer_segment,
    /*4. KPI: recency*/
	last_order_date,
    TIMESTAMPDIFF(month, last_order_date, CURDATE()) AS recency,
    total_orders,
	total_sales,
	total_quantity,
	total_products,
	lifespan,
    /*5. KPI: Average order value (AVO)*/
	CASE
		WHEN total_sales = 0 THEN 0
        ELSE total_sales / total_orders
	END AS avg_order_value,
	/*4. KPI: Average monthly spend*/   
	CASE
		WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
	END AS avg_monthly_spend
FROM customer_aggregation;
    
/*CREATE REPORT*/
SELECT * 
FROM gold.report_customers;

SELECT
	customer_segment,
	COUNT(customer_number) AS total_customers,
	SUM(total_sales) AS total_sales
FROM gold.report_customers
GROUP BY customer_segment
;






