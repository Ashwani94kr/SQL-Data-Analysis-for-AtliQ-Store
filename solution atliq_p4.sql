use gdb023;

show tables;

desc dim_customer;

##  Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT 
    market
FROM
    dim_customer
WHERE
    region = 'APAC'
GROUP BY market;

-- OR

SELECT 
    distinct(market)
FROM
    dim_customer
WHERE
    region = 'APAC';

/* What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */
##############
-- used CTE concept 
##############

With unique_2020 As (SELECT 
    COUNT(DISTINCT product_code) AS unique_product_2020
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020),
unique_2021 As
  (select 
count(distinct product_code) as 
unique_product_2021 from fact_sales_monthly where fiscal_year = 2021)
select
a.unique_product_2020,
b.unique_product_2021,
Round(((b.unique_product_2021-a.unique_product_2020)/a.unique_product_2020*100),2) as Percentage_chg
    from 
unique_2020 as a
    join
unique_2021 as b;


/* Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count */ 

SELECT 
    segment, COUNT(Distinct product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;   

/* Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference */

With Product_2020 As
(SELECT 
    p.segment,
    COUNT(DISTINCT s.product_code) AS product_count_2020
FROM
    dim_product p
        INNER JOIN
    fact_sales_monthly s ON p.product_code = s.product_code
WHERE
    fiscal_year = 2020
GROUP BY segment
ORDER BY product_count_2020 DESC),
Product_2021 As
(SELECT 
    p.segment,
    COUNT(DISTINCT s.product_code) AS product_count_2021
FROM
    dim_product p
        INNER JOIN
    fact_sales_monthly s ON p.product_code = s.product_code
WHERE
    fiscal_year = 2021
GROUP BY segment
ORDER BY product_count_2021 DESC)
SELECT 
    a.segment,
    a.product_count_2020,
    b.product_count_2021,
    (b.product_count_2021 - a.product_count_2020) AS difference
FROM
    product_2020 AS a
        INNER JOIN
    product_2021 AS b ON a.segment = b.segment;

/* Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost */

SELECT 
    p.product, p.product_code, m.manufacturing_cost
FROM
    dim_product p
        INNER JOIN
    fact_manufacturing_cost m ON p.product_code = m.product_code
WHERE
    manufacturing_cost = (SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost) 
UNION SELECT 
    p.product, p.product_code, m.manufacturing_cost
FROM
    dim_product p
        INNER JOIN
    fact_manufacturing_cost m ON p.product_code = m.product_code
WHERE
    manufacturing_cost = (SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost);
			
/* Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage
*/

SELECT 
    c.customer_code,
    c.customer,
    round(AVG(f.pre_invoice_discount_pct)*100,2) AS average_discount_percentage
FROM
    dim_customer c
        INNER JOIN
    fact_pre_invoice_deductions f ON c.customer_code = f.customer_code
WHERE
    fiscal_year = 2021 and market = 'India'
GROUP BY customer_code, customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

/* Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount
*/

SELECT 
    MONTH(m.date) AS month,
    YEAR(m.date) AS year,
    Round(SUM(g.gross_price * m.sold_quantity),2) AS Gross_Sales_Amount
FROM
    fact_sales_monthly m
        INNER JOIN
    fact_gross_price g ON m.product_code = g.product_code
        INNER JOIN
    dim_customer c ON m.customer_code = c.customer_code
WHERE
    customer = 'Atliq Exclusive'
GROUP BY month , year
ORDER BY month;

/* In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity(case statement)
*/

SELECT 
    CASE
        WHEN MONTH(date) IN (9 , 10, 11) THEN 'qtr1'
        WHEN MONTH(date) IN (12 , 1, 2) THEN 'qtr2'
        WHEN MONTH(date) IN (3 , 4, 5) THEN 'qtr3'
        WHEN MONTH(date) IN (6 , 7, 8) THEN 'qtr4'
    END AS Quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC;

/*  Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage
*/

with gross_sale as(
select c.channel,
round(sum(g.gross_price*m.sold_quantity)/1000000,2) as gross_sales_mln
from dim_customer c 
inner join
fact_sales_monthly m on c.customer_code = m.customer_code
inner join
fact_gross_price g on m.product_code = g.product_code
where m.fiscal_year = 2021
group by channel 
order by gross_sales_mln desc)
select *,
gross_sales_mln*100/sum(gross_sales_mln) over() as percentage 
from gross_sale;

/* Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
division
product_code
product
total_sold_quantity
rank_order
*/

with total_sold as 
(select
p.division,p.product_code,p.product,sum(s.sold_quantity) as total_sold_quantity
from 
dim_product p 
join 
fact_sales_monthly s on p.product_code = s.product_code
where fiscal_year = 2021
group by p.division,p.product_code,p.product),

rank_top as (select *, rank() over(partition by division 
order by total_sold_quantity desc) as rnk from total_sold)

select * from rank_top where rnk <=3;



