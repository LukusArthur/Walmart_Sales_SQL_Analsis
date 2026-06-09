-- ==========================================
-- WALMART SALES DATA ANALYSIS PORTFOLIO PROJECT
-- ==========================================

-- Initial Data exploration and table checks
SELECT * FROM walmart;


SELECT 
    payment_method,
    COUNT(*)
FROM walmart
GROUP BY payment_method;



--There are some casing errors with branch 
--So change it inside vs code "df.columns.str.lower()"

DROP TABLE walmart_sales;

SELECT MAX(quantity) AS max_quantity FROM walmart_sales;


--Q1. Find Difference Between Payment Method And Transactions Number Of Qty Sold 

SELECT 
    payment_method,
    COUNT(*) as no_of_payments,
    SUM(quantity) AS total_num_of_quantity
FROM walmart
GROUP BY payment_method;


--Q2. Identify the highest-rated category in each branch, displaying the branch, category 
-- AVG rating 
-- Summarize the general rating of the specific category the consumers bought then give it a ranking for each

SELECT *
FROM
(SELECT 
    branch,
    category,
    AVG(rating) AS avg_rating, 
    RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) as Rank
FROM walmart
GROUP BY 1, 2
)
WHERE Rank = 1;


--Q3. Identify the busiest day for each branch based on the number of transactions 
-- First our date column is text column so we converted into a date data type then we only neeed day name so we use 
-- TO_CHAR(date , format, day)
SELECT *
FROM
(    SELECT 
        branch,
        TO_CHAR(TO_DATE(date, 'DD/MM/YY'),'Day') AS day_name,
        COUNT(*) as no_of_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC ) AS Rank
    FROM walmart
    GROUP BY branch, day_name
    
)
WHERE Rank = 1;


--Q4. Calculate the total quantity of items sold per each payment method. list payment method and quantity sold 

SELECT 
    payment_method,
    COUNT(*) AS no_of_transactions,
    SUM(quantity) AS no_of_quantity_sold
FROM walmart
GROUP BY payment_method;


--Q5. Determine the average, minimum , and maximum rating of category for each city

SELECT 
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating) AS avg_rating
FROM walmart
GROUP BY 1,2;


--Q6. Calculate the total profit for each category by considering total_profit as (unit price * quantity * profit_margin)
-- List category and total_profit, order from highest to lowest profit.

SELECT * FROM walmart;

DROP TABLE walmart;

SELECT 
    category,
    SUM(total_amount) AS total_revenue,
    SUM(total_amount * profit_margin) AS profit
FROM walmart
GROUP BY 1
ORDER BY profit DESC;


--Q7. Determine the most common payment method for each branch 
--Diplay each branch and prefered payment_method for each branch

SELECT * FROM walmart;

DROP TABLE walmart_sales;

WITH payment_method_rank AS
    (SELECT 
        branch,
        payment_method,
        COUNT(*) as No_of_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC)  rank
    FROM walmart
    GROUP BY branch, payment_method
)

SELECT * FROM payment_method_rank
WHERE rank = 1;


--Q8. Categorize sales into 3 group MORNING, AFTERNOON, EVENING 
--FIND OUT EACH OF THE SHIFT and NUMBER OF INVOICES

SELECT 
    branch,
CASE
     WHEN EXTRACT(HOUR FROM(time::time)) < 12 THEN 'MORNING'
     WHEN EXTRACT(HOUR FROM(time::time)) BETWEEN 12 AND 17 THEN 'AFTERNOON'
     ELSE 'EVENING'
END time_of_the_day,
    COUNT(*) AS no_of_invoices
FROM walmart
GROUP BY 1,2
ORDER BY 1, 3 DESC;


--Q9: Identify 5 branch with highest decrease ratio in 
-- revenue compared to last_year (current year 2023 and last year 2022)

WITH revenue_2022 AS
(   SELECT 
        branch,
        SUM(total_amount) as total_revenue
    FROM walmart 
    WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022
    GROUP BY 1
),
revenue_2023 AS
(
    SELECT 
        branch,
        SUM(total_amount) AS total_revenue
    FROM walmart
    WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) =2023
    GROUP BY 1
)

-- Firstly we do the CTEs for both 2022 and 2023 to reuse it again to do further aggregation 
-- So we converted our date text data type into date format to nicely came out then we will calculate total revenue for both
-- And then we calculate Revenue decrease ratio then limit it to only 5  branch which drains the profits then last year and decline in sales
-- For revenue decrease ratio - Formula (last_year_revenue - current_year_revenue) / last_year_revenue * 100

SELECT 
    last_year.branch,
    last_year.total_revenue,
    current_year.total_revenue,
    ROUND((last_year.total_revenue - current_year.total_revenue)::numeric /
    last_year.total_revenue::numeric * 100, 2) AS rev_dec_ratio
FROM revenue_2022 AS last_year
JOIN revenue_2023 AS current_year
ON last_year.branch = current_year.branch
WHERE last_year.total_revenue > current_year.total_revenue
ORDER BY rev_dec_ratio DESC
LIMIT 5;
