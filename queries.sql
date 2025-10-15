


-- creating a all the tables

DROP TABLE IF EXISTS city;
CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);




DROP TABLE IF EXISTS customers;
CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);



DROP TABLE IF EXISTS products;
CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);

DROP TABLE IF EXISTS sales;
CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);





SELECT * FROM city ;
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM sales ;




--------------------------
--Report and Data Analysis
--------------------------


--Coffee Consumers Count
--How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT city_name , ROUND((population * 0.25 )/1000000,2) as coffe_consumers, city_rank FROM city 
ORDER BY 2 DESC ;






--Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?


SELECT * FROM sales ;


--only profit
SELECT 
	SUM(total) as total_revenue
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date)  = 2023
	AND
	EXTRACT(quarter FROM sale_date) = 4;



	
--grouped by city name 
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)  = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;



--Sales Count for Each Product
--How many units of each coffee product have been sold?

SELECT * FROM sales ;
SELECT * FROM products  ;



SELECT p.product_name ,
		COUNT(s.sale_id) as total_orders 
FROM products as p
LEFT JOIN sales as s
ON s.product_id = p.product_id 
GROUP BY 1
ORDER BY 2 DESC ;




--Average Sales Amount per City
--What is the average sales amount per customer in each city?


SELECT * FROM sales ;
SELECT * FROM customers ;


SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(distinct s.customer_id) as total_customer,
	ROUND(SUM(s.total)::numeric/COUNT(distinct s.customer_id)::numeric,2) as per_city_avg_sales
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;



--City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers.
--rreturn city_name , total current customers , estimated coffee consumers 


WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name ;






--Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?


SELECT * FROM --table name
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC ) as rank
	FROM sales as s
	JOIN products as p 
	ON s.product_id = p.product_id 
	JOIN customers as c 
	ON c.customer_id = s.customer_id 
	JOIN city as ci 
	ON ci.city_id = c.city_id
	GROUP BY 1,2 
) as t1
WHERE rank <= 3 ;




--Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?



SELECT * FROM products;



SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_customer
FROM city as ci
LEFT JOIN customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1 ;






--Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer



WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_customer,
		ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_customer
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name, 
	estimated_rent
FROM city
)
SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_customer,
	ct.avg_sale_pr_customer,
	ROUND(cr.estimated_rent::numeric/ct.total_customer::numeric, 2) as avg_rent_per_cusromer
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC ;






--Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).



WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as current_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)


SELECT
	city_name,
	month,
	year,
	current_month_sale,
	last_month_sale,
	ROUND((current_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100, 2) as growth_ratio
FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	 ;





--Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer




WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_customer,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_per_customer
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_customer,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_per_customer,
	ROUND(cr.estimated_rent::numeric/ct.total_customer::numeric, 2) as avg_rent_per_customer
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC ; 



--Recommendation 


/*
First city will be Pune because 
1. its average rent per customer is very less 
2. it has highest total revenue 
3. average sale per customer is also high


Second city will be Delhi 
1. it has highest estimated coffee consumer which is 7.7M 
2. have highest total customer which is 68
3. average rent per customer is also less which is 330 


Third city will be Jaipur
1. highest cutomer number which is 69
2. Average rent per customer is very less which is 156
3. Avergae sale per customer is better than other cities which is 11.6k
*/