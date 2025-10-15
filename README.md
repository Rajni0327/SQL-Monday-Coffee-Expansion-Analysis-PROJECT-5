## SQL-Monday-Coffee-Expansion-Analysis-PROJECT-1

## Project Overview
This project analyzes coffee sales data across multiple cities to identify market trends, customer behavior, and business expansion opportunities. The analysis uses PostgreSQL to query sales, customer, product, and city demographic data.


## DATABASE SCHEMAS ERD

![](https://github.com/Rajni0327/SQL-Monday-Coffee-Expansion-Analysis-PROJECT-5/blob/main/Screenshot%202025-10-13%20211941.png)

## Database Schema Overview

- **city**: Contains city demographics (population, rent, ranking)
- **customers**: Customer information linked to cities
- **products**: Coffee products and their prices
- **sales**: Transaction records linking customers, products, and sales data

---

## Query 1: Coffee Consumers Count

### Question
"How many people in each city are estimated to consume coffee, given that 25% of the population does?"

### SQL Query
```sql
SELECT city_name, 
       ROUND((population * 0.25)/1000000, 2) as coffee_consumers_in_millions, 
       city_rank 
FROM city 
ORDER BY 2 DESC;
```

### Explanation

1. **SELECT city_name**: Gets the name of each city
2. **population * 0.25**: Calculates 25% of the city's population (estimated coffee drinkers)
3. **/1000000**: Converts the number to millions for readability
4. **ROUND(..., 2)**: Rounds to 2 decimal places
5. **ORDER BY 2 DESC**: Sorts by coffee consumers (column 2) in descending order


### Business Insight
This helps identify cities with the largest potential customer base, regardless of current sales.

---

## Query 2A: Total Revenue from Q4 2023 (Overall)

### Question
"What is the total revenue generated from coffee sales in the last quarter of 2023?"

### SQL Query
```sql
SELECT SUM(total) as total_revenue
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = 2023
  AND EXTRACT(QUARTER FROM sale_date) = 4;
```

### Explanation

1. **SUM(total)**: Adds up all sales amounts
2. **EXTRACT(YEAR FROM sale_date) = 2023**: Filters for year 2023
3. **EXTRACT(QUARTER FROM sale_date) = 4**: Filters for Q4 (Oct, Nov, Dec)



---

## Query 2B: Total Revenue by City (Q4 2023)

### SQL Query
```sql
SELECT ci.city_name,
       SUM(s.total) as total_revenue
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
WHERE EXTRACT(YEAR FROM s.sale_date) = 2023
  AND EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY ci.city_name
ORDER BY total_revenue DESC;
```

### Explanation

1. **FROM sales s**: Start with sales table (aliased as 's')
2. **JOIN customers c**: Link sales to customers to get customer details
3. **JOIN city ci**: Link customers to cities to get city information
4. **WHERE filters**: Same as Query 2A, filtering for Q4 2023
5. **GROUP BY ci.city_name**: Aggregate data for each city
6. **SUM(s.total)**: Calculate total revenue per city
7. **ORDER BY total_revenue DESC**: Show highest revenue cities first

### Visual Representation of Joins
```
sales → customers → city
  ↓         ↓         ↓
sale_id  cust_name  city_name
total    city_id    population
```

### Business Insight
Identifies which cities are generating the most revenue, helping prioritize marketing efforts.

---

## Query 3: Sales Count for Each Product

### Question
"How many units of each coffee product have been sold?"

### SQL Query
```sql
SELECT p.product_name,
       COUNT(s.sale_id) as total_orders 
FROM products p
LEFT JOIN sales s ON s.product_id = p.product_id 
GROUP BY p.product_name
ORDER BY total_orders DESC;
```

### Explanation

1. **FROM products p**: Start with products table
2. **LEFT JOIN sales**: Keep ALL products, even if they have zero sales
   - Regular JOIN would exclude products with no sales
   - LEFT JOIN ensures we see underperforming products too
3. **COUNT(s.sale_id)**: Count number of sales transactions per product
4. **GROUP BY p.product_name**: Aggregate by each product
5. **ORDER BY total_orders DESC**: Show best sellers first

### Why LEFT JOIN?
```
Products Table:        Sales Table:
- Latte                - Sale 1: Latte
- Cappuccino           - Sale 2: Latte
- Espresso             - Sale 3: Cappuccino
- Mocha                (no Espresso or Mocha sales)

LEFT JOIN Result:
Latte: 2 orders
Cappuccino: 1 order
Espresso: 0 orders
Mocha: 0 orders
```

### Business Insight
Helps identify bestsellers for inventory planning and products that need promotion.

---

## Query 4: Average Sales Amount per City

### Question
"What is the average sales amount per customer in each city?"

### SQL Query
```sql
SELECT ci.city_name,
       SUM(s.total) as total_revenue,
       COUNT(DISTINCT s.customer_id) as total_customers,
       ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sales_per_customer
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;
```

### Explanation

1. **SUM(s.total)**: Total revenue for each city
2. **COUNT(DISTINCT s.customer_id)**: Count unique customers (DISTINCT prevents counting the same customer multiple times)
3. **::numeric**: Converts to numeric type for precise division
4. **Division**: Total revenue ÷ unique customers = average per customer
5. **ROUND(..., 2)**: Round to 2 decimal places for currency

### Why DISTINCT is Important
```
Without DISTINCT:
Customer A: 3 purchases
Customer B: 2 purchases
COUNT = 5 (incorrect - counts purchases, not customers)

With DISTINCT:
Customer A: counted once
Customer B: counted once
COUNT = 2 (correct - counts unique customers)
```

### Business Insight
Shows customer spending power in different cities. High average = wealthy customers or effective upselling.

---

## Query 5: City Population and Coffee Consumers (CTE Version)

### Question
"Compare estimated coffee consumers with actual current customers per city."

### SQL Query
```sql
WITH city_table AS (
    SELECT city_name, 
           ROUND((population * 0.25)/1000000, 2) as coffee_consumers
    FROM city
),
customers_table AS (
    SELECT ci.city_name, 
           COUNT(DISTINCT c.customer_id) as unique_customers
    FROM sales s
    JOIN customers c ON c.customer_id = s.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
)
SELECT ct.city_name,
       ct.coffee_consumers as coffee_consumers_in_millions,
       cust.unique_customers
FROM city_table ct
JOIN customers_table cust ON ct.city_name = cust.city_name;
```

### Explanation

**Understanding CTEs (Common Table Expressions)**
CTEs are temporary result sets that exist only during query execution. Think of them as "sub-queries with names."

**Step 1 - city_table CTE:**
```sql
WITH city_table AS (...)
```
Creates a temporary table with:
- City name
- Estimated coffee consumers (25% of population in millions)

**Step 2 - customers_table CTE:**
```sql
customers_table AS (...)
```
Creates another temporary table with:
- City name  
- Actual count of unique customers who made purchases

**Step 3 - Final SELECT:**
Joins both CTEs to compare:
- Potential market size (estimated consumers)
- Current market penetration (actual customers)

### Visual Flow
```
city_table CTE          customers_table CTE
├─ Delhi: 7.7M         ├─ Delhi: 68 customers
├─ Mumbai: 5.2M        ├─ Mumbai: 45 customers
└─ Pune: 3.1M          └─ Pune: 52 customers
         ↓                        ↓
    JOIN both on city_name
         ↓
Final Result: Shows gap between potential and actual
```

### Business Insight
Reveals untapped market potential. Large gap = opportunity for growth.

---

## Query 6: Top Selling Products by City

### Question
"What are the top 3 selling products in each city based on sales volume?"

### SQL Query
```sql
SELECT * FROM (
    SELECT ci.city_name,
           p.product_name,
           COUNT(s.sale_id) as total_orders,
           DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
    FROM sales s
    JOIN products p ON s.product_id = p.product_id 
    JOIN customers c ON c.customer_id = s.customer_id 
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
) ranked
WHERE rank <= 3;
```

### Explanation

**PARTITION BY**: Divides data into groups
**ORDER BY**: Sorts within each group
**DENSE_RANK()**: Assigns ranks without gaps

**Inner Query (Subquery):**
1. Joins all tables to get city and product information
2. **GROUP BY city_name, product_name**: Creates groups for each product in each city
3. **COUNT(s.sale_id)**: Counts orders for each product-city combination
4. **DENSE_RANK() OVER (...)**: Ranks products within each city

**PARTITION BY Visualization:**
```
City: Delhi              City: Mumbai
├─ Latte: 50 → Rank 1   ├─ Cappuccino: 60 → Rank 1
├─ Mocha: 45 → Rank 2   ├─ Latte: 55 → Rank 2
├─ Espresso: 40 → Rank 3├─ Mocha: 48 → Rank 3
└─ Cappuccino: 30→Rank 4└─ Espresso: 30 → Rank 4
```

**Outer Query:**
Filters to keep only ranks 1, 2, and 3

### DENSE_RANK vs RANK
```
RANK():              DENSE_RANK():
1st: 100 orders → 1  1st: 100 orders → 1
2nd: 100 orders → 1  2nd: 100 orders → 1
3rd: 90 orders → 3   3rd: 90 orders → 2  ← No gap!
4th: 85 orders → 4   4th: 85 orders → 3
```

### Business Insight
Enables localized inventory and marketing strategies based on city preferences.

---

## Query 7: Customer Segmentation by City

### Question
"How many unique customers are there in each city who have purchased coffee products?"

### SQL Query
```sql
SELECT ci.city_name,
       COUNT(DISTINCT c.customer_id) as unique_customers
FROM city ci
LEFT JOIN customers c ON c.city_id = ci.city_id
JOIN sales s ON s.customer_id = c.customer_id
WHERE s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY ci.city_name;
```

### Explanation

1. **FROM city ci**: Start with cities table
2. **LEFT JOIN customers**: Include all cities, even those with no customers
3. **JOIN sales**: Connect to sales to verify purchases
4. **WHERE s.product_id IN (...)**: Filter for coffee products only (IDs 1-14)
   - Excludes non-coffee items like pastries or merchandise
5. **COUNT(DISTINCT c.customer_id)**: Count unique customers per city
6. **GROUP BY ci.city_name**: Aggregate by city

### Why This Filter Matters
```
All Products:              Coffee Products Only:
- Coffee Latte (ID: 1)     ✓ Included
- Espresso (ID: 2)         ✓ Included
- Pastry (ID: 15)          ✗ Excluded
- Mug (ID: 16)             ✗ Excluded
```

### Business Insight
Focuses on core coffee business customers, excluding merchandise buyers.

---

## Query 8: Average Sale vs Rent Analysis

### Question
"Find each city's average sale per customer and average rent per customer to evaluate profitability."

### SQL Query
```sql
WITH city_table AS (
    SELECT ci.city_name,
           SUM(s.total) as total_revenue,
           COUNT(DISTINCT s.customer_id) as total_customers,
           ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_per_customer
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT city_name, estimated_rent
    FROM city
)
SELECT cr.city_name,
       cr.estimated_rent,
       ct.total_customers,
       ct.avg_sale_per_customer,
       ROUND(cr.estimated_rent::numeric/ct.total_customers::numeric, 2) as avg_rent_per_customer
FROM city_rent cr
JOIN city_table ct ON cr.city_name = ct.city_name
ORDER BY avg_sale_per_customer DESC;
```

### Explanation

**CTE 1 - city_table:**
Calculates customer metrics:
- Total revenue
- Customer count
- Average sale per customer

**CTE 2 - city_rent:**
Simple extraction of rent data

**Final SELECT:**
Calculates **avg_rent_per_customer**:
```
Formula: estimated_rent ÷ total_customers
```

This shows operational cost per customer.

### Business Logic Example
```
City: Pune
- Estimated Rent: ₹100,000/month
- Total Customers: 500
- Avg Rent per Customer: ₹200

City: Mumbai  
- Estimated Rent: ₹300,000/month
- Total Customers: 400
- Avg Rent per Customer: ₹750

Pune is more cost-efficient!
```

### Profitability Analysis
```
If avg_sale_per_customer > avg_rent_per_customer → Profitable
If avg_sale_per_customer < avg_rent_per_customer → Losing money
```

### Business Insight
Identifies cities where operational costs are justified by customer revenue.

---

## Query 9: Monthly Sales Growth Rate

### Question
"Calculate the percentage growth (or decline) in sales month-over-month for each city."

### SQL Query
```sql
WITH monthly_sales AS (
    SELECT ci.city_name,
           EXTRACT(MONTH FROM sale_date) as month,
           EXTRACT(YEAR FROM sale_date) as year,
           SUM(s.total) as total_sale
    FROM sales s
    JOIN customers c ON c.customer_id = s.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, month, year
    ORDER BY ci.city_name, year, month
),
growth_ratio AS (
    SELECT city_name, month, year, 
           total_sale as current_month_sale,
           LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
    FROM monthly_sales
)
SELECT city_name, month, year,
       current_month_sale,
       last_month_sale,
       ROUND((current_month_sale - last_month_sale)::numeric/last_month_sale::numeric * 100, 2) as growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;
```

### Explanation

**CTE 1 - monthly_sales:**
1. **EXTRACT(MONTH/YEAR)**: Pulls month and year from date
2. **SUM(s.total)**: Calculates total sales per month per city
3. **GROUP BY city_name, month, year**: Creates separate totals for each month
4. **ORDER BY**: Ensures chronological order

**CTE 2 - growth_ratio:**
Uses **LAG()** window function:
```sql
LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month)
```

**Understanding LAG():**
```
Month        Current Sale    LAG (Previous Month)
------       ------------    --------------------
Jan 2023     50,000          NULL (no previous)
Feb 2023     55,000          50,000
Mar 2023     52,000          55,000
Apr 2023     60,000          52,000
```

**LAG Parameters:**
- `total_sale`: The column to look back at
- `1`: Look back 1 row (previous month)
- `PARTITION BY city_name`: Reset for each city
- `ORDER BY year, month`: Ensure chronological order

**Final SELECT:**
Calculates growth percentage:
```
Formula: ((Current - Previous) / Previous) × 100
Example: ((55,000 - 50,000) / 50,000) × 100 = 10% growth
```

**WHERE last_month_sale IS NOT NULL:**
Removes the first month (no previous month to compare)

### Growth Calculation Example
```
City: Delhi
Mar 2023: ₹100,000 (previous)
Apr 2023: ₹120,000 (current)

Growth = ((120,000 - 100,000) / 100,000) × 100
       = (20,000 / 100,000) × 100
       = 20% growth
```

### Interpreting Results
```
Positive %: Sales increased (good!)
Negative %: Sales decreased (investigate why)
Large swings: Seasonal trends or one-time events
```

### Business Insight
Tracks business momentum, identifies seasonal patterns, and helps forecast future sales.

---

## Query 10: Market Potential Analysis (Comprehensive)

### Question
"Identify top 3 cities based on highest sales, showing total revenue, rent, customers, and market potential."

### SQL Query
```sql
WITH city_table AS (
    SELECT ci.city_name,
           SUM(s.total) as total_revenue,
           COUNT(DISTINCT s.customer_id) as total_customers,
           ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_per_customer
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT city_name, 
           estimated_rent,
           ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumers_in_millions
    FROM city
)
SELECT cr.city_name,
       total_revenue,
       cr.estimated_rent as total_rent,
       ct.total_customers,
       estimated_coffee_consumers_in_millions,
       ct.avg_sale_per_customer,
       ROUND(cr.estimated_rent::numeric/ct.total_customers::numeric, 2) as avg_rent_per_customer
FROM city_rent cr
JOIN city_table ct ON cr.city_name = ct.city_name
ORDER BY total_revenue DESC;
```

### Explanation

This is the **master analysis query** that combines multiple metrics.

**CTE 1 - city_table:**
Financial metrics:
- Total revenue (performance indicator)
- Customer count (market penetration)
- Average sale per customer (customer value)

**CTE 2 - city_rent:**
Market metrics:
- Estimated rent (operational cost)
- Estimated coffee consumers (market size)

**Final SELECT:**
Creates comprehensive city profile with 7 key metrics:

1. **city_name**: Location
2. **total_revenue**: Current performance
3. **total_rent**: Fixed operational cost
4. **total_customers**: Current market penetration
5. **estimated_coffee_consumers_in_millions**: Total addressable market
6. **avg_sale_per_customer**: Revenue per customer
7. **avg_rent_per_customer**: Cost efficiency

### Decision Matrix Example
```
City Analysis Template:

Pune:
✓ Revenue: ₹8M (HIGH)
✓ Rent/Customer: ₹150 (LOW - GOOD)
✓ Avg Sale: ₹11.5K (HIGH)
✓ Market Size: 3.2M (MEDIUM)
→ VERDICT: Expand (profitable + efficient)

Mumbai:
✓ Revenue: ₹6M (MEDIUM)
✗ Rent/Customer: ₹800 (HIGH - BAD)
✓ Avg Sale: ₹10K (MEDIUM)
✓ Market Size: 5.2M (HIGH)
→ VERDICT: Hold (expensive despite large market)
```

### Multi-Factor Decision Logic

The query enables evaluation across multiple dimensions:

**Profitability Factors:**
- Total revenue (higher = better)
- Avg rent per customer (lower = better)
- Avg sale per customer (higher = better)

**Growth Factors:**
- Estimated coffee consumers (larger market = more potential)
- Current customers (shows penetration rate)

**Efficiency Factors:**
- Revenue ÷ Rent ratio
- Customers ÷ Market size (penetration %)

### Business Recommendations Based on Query Results

**1st Priority: Pune**
```
Strengths:
- Highest total revenue
- Lowest avg rent per customer (cost-efficient)
- High avg sale per customer (valuable customers)

Action: Aggressive expansion
```

**2nd Priority: Delhi**
```
Strengths:
- Highest estimated coffee consumers (7.7M)
- Highest total customers (68)
- Low avg rent per customer (₹330)

Action: Scale existing operations
```

**3rd Priority: Jaipur**
```
Strengths:
- Highest customer count (69)
- Very low avg rent per customer (₹156)
- Better than average sales per customer (₹11.6K)

Action: Optimize and expand gradually
```

### Business Insight
This comprehensive analysis enables data-driven decisions about where to invest resources for expansion, considering both current performance and future potential.

---

## Key SQL Concepts Used Throughout

### 1. **Joins**
- **INNER JOIN**: Only matching records
- **LEFT JOIN**: All records from left table + matches from right

### 2. **Aggregations**
- **SUM()**: Total amounts
- **COUNT()**: Number of records
- **AVG()**: Averages (though we calculated manually for precision)

### 3. **Window Functions**
- **DENSE_RANK()**: Ranking within partitions
- **LAG()**: Access previous row data
- **OVER()**: Defines window for function
- **PARTITION BY**: Creates separate groups

### 4. **CTEs (Common Table Expressions)**
- Makes complex queries readable
- Breaks analysis into logical steps
- Can reference previous CTEs

### 5. **Type Casting**
- **::numeric**: Ensures precise decimal division
- Prevents integer division errors

### 6. **Date Functions**
- **EXTRACT()**: Pulls year, month, quarter from dates

---

## Summary of Business Value

Each query serves a specific business purpose:

1. **Market Sizing**: Identify largest potential markets
2. **Revenue Tracking**: Monitor financial performance
3. **Product Performance**: Optimize inventory
4. **Customer Value**: Understand spending patterns
5. **Market Penetration**: Measure growth opportunities
6. **Localization**: Tailor offerings by city
7. **Segmentation**: Focus on core customers
8. **Cost Analysis**: Evaluate operational efficiency
9. **Trend Analysis**: Track momentum and seasonality
10. **Strategic Planning**: Make expansion decisions

Together, these queries provide a complete picture of business health and growth opportunities.
