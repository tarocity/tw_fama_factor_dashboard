/*
===============================================================================
DDL Script: Create gold.fct_factor_data Table
===============================================================================
Script Purpose:
    計算因子,其中 UMD 為重新分組頻率為'月',其餘因子分為'季'或'年'頻率重新分組,
	SMB 因子只計算五因子版本的,三因子就不計算了,
	CMA 因為 INV 與其他變數一樣是從低到高排序,因此 CMA 是 inv1 減去 inv3 的組別,
	避免之後還要寬表轉長表,各因子分開處理,在 UNION ALL 起來
===============================================================================
*/

IF OBJECT_ID('gold.fct_factor_data', 'U') IS NOT NULL
    DROP TABLE gold.fct_factor_data;
GO
CREATE TABLE gold.fct_factor_data	(
	month_date			DATE,
	rebalance			NVARCHAR(30),
	portfolio			NVARCHAR(30),
	portfolio_return	FLOAT,
	dwh_create_date		DATETIME2 DEFAULT GETDATE()
);
GO
TRUNCATE TABLE gold.fct_factor_data;
GO
--------------------------------------------
INSERT INTO gold.fct_factor_data (
			month_date,
			rebalance,
			portfolio,
			portfolio_return
			)

-- UMD
SELECT
	month_date,
	'monthly' AS rebalance,
	'UMD' AS portfolio,
	(
	SUM(CASE WHEN portfolio IN ('s1_mom3','s2_mom3') THEN portfolio_return END) 
	-
	SUM(CASE WHEN portfolio IN ('s1_mom1','s2_mom1') THEN portfolio_return END) 
	) /2 AS portfolio_return
FROM gold.fct_mom_portfolio
GROUP BY month_date

UNION ALL
-- HML_quarterly
SELECT
	month_date,
	'quarterly' AS rebalance,
	'HML' AS portfolio,
	(
	SUM(CASE WHEN portfolio IN ('s1_bm3','s2_bm3') THEN portfolio_return END) 
	-
	SUM(CASE WHEN portfolio IN ('s1_bm1','s2_bm1') THEN portfolio_return END) 
	) /2 AS portfolio_return
FROM gold.fct_factor_portfolio_rebalance_quarterly
GROUP BY month_date

UNION ALL
-- HML_annual
SELECT
	month_date,
	'annual' AS rebalance,
	'HML' AS portfolio,
	(
	SUM(CASE WHEN portfolio IN ('s1_bm3','s2_bm3') THEN portfolio_return END) 
	-
	SUM(CASE WHEN portfolio IN ('s1_bm1','s2_bm1') THEN portfolio_return END) 
	) /2 AS portfolio_return
FROM gold.fct_factor_portfolio_rebalance_annual
GROUP BY month_date

UNION ALL
-- RMW_quarterly
SELECT
	month_date,
	'quarterly' AS rebalance,
	'RMW' AS portfolio,
	(
	SUM(CASE WHEN portfolio IN ('s1_op3','s2_op3') THEN portfolio_return END) 
	-
	SUM(CASE WHEN portfolio IN ('s1_op1','s2_op1') THEN portfolio_return END) 
	) /2 AS portfolio_return
FROM gold.fct_factor_portfolio_rebalance_quarterly
GROUP BY month_date

UNION ALL
-- RMW_annual
SELECT
	month_date,
	'annual' AS rebalance,
	'RMW' AS portfolio,
	(
	SUM(CASE WHEN portfolio IN ('s1_op3','s2_op3') THEN portfolio_return END) 
	-
	SUM(CASE WHEN portfolio IN ('s1_op1','s2_op1') THEN portfolio_return END) 
	) /2 AS portfolio_return
FROM gold.fct_factor_portfolio_rebalance_annual
GROUP BY month_date

UNION ALL
-- CMA_q
SELECT
	month_date,
	'quarterly' AS rebalance,
	'CMA' AS portfolio,
	(
	SUM(CASE WHEN portfolio IN ('s1_inv1','s2_inv1') THEN portfolio_return END) 
	-
	SUM(CASE WHEN portfolio IN ('s1_inv3','s2_inv3') THEN portfolio_return END) 
	) /2 AS portfolio_return
FROM gold.fct_factor_portfolio_rebalance_quarterly
GROUP BY month_date

UNION ALL
-- CMA_y
SELECT
	month_date,
	'annual' AS rebalance,
	'CMA' AS portfolio,
	(
	SUM(CASE WHEN portfolio IN ('s1_inv1','s2_inv1') THEN portfolio_return END) 
	-
	SUM(CASE WHEN portfolio IN ('s1_inv3','s2_inv3') THEN portfolio_return END) 
	) /2 AS portfolio_return
FROM gold.fct_factor_portfolio_rebalance_annual
GROUP BY month_date

UNION ALL
-- SMB_q
SELECT
	month_date,
	'quarterly' AS rebalance,
	'SMB' AS portfolio,
	(
	SUM(CASE WHEN portfolio IN 
	('s1_bm1','s1_bm2','s1_bm3',
	's1_op1','s1_op2','s1_op3',
	's1_inv1','s1_inv2','s1_inv3') THEN portfolio_return END) 
	-
	SUM(CASE WHEN portfolio IN 
	('s2_bm1','s2_bm2','s2_bm3',
	's2_op1','s2_op2','s2_op3',
	's2_inv1','s2_inv2','s2_inv3') THEN portfolio_return END) 
	) / 9 AS portfolio_return
FROM gold.fct_factor_portfolio_rebalance_quarterly
GROUP BY month_date

UNION ALL
-- SMB_y
SELECT
	month_date,
	'annual' AS rebalance,
	'SMB' AS portfolio,
	(
	SUM(CASE WHEN portfolio IN 
	('s1_bm1','s1_bm2','s1_bm3',
	's1_op1','s1_op2','s1_op3',
	's1_inv1','s1_inv2','s1_inv3') THEN portfolio_return END) 
	-
	SUM(CASE WHEN portfolio IN 
	('s2_bm1','s2_bm2','s2_bm3',
	's2_op1','s2_op2','s2_op3',
	's2_inv1','s2_inv2','s2_inv3') THEN portfolio_return END) 
	) / 9 AS portfolio_return
FROM gold.fct_factor_portfolio_rebalance_annual
GROUP BY month_date




