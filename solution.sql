use credit_card;

-- show tables;
SELECT * FROM `credit card transactions - india - simple` LIMIT 0, 1000;
-- 1-write a query to print top 5 cities with highest spends 

WITH total_spent AS (
    SELECT SUM(Amount) AS total_amount
    FROM `credit card transactions - india - simple`
),
city_spends AS (
    SELECT 
        City,
        SUM(Amount) AS total_spend
    FROM 
        `credit card transactions - india - simple`
    GROUP BY 
        City
)
SELECT 
    cs.City, 
    cs.total_spend, 
    ROUND((cs.total_spend / ts.total_amount) * 100, 2) AS percentage_contribution
FROM 
    city_spends cs, 
    total_spent ts
ORDER BY 
    cs.total_spend DESC
LIMIT 5;
-- another approach
SELECT 
    City,
    SUM(Amount) AS Total_Spend,
    ROUND((SUM(Amount) / (SELECT SUM(Amount) * 1.0 FROM `credit card transactions - india - simple`)) * 100, 2) AS Percentage_Contribution
FROM 
    `credit card transactions - india - simple`
GROUP BY 
    City
ORDER BY 
    Total_Spend DESC
LIMIT 5;
-- 2- write a query to print highest spend month and amount spent in that month for each card type

-- Step 1: Create a subquery to calculate total monthly spending per card type
-- Step 1: Create a CTE to calculate total monthly spending per card type
WITH MonthlySpending AS (
    SELECT 
        `Card Type`,
        DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%Y'), '%m') AS MonthYear,
        SUM(Amount) AS TotalAmount
    FROM 
        `credit card transactions - india - simple`
    GROUP BY 
        `Card Type`, MonthYear
),
-- Step 2: Find the maximum monthly spending for each card type
MaxMonthlySpending AS (
    SELECT 
        `Card Type`,
        MAX(TotalAmount) AS MaxAmount
    FROM 
        MonthlySpending
    GROUP BY 
        `Card Type`
)
-- Step 3: Join the results to get the month and amount
SELECT 
    m.`Card Type`,
    m.MonthYear AS HighestSpendMonth,
    m.TotalAmount AS AmountSpent
FROM 
    MonthlySpending m
JOIN 
    MaxMonthlySpending mm
ON 
    m.`Card Type` = mm.`Card Type` AND m.TotalAmount = mm.MaxAmount;
-- 3 - write a query to print the transaction details(all columns from the table) for each card type when
-- it reaches a cumulative of  1,000,000 total spends(We should have 4 rows in the o/p one for each card type)
WITH CumulativeSpending AS (
    SELECT 
        `index`,
        City,
        Date,
        `Card Type`,
        `Exp Type`,
        Gender,
        Amount,
        SUM(Amount) OVER (PARTITION BY `Card Type` ORDER BY STR_TO_DATE(Date, '%d-%m-%Y')) AS CumulativeTotal,
        ROW_NUMBER() OVER (PARTITION BY `Card Type` ORDER BY STR_TO_DATE(Date, '%d-%m-%Y')) AS RowNum
    FROM 
        `credit card transactions - india - simple`
)
SELECT 
    `index`,
    City,
    Date,
    `Card Type`,
    `Exp Type`,
    Gender,
    Amount,
    CumulativeTotal
FROM 
    CumulativeSpending
WHERE 
    CumulativeTotal >= 1000000
    AND RowNum = 1
ORDER BY 
    `Card Type`;
-- 4- write a query to find city which had lowest percentage spend for gold card type
use credit_card;
WITH card_type AS (
    SELECT 
        city, 
        SUM(amount) AS total_sum,
        `Card Type`
    FROM  
        `credit card transactions - india - simple`
    GROUP BY 
        `Card Type`, city
)
SELECT 
    ROUND(total_sum / (SELECT SUM(amount) FROM `credit card transactions - india - simple` WHERE `Card Type` = 'Gold') * 100, 2) AS percentage,
    city,
    `Card Type`
FROM  
    card_type
WHERE 
    `Card Type` = 'Gold'
GROUP BY 
    city, `Card Type`
    order by city 
    limit 1;
-- 5- write a query to find percentage contribution of spends by females for each expense type

SELECT 
    `Exp Type`,
    SUM(CASE WHEN Gender = 'F' THEN Amount ELSE 0 END) * 1.0 / SUM(Amount) AS Percentage_Female_Contribution
FROM 
    `credit card transactions - india - simple`
GROUP BY 
    `Exp Type`
ORDER BY 
    Percentage_Female_Contribution DESC;
    -- 6- which city took least number of days to reach its
-- 500th transaction after the first transaction in that city;
WITH cte AS (
    SELECT 
        `index`,
        City,
        Date,
        STR_TO_DATE(Date, '%d-%m-%Y') AS ConvertedDate,
        ROW_NUMBER() OVER (PARTITION BY City ORDER BY STR_TO_DATE(Date, '%d-%m-%Y')) AS rn
    FROM 
        `credit card transactions - india - simple`
)
SELECT 
    City, 
    MIN(ConvertedDate) AS FirstTransactionDate, 
    MAX(ConvertedDate) AS FiveHundredthTransactionDate,
    DATEDIFF(MAX(ConvertedDate), MIN(ConvertedDate)) AS days_difference
FROM 
    cte
WHERE 
    rn = 1 OR rn = 500
GROUP BY 
    City
HAVING 
    COUNT(*) = 2
ORDER BY 
    days_difference
LIMIT 1;

-- 7  which card and expense type combination saw highest month over month growth in Jan-2014
WITH cte AS (
    SELECT 
        `Card Type`,
        `Exp Type`,
        YEAR(STR_TO_DATE(Date, '%d-%m-%Y')) AS yt,
        MONTH(STR_TO_DATE(Date, '%d-%m-%Y')) AS mt,
        SUM(Amount) AS total_spend
    FROM 
        `credit card transactions - india - simple`
    GROUP BY 
        `Card Type`, 
        `Exp Type`, 
        YEAR(STR_TO_DATE(Date, '%d-%m-%Y')), 
        MONTH(STR_TO_DATE(Date, '%d-%m-%Y'))
),
cte_with_lag AS (
    SELECT 
        `Card Type`,
        `Exp Type`,
        yt,
        mt,
        total_spend,
        LAG(total_spend, 1) OVER (PARTITION BY `Card Type`, `Exp Type` ORDER BY yt, mt) AS prev_month_spend
    FROM 
        cte
)
SELECT 
    `Card Type`,
    `Exp Type`,
    yt,
    mt,
    total_spend,
    prev_month_spend,
    (total_spend - prev_month_spend) AS mom_growth
FROM 
    cte_with_lag
WHERE 
    prev_month_spend IS NOT NULL 
    AND total_spend IS NOT NULL 
    AND yt = 2014 
    AND mt = 1
ORDER BY 
    mom_growth DESC
LIMIT 1;
