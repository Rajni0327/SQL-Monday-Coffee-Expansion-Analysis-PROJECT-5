


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

SELECT city_name , population * 0.25 , city_rank FROM city 
ORDER BY 2 DESC ;






--Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?


SELECT * FROM sales ;




--Sales Count for Each Product
--How many units of each coffee product have been sold?







--Average Sales Amount per City
--What is the average sales amount per customer in each city?







--City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers.







--Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?






--Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?








--Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer







--Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).







--Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer







