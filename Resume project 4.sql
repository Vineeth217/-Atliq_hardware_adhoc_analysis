# Request 1

SELECT DISTINCT market
FROM dim_customer
WHERE customer = "Atliq Exclusive" AND region = "APAC";

# Request 2

WITH cte1 AS (
	SELECT COUNT(distinct(product_code)) AS Y20
    FROM fact_sales_monthly
    WHERE fiscal_year = 2020),
 cte2 AS (
	SELECT COUNT(distinct(product_code)) AS Y21
    FROM fact_sales_monthly
    WHERE fiscal_year = 2021)
SELECT cte1.Y20 AS unique_products_2020,
		cte2.Y21 AS unique_products_2021,
        ROUND(((cte2.Y21-cte1.Y20)*100/cte1.Y20),2) AS Percentage_chg
        FROM cte1 CROSS JOIN cte2 ;

# Request 3

SELECT segment,COUNT(distinct(product_code)) AS Product_code
FROM dim_product
GROUP BY segment
ORDER BY product_code DESC;

# Request 4

WITH 
cte1 AS (
	SELECT p.segment, COUNT(DISTINCT(s.product_code)) AS Y20
    FROM dim_product p
    JOIN fact_sales_monthly s
    ON p.product_code = s.product_code
    WHERE s.fiscal_year = 2020
    GROUP BY p.segment
),
 cte2 AS (
	SELECT p.segment,COUNT(DISTINCT(s.product_code)) AS Y21
    FROM dim_product p
    JOIN fact_sales_monthly s
    ON p.product_code = s.product_code
    WHERE s.fiscal_year = 2021
    GROUP BY p.segment)

SELECT 	cte1.segment,
		cte1.Y20 AS product_count_2020,
		cte2.Y21 AS product_count_2021,
		(cte2.Y21-cte1.Y20) AS difference
FROM cte1 JOIN cte2 ON cte1.segment = cte2.segment
ORDER BY difference DESC;

# Request 5

SELECT m.product_code,p.product, m.manufacturing_cost
FROM fact_manufacturing_cost m
JOIN dim_product p
ON m.product_code = p.product_code
WHERE manufacturing_cost IN (
	SELECT max(manufacturing_cost) FROM fact_manufacturing_cost
    UNION
    SELECT min(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

# Request 6

	WITH cte1 AS (
		SELECT customer_code, AVG(pre_invoice_discount_pct)*100 AS pct
		FROM fact_pre_invoice_deductions
		WHERE fiscal_year = 2021
		GROUP BY customer_code
	),
	cte2 AS (
		SELECT customer_code, customer 
		FROM dim_customer
		WHERE market = 'india'
	)
	SELECT b.customer_code, b.customer, ROUND(a.pct, 2) AS Avg_discount_pct
	FROM cte1 a 
	JOIN cte2 b 
	ON a.customer_code = b.customer_code
	ORDER BY avg_discount_pct DESC
	LIMIT 5;

# Request 7

SELECT CONCAT(MONTHNAME(s.date), ' [', YEAR(s.date), ']') AS 'Month', 
		s.fiscal_year,
		ROUND(SUM(s.sold_quantity * g.gross_price), 2) AS Gross_sales_Amt
FROM fact_sales_monthly s
JOIN dim_customer c 	ON s.customer_code = c.customer_code
JOIN fact_gross_price g	ON s.product_code = g.product_code
WHERE c.customer = "Atliq Exclusive"
GROUP BY Month, s.fiscal_year
ORDER BY s.fiscal_year;

# Request 8

SELECT 
  CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-30' THEN 'Q1'
    WHEN date BETWEEN '2019-12-01' AND '2020-02-29' THEN 'Q2'
    WHEN date BETWEEN '2020-03-01' AND '2020-05-31' THEN 'Q3'
    WHEN date BETWEEN '2020-06-01' AND '2020-08-31' THEN 'Q4'
  END AS Quarters,
  SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
ORDER BY total_sold_quantity DESC;

# Request 9

WITH cte1 AS (
	SELECT c.channel,
		ROUND(SUM(g.gross_price * s.sold_quantity)/1000000,2) AS Gross_sales_mln
	FROM fact_sales_monthly s 
	JOIN dim_customer c 	ON s.customer_code = c.customer_code
	JOIN fact_gross_price g ON s.product_code = g.product_code
	WHERE s.fiscal_year = 2021
	GROUP BY channel)
SELECT channel, 
  CONCAT( '$',Gross_sales_mln) AS Gross_sales_mln,
  ROUND (Gross_sales_mln * 100 / SUM(Gross_sales_mln) OVER(),2) AS percentage
FROM cte1
ORDER BY percentage DESC;

# Request 10

WITH cte1 as (
	SELECT p.division, s.product_code, p.product,
			SUM(s.sold_quantity) AS Total_Sold_qty
	FROM fact_sales_monthly s
	JOIN dim_product p ON s.product_code = p.product_code
	WHERE s.fiscal_year = 2021
	GROUP BY p.division, s.product_code, p.product),
cte2 as (
	SELECT division,product_code,product, Total_Sold_qty,
		 RANK() OVER ( partition by division order by Total_Sold_qty DESC) AS Rank_order
	FROM cte1 )
    
SELECT *
FROM cte2
WHERE Rank_order <= 3;


        
