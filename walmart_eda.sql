---- Create and use database----
--------------------------------

create database walmart;
use walmart;

---- Create table in walmart database ----
------------------------------------------

CREATE TABLE IF NOT EXISTS sales(
	invoice_id VARCHAR(30) PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT NOT NULL,
    total DECIMAL NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL NOT NULL,
    gross_margin_pct FLOAT,
    gross_income DECIMAL,
    rating FLOAT
);


----Data------------
--------------------

select * from sales


----Feature Engineering--------------------------------------------------
-------------------------------------------------------------------------

-- Add column 'time_of_day' -----------
---------------------------------------

select time, (
case
	when time between '00:00:00' and '12:00:00' then 'Morning'
    when time between '12:01:00' and '16:00:00' then 'Afternoon'
    else 'Evening'
    end
) as time_of_day from sales

alter table sales
add column time_of_day varchar(50);

update sales
set time_of_day = (case
	when time between '00:00:00' and '12:00:00' then 'Morning'
    when time between '12:01:00' and '16:00:00' then 'Afternoon'
    else 'Evening'
    end);
    
-- Add column 'day_name' --------------
---------------------------------------

alter table sales
add column day_name varchar(50);

select date, dayname(date) from sales;

update sales
set day_name = (dayname(date));

-- Add column 'month_name' --------------
-----------------------------------------

alter table sales
add column month_name varchar(50);

select date, monthname(date) from sales;

update sales
set month_name = monthname(date);



-- Exploratory Analysis ----------------------------------------------
----------------------------------------------------------------------

-- >> How many Unique city ?

select distinct(city) from sales;

-- >> In which city how many branch ?

select city, count(branch) as branch_count from sales
group by city;


------------- Product ---------------------
-------------------------------------------

-- >> How many unique product ?

select count(distinct(product_line)) as unique_product from sales;


-- >> What is the most selling product line ?

select product_line, count(product_line) as count from sales
group by product_line
order by count desc;


-- >> What product line had the largest revenue?

select product_line, sum(total) as sales from sales
group by product_line
order by sales desc
limit 1;


-- >> What product line had the largest VAT?

select product_line, max(tax_pct) as vat from sales
group by product_line
order by vat desc
limit 1;


-- >> Fetch each product line and add a column to those product line
-- showing "Good", "Bad". Good if its greater than average sales

select product_line,case 
when avg_sale >= (select ROUND(AVG(total), 2) from sales) then 'Good'
else 'Bad'
end as performance
from (select product_line,round(avg(total), 2) as avg_sale
from sales
group by product_line
) as subquery;


-- >> Which branch sold more products than average product sold?

WITH qnt1 AS (
	SELECT branch, SUM(quantity) as qnt 
	FROM sales
	GROUP BY branch 
)
SELECT branch, SUM(quantity) as qnt FROM sales
GROUP BY branch
HAVING SUM(quantity) > (SELECT AVG(qnt) FROM qnt1)


-- >> What is the most common product line by gender?

SELECT gender, product_line, count(gender) as count from sales
group by gender, product_line
order by gender desc;


-- >> What is the average rating of each product line?

SELECT product_line, ROUND(AVG(rating),2) AS avg_rating FROM sales
GROUP BY product_line;


------------- Sales -----------------------
-------------------------------------------

-- >> What is the most common payment method ?

select payment, count(payment) as count from sales
group by payment
order by count desc
limit 1;


-- >> What is the total revenue by month ?

select month_name, sum(total) as sales from sales
group by month_name;


-- >> What month had the largest COGS?

select month_name, sum(cogs) as total_cogs from sales
group by month_name;


-- >> Number of sales made in each time of the day per weekday ?

SELECT day_name, COUNT(invoice_id) as total_invoice, SUM(total) as sale FROM sales
GROUP BY day_name;


-- >> What is the city with the largest revenue?

select city, sum(total) as sale from sales
group by city
order by sale desc
limit 1;


-- >> Which city has the largest tax percent/ VAT (Value Added Tax)?

SELECT city, Max(tax_pct) as vat FROM sales
GROUP BY city
ORDER BY vat desc;


------------- Customer ---------------------
--------------------------------------------

-- >> How many unique customer types does the data have?

SELECT distinct(customer_type) from sales;


-- >> What is the most common customer type?

SELECT 
	customer_type, count(customer_type) as count
from sales
group by customer_type
order by count desc;


-- >> Which customer type buys the most?

SELECT
	customer_type, count(invoice_id) as count
from sales
group by customer_type
order by count desc;


-- >> What is the gender of most of the customers?

SELECT 
	gender, COUNT(gender) as count
FROM
	sales
GROUP BY gender
ORDER BY count DESC;


-- >> What is the gender distribution per branch?

SELECT branch, 
       SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) as male_count,
       SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) as female_count
FROM sales
GROUP BY branch;


-- >> Which of the customer types brings the most revenue?

SELECT
	customer_type, SUM(total) as total 
FROM 
	sales
group by customer_type
order by total desc
LIMIT 1;


-- >> Which customer type pays the most in VAT?

SELECT
	customer_type, Max(tax_pct) as vat
FROM
	sales
GROUP BY customer_type
ORDER BY vat desc;


-- >> Which time of the day do customers give most ratings?

SELECT 
	time_of_day, COUNT(rating) AS count
FROM
	sales
GROUP BY time_of_day
ORDER BY count DESC;


-- >> Which time of the day do customers give most ratings per branch?

WITH rating_counts AS (
    SELECT branch, time_of_day, COUNT(rating) as count,
    RANK() OVER(PARTITION BY branch order by count(rating) desc) as ranking
    FROM sales
    GROUP BY branch, time_of_day
)

select branch, time_of_day from rating_counts
where ranking = 1;


-- >> Which day of the week has the best avg ratings?

SELECT day_name, ROUND(AVG(rating),2) as avg_rat
FROM sales
GROUP BY day_name
ORDER BY  avg_rat DESC;


-- >> Which day of the week has the best average ratings per branch?

WITH avgdf as 
(SELECT branch, day_name, ROUND(AVG(rating),2) as avg_rat,
RANK() OVER(PARTITION BY branch ORDER BY  ROUND(AVG(rating),2) DESC) AS avg_rank
FROM sales
GROUP BY branch, day_name)

SELECT branch, day_name, avg_rat from avgdf
WHERE avg_rank = 1;

