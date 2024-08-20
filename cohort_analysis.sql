-- create a view looking at just the sales invoice where customer ID is available

CREATE VIEW sales_invoice AS
(SELECT *
FROM invoice
WHERE NOT (
      customer_id IS NULL
      OR invoice LIKE 'C%'
      OR quantity < 0
)
)

--Find the cohort
SELECT customer_id,
       MIN(DATE_TRUNC('month',invoice_dt))::date AS start_month
INTO cohort_data
FROM sales_invoice
GROUP BY customer_id;

--Find out how many customers are gained each month
    SELECT start_month,
        COUNT(customer_id)
    FROM cohort_data
    GROUP BY start_month
    ORDER BY start_month

-- where are most of their customers based in

WITH total_customers AS (
    SELECT SUM(COUNT(DISTINCT sales_invoice.customer_id)) OVER () AS total_customers
    FROM sales_invoice
)
SELECT 
    COUNT(DISTINCT sales_invoice.customer_id) AS customer_count,
    ROUND(COUNT(DISTINCT sales_invoice.customer_id) / total_customers.total_customers,4) AS percentage,
    country
FROM 
    sales_invoice,
    total_customers
GROUP BY 
    country, total_customers.total_customers
ORDER BY 
    customer_count DESC
LIMIT 3;

--Look at retention rate per month

WITH cohort_activity AS (
    SELECT 
        cohort_data.start_month AS start_month,
        DATE_TRUNC('month', sales_invoice.invoice_dt)::date AS activity_month,
        COUNT(DISTINCT sales_invoice.customer_id)::NUMERIC AS active_user
    FROM cohort_data
    JOIN sales_invoice
        ON cohort_data.customer_id = sales_invoice.customer_id
    GROUP BY cohort_data.start_month, activity_month
),
cohort_size AS (
    SELECT 
        start_month,
        COUNT(DISTINCT customer_id) AS total_user
    FROM cohort_data
    GROUP BY start_month
)
SELECT 
    cohort_activity.start_month,
    cohort_activity.activity_month,
    (EXTRACT(YEAR FROM AGE(cohort_activity.activity_month,cohort_activity.start_month))*12 +
    EXTRACT(MONTH FROM AGE(cohort_activity.activity_month, cohort_activity.start_month)))::INT AS num_of_months,
    cohort_activity.active_user,
    ROUND((cohort_activity.active_user / cohort_size.total_user),2) AS retention_rate
INTO cohort_active_user
FROM cohort_activity
JOIN cohort_size
    ON cohort_activity.start_month = cohort_size.start_month
ORDER BY cohort_activity.start_month, cohort_activity.activity_month;

-- Look into the percentage of revenue from each cohort

WITH cohort_revenue AS (
    SELECT 
        cohort_data.start_month AS start_month,
        DATE_TRUNC('month', sales_invoice.invoice_dt)::date AS activity_month,
        SUM(sales_invoice.quantity * sales_invoice.price)::NUMERIC AS revenue
    FROM cohort_data
    JOIN sales_invoice
        ON cohort_data.customer_id = sales_invoice.customer_id
    GROUP BY cohort_data.start_month, activity_month
    ORDER BY cohort_data.start_month, activity_month
    
),

total_monthly_revenue AS (
    SELECT 
        activity_month,
        SUM(revenue) AS total
    FROM cohort_revenue
    GROUP BY activity_month
    
) 

SELECT 
    cohort_revenue.start_month,
    cohort_revenue.activity_month,
    (EXTRACT(YEAR FROM AGE(cohort_revenue.activity_month,cohort_revenue.start_month))*12 +
    EXTRACT(MONTH FROM AGE(cohort_revenue.activity_month, cohort_revenue.start_month)))::INT AS num_of_months,
    ROUND((cohort_revenue.revenue/total_monthly_revenue.total),2) AS revenue_percent
FROM cohort_revenue
JOIN total_monthly_revenue
    ON cohort_revenue.activity_month = total_monthly_revenue.activity_month
ORDER BY cohort_revenue.start_month, cohort_revenue.activity_month;


-- Look into the ave spending for each cohort and how many percentage of total sales it made up

WITH cohort_spending AS (
    SELECT 
        cohort_data.start_month AS start_month,
        DATE_TRUNC('month', sales_invoice.invoice_dt)::date AS activity_month,
        SUM(sales_invoice.quantity * sales_invoice.price)::NUMERIC AS spending
    FROM cohort_data
    JOIN sales_invoice
        ON cohort_data.customer_id = sales_invoice.customer_id
    GROUP BY cohort_data.start_month, activity_month
    
),

cohort_total_spending AS (
    SELECT 
        activity_month,
        SUM(spending) AS total_spending
    FROM cohort_spending
    GROUP BY activity_month
) 

SELECT 
    cohort_spending.start_month,
    cohort_spending.activity_month,
    (EXTRACT(YEAR FROM AGE(cohort_spending.activity_month,cohort_spending.start_month))*12 +
    EXTRACT(MONTH FROM AGE(cohort_spending.activity_month, cohort_spending.start_month)))::INT AS num_of_months,
    ROUND((cohort_spending.spending/cohort_active_user.active_user),2) AS average_spending,
    ROUND((cohort_spending.spending/cohort_total_spending.total_spending),2) AS purchase_percent
FROM cohort_spending
JOIN cohort_total_spending
      ON cohort_spending.activity_month = cohort_total_spending.activity_month
JOIN cohort_active_user
      ON cohort_spending.activity_month = cohort_active_user.activity_month
      AND cohort_spending.start_month = cohort_active_user.start_month
ORDER BY cohort_spending.start_month, cohort_spending.activity_month;

 --Looking into why the spending went up in May 2011

WITH this AS(
    SELECT 
        sales_invoice.*,
        quantity*price AS total
    FROM cohort_data
    JOIN sales_invoice
        ON cohort_data.customer_id = sales_invoice.customer_id
    WHERE cohort_data.start_month = '2011-05-01' AND
          sales_invoice.invoice_dt >= '2011-12-01'

)

SELECT customer_id, SUM(total), SUM(total)/SUM(SUM(total)) OVER () as total_ratio
FROM this
GROUP BY customer_id
ORDER BY total_ratio

-- Looking into what the highest purchase was made
    SELECT 
        sales_invoice.customer_id,
        sales_invoice.quantity,
        sales_invoice.price,
        quantity*price AS total,
        country

    FROM cohort_data
    JOIN sales_invoice
        ON cohort_data.customer_id = sales_invoice.customer_id
    WHERE cohort_data.start_month = '2011-05-01' AND
          sales_invoice.invoice_dt >= '2011-12-01' AND
          sales_invoice.customer_id = '16446'
    










