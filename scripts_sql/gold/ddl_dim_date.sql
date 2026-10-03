/*
===============================================================================
DDL Script: Create gold.dim_date Table
===============================================================================
Script Purpose:
	根據季財報公布時間,製作與財報日期對應的月報酬日期表,
	第一季（Q1）季報：每年的 5 月 15 日前 公布。
	第二季（Q2）季報（即半年報）：每年的 8 月 14 日前 公布。
	第三季（Q3）季報：每年的 11 月 14 日前 公布。
	第四季（Q4）年報：隔年的 3 月 31 日前 公布。
	依上述財報發布時間,Q1–Q4 季報對應以下月份的月報酬資料
	財報季度: 報酬月份
	Y(t)-Q1: Y(t)- 6,7,8 
	Y(t)-Q2: Y(t)- 9,10,11
	Y(t)-Q3: Y(t)- 12, Y(t+1)- 1,2,3
	Y(t)-Q4: Y(t+1)- 4,5
	-----------------------------------------------------
	如果以年財報資料做分組依據,t 年年財報在 t+1 年 03-31 公布,
	因此每年以 4 月使用新財報資料重新分組,
	t 年財報對應 t+1 年 4 月至 t+2 年 3 月之月報酬資料,
	即 t 年 1 至 3 月月報酬使用 t-2 年財報, t 年 4 月至 12 月使用 t-1 年財報
===============================================================================
*/
--
-- financial_statement
IF OBJECT_ID('gold.dim_date', 'U') IS NOT NULL
    DROP TABLE gold.dim_date;
GO
CREATE TABLE gold.dim_date	(
	month_date				DATE,
	report_date_by_quarter	DATE,
	report_date_by_year		DATE,
	dwh_create_date			DATETIME2 DEFAULT GETDATE()
);
GO

TRUNCATE TABLE gold.dim_date;
GO
-----------------------------------------------
WITH cte_month_date AS (
SELECT 
    CAST(DATEADD(MONTH, value, '2000-01-01') AS DATE) month_date
FROM GENERATE_SERIES(0, DATEDIFF(MONTH, '2000-01-01', '2030-12-01'))
),
cte_report_date AS (
SELECT 
	month_date,
	CASE 
		WHEN MONTH(month_date) IN (6,7,8)	THEN CAST(LEFT(month_date,5) + '03-01' AS DATE)
		WHEN MONTH(month_date) IN (9,10,11) THEN CAST(LEFT(month_date,5) + '06-01' AS DATE)
		WHEN MONTH(month_date) IN (12)		THEN CAST(LEFT(month_date,5) + '09-01' AS DATE)
		WHEN MONTH(month_date) IN (1,2,3)	THEN DATEADD(YEAR, -1, CAST(LEFT(month_date,5) + '09-01' AS DATE))
		WHEN MONTH(month_date) IN (4,5)		THEN DATEADD(YEAR, -1, CAST(LEFT(month_date,5) + '12-01' AS DATE))
	END AS report_date_by_quarter,
	CASE 
		WHEN MONTH(month_date) IN (4,5,6,7,8,9,10,11,12) 
		THEN DATEADD(YEAR, -1, CAST(LEFT(month_date,5) + '12-01' AS DATE))
		WHEN MONTH(month_date) IN (1,2,3) 
		THEN DATEADD(YEAR, -2, CAST(LEFT(month_date,5) + '12-01' AS DATE))
	END AS report_date_by_year
FROM cte_month_date
)

INSERT INTO gold.dim_date (
			month_date,
			report_date_by_quarter,
			report_date_by_year
		)
SELECT
*
FROM cte_report_date







