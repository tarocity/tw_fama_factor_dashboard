/*
===============================================================================
DDL Script: Create gold.fct_market_premium Table
===============================================================================
Script Purpose:
    計算 market_premium, MKT, Rf:
    其中無風險利率:Rf 是年利率,計算 market_premium 時以 Rf/12 去計算,
	避免之後還要寬表轉長表,各資料分開處理,在 UNION ALL 起來,column name 統一為 portfolio
===============================================================================
*/

IF OBJECT_ID('gold.fct_market_premium', 'U') IS NOT NULL
    DROP TABLE gold.fct_market_premium;
GO
CREATE TABLE gold.fct_market_premium	(
	month_date			DATE,
	portfolio			NVARCHAR(30),
	portfolio_return	FLOAT,
	dwh_create_date		DATETIME2 DEFAULT GETDATE()
);
GO
TRUNCATE TABLE gold.fct_market_premium;
GO
----------------------------------------
INSERT INTO gold.fct_market_premium (
			month_date,
			portfolio,
			portfolio_return
		)
SELECT
	t.month_date,
	'mkt_premium' AS portfolio,
	--t.month_return,
	--r.rate,
	t.month_return - r.rate/12 AS portfolio_return
FROM silver.taiex_month_return AS t
LEFT JOIN silver.risk_free_rate AS r
ON t.month_date = r.month_date
WHERE r.rate IS NOT NULL
UNION ALL
SELECT
	month_date,
	'MKT' AS portfolio,
	month_return AS portfolio_return
FROM silver.taiex_month_return 
UNION ALL
SELECT
month_date,
	'Rf' AS portfolio,
	rate AS portfolio_return
FROM silver.risk_free_rate
