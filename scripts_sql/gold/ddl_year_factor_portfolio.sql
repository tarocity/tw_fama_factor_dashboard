/*
===============================================================================
DDL Script: Create gold.fct_factor_portfolio_rebalance_annual Table
===============================================================================
Script Purpose:
	資料起點是 balance sheet 的 2012-03 財報, cash_flows: InterestExpense 起點也是 2012-03
	月報酬期開始於 2013-04(inv投組始於2014-04),月報酬日期結束於 2026-05, 
	調整股價資料抓到2026-06-18, 最後去掉 2026-06 的資料
	----------------------------------------------
	計算 Fama factor portfolios: HML, RMW, CMA
	1. cte_financial_year :
	把季財報轉成年財報,balance 取12月的資料, 
	income 和 cash_flows 依照 公司,年份,項目 把 item_value加總
	↓
	2. cte_pivot_financial :
	把年報從長表轉寬表,方便後續計算 factor variable 
	↓
	3. cte_factor_variable :
	根據 report_date JOIN (12月底)市值後計算 factor variable (bm, op, inv) 
	↓
	4. cte_sort_variable :
	排序 factor variable, 把個股分類進因子的排序分組中,排序前把金融業與興櫃公司排除掉
	↓
	5. cte_factor_group :
	把各因子排序與市值排序合併 g_mv  g_bm  g_op  g_inv 
	↓
	6. cte_value_weighted_group :
	最後根據因子分組, 計算個股在所屬組別中的市值占比, 用於後續計算市值加權投組報酬率
	↓
	7. cte_join_return :
	cte 先合併 gold.dim_date, 再依照 gold.dim_date 的日期合併 stock_month_return
	↓
	8. gold.fct_factor_portfolio_rebalance_annual :
	最後根據每個日期與該因子分組, 把所有個股的市值佔比*月報酬後 再加總, 完成計算因子投組的 市值加權報酬
===============================================================================
*/
IF OBJECT_ID('gold.fct_factor_portfolio_rebalance_annual', 'U') IS NOT NULL
	DROP TABLE gold.fct_factor_portfolio_rebalance_annual;
GO
CREATE TABLE gold.fct_factor_portfolio_rebalance_annual	(
	month_date			DATE,
	portfolio			NVARCHAR(30),
	portfolio_return	FLOAT,
	dwh_create_date		DATETIME2 DEFAULT GETDATE()
);
GO
TRUNCATE TABLE gold.fct_factor_portfolio_rebalance_annual;
GO
-----------------------------------------------
--1. cte_financial_year :
--先把季財報轉成年財報,balance 取12月的資料, income和 cash_flows依照公司,年份,項目 把 item_value加總
WITH cte_financial_year AS (
SELECT
	stock_id,
	report_date,
	item,
	item_value
FROM silver.financial_statement
WHERE statement_type = 'balance' AND MONTH(report_date) = 12
UNION ALL
SELECT
	stock_id,
	CAST(YEAR(report_date) AS VARCHAR) + '-12-01' AS report_date,
	item,
	SUM(item_value) AS item_value
FROM silver.financial_statement
WHERE statement_type IN ('income','cash_flows') 
GROUP BY stock_id, YEAR(report_date), item
--UNION ALL
--SELECT
--	stock_id,
--	CAST(YEAR(report_date) AS VARCHAR) + '-12-01' report_date,
--	item,
--	SUM(item_value) item_value
--FROM silver.financial_statement
--WHERE statement_type = 'cash_flows' 
--GROUP BY stock_id, YEAR(report_date), item
),
-----------------------------------------------
--2. cte_pivot_financial :
--先把年報從長表轉寬表,用於計算 factor variable 
cte_pivot_financial AS (
SELECT *
	FROM (
		SELECT 
			report_date,
			stock_id,
			item,
			item_value
		FROM cte_financial_year
	) t 
	PIVOT (
		-- 選擇欄位
		MAX(t.item_value)
		-- 設定橫轉直 轉置欄位，只能用[]，不能用單引號''
		FOR item IN (TotalAssets,OperatingExpenses,Equity,CostOfGoodsSold,Revenue,InterestExpense)
	) p	WHERE report_date > '2012-01-01'
),
------------------------------------
--3. cte_factor_variable :
--根據 report_date JOIN (12月底)市值後計算 factor variable (bm, op, inv) 
cte_factor_variable AS (
SELECT
	f.report_date,
	f.stock_id,
	m.market_value AS mv,
	f.Equity / m.market_value AS bm,
	(f.TotalAssets/LAG(f.TotalAssets) OVER (PARTITION BY f.stock_id ORDER BY f.report_date)) -1 AS inv,
	--(f.Revenue - f.CostOfGoodsSold - f.OperatingExpenses - isnull(f.InterestExpense,0)) / f.Equity AS op
	(f.Revenue - f.CostOfGoodsSold - f.OperatingExpenses - f.InterestExpense) / f.Equity AS op
FROM cte_pivot_financial AS f
LEFT JOIN silver.month_market_value AS m
ON f.report_date = m.month_date AND f.stock_id = m.stock_id
WHERE f.TotalAssets > 0 AND m.market_value > 0
),
------------------------------------
--4. cte_sort_variable
--排序 factor variable, 把個股分類進因子的排序分組中,排序前把金融業與興櫃公司排除掉
cte_sort_variable AS (
SELECT
	*,
	CASE
		WHEN mv <   PERCENTILE_CONT (0.5) WITHIN GROUP (ORDER BY mv) OVER (PARTITION BY report_date) THEN 's1'
		WHEN mv >=  PERCENTILE_CONT (0.5) WITHIN GROUP (ORDER BY mv) OVER (PARTITION BY report_date) THEN 's2'
		ELSE 'NA' 
	END AS g_mv,
	CASE
		WHEN bm <  PERCENTILE_CONT (0.3) WITHIN GROUP (ORDER BY bm) OVER (PARTITION BY report_date) THEN 'bm1'
		WHEN bm <  PERCENTILE_CONT (0.7) WITHIN GROUP (ORDER BY bm) OVER (PARTITION BY report_date) THEN 'bm2'
		WHEN bm >= PERCENTILE_CONT (0.7) WITHIN GROUP (ORDER BY bm) OVER (PARTITION BY report_date) THEN 'bm3'
		ELSE 'NA' 
	END AS g_bm,
	CASE
		WHEN op <  PERCENTILE_CONT (0.3) WITHIN GROUP (ORDER BY op) OVER (PARTITION BY report_date) THEN 'op1'
		WHEN op <  PERCENTILE_CONT (0.7) WITHIN GROUP (ORDER BY op) OVER (PARTITION BY report_date) THEN 'op2'
		WHEN op >= PERCENTILE_CONT (0.7) WITHIN GROUP (ORDER BY op) OVER (PARTITION BY report_date) THEN 'op3'
		ELSE 'NA' 
	END AS g_op,
	CASE
		WHEN inv <  PERCENTILE_CONT (0.3) WITHIN GROUP (ORDER BY inv) OVER (PARTITION BY report_date) THEN 'inv1'
		WHEN inv <  PERCENTILE_CONT (0.7) WITHIN GROUP (ORDER BY inv) OVER (PARTITION BY report_date) THEN 'inv2'
		WHEN inv >= PERCENTILE_CONT (0.7) WITHIN GROUP (ORDER BY inv) OVER (PARTITION BY report_date) THEN 'inv3'
		ELSE 'NA' 
	END AS g_inv
FROM cte_factor_variable AS cte
WHERE EXISTS (
	SELECT
		1	
	FROM silver.company_industry AS ci
	WHERE 
	industry_category NOT IN ('金融保險業','金融業') AND
	market != 'emerging' AND
	ci.company_id = cte.stock_id 
)
),
------------------------------------
--5. cte_factor_group
--把各因子排序與市值排序合併 g_mv  g_bm  g_op  g_inv 
cte_factor_group AS (
SELECT
	report_date,
	stock_id,
	mv,
	g_mv +'_'+ g_bm AS  g_HML,
	g_mv +'_'+ g_op AS  g_RMW,
	g_mv +'_'+ g_inv AS g_CMA
FROM cte_sort_variable
),
------------------------------------
--6. cte_value_weighted_group
--最後根據因子分組, 計算個股在所屬組別中的市值占比, 用於後續計算市值加權投組報酬率
cte_value_weighted_group AS (
SELECT
	report_date,
	stock_id,
	g_HML,
	g_RMW,
	g_CMA,
	CAST(mv AS FLOAT) / SUM(mv) OVER (PARTITION BY report_date, g_HML) AS HML_ratio,
	CAST(mv AS FLOAT) / SUM(mv) OVER (PARTITION BY report_date, g_RMW) AS RMW_ratio,
	CAST(mv AS FLOAT) / SUM(mv) OVER (PARTITION BY report_date, g_CMA) AS CMA_ratio
FROM cte_factor_group
),
------------------------------------
--7. cte_join_return :
--cte 先合併 gold.dim_date, 再依照 gold.dim_date 的日期合併 stock_month_return
--讓財報日期 report_date 可以依照報酬日期 month_date 合併月報酬
cte_join_return AS(
SELECT
	vw.report_date,
	dd.month_date,
	vw.stock_id,
	vw.g_HML,
	vw.g_RMW,
	vw.g_CMA,
	vw.HML_ratio,
	vw.RMW_ratio,
	vw.CMA_ratio,
	mr.month_return
FROM cte_value_weighted_group AS vw                          
LEFT JOIN gold.dim_date AS dd
ON dd.report_date_by_year = vw.report_date
LEFT JOIN silver.stock_month_return AS mr
ON vw.stock_id = mr.stock_id AND dd.month_date = mr.month_date
WHERE mr.month_return IS NOT NULL
)
------------------------------------
--8. gold.fct_factor_portfolio_rebalance_annual
--最後根據每個日期與該因子分組, 把所有個股的市值佔比*月報酬後 再加總, 完成計算因子投組的 市值加權報酬
--避免之後還要寬表轉長表,各因子投組分開處理,在 UNION ALL 起來,各因子分組 column name 統一為 portfolio
INSERT INTO gold.fct_factor_portfolio_rebalance_annual (
			month_date,
			portfolio,
			portfolio_return
		)

SELECT * FROM (
SELECT
	month_date,
	g_HML AS portfolio,
	SUM(month_return * HML_ratio) AS portfolio_return
FROM cte_join_return
GROUP BY month_date, g_HML
UNION ALL
SELECT
	month_date,
	g_RMW AS portfolio,
	SUM(month_return * RMW_ratio) AS portfolio_return
FROM cte_join_return
GROUP BY month_date, g_RMW
UNION ALL
SELECT
	month_date,
	g_CMA AS portfolio,
	SUM(month_return * CMA_ratio) AS portfolio_return
FROM cte_join_return
GROUP BY month_date, g_CMA
) t WHERE portfolio NOT LIKE '%NA%' AND month_date <= '2026-05-01'













