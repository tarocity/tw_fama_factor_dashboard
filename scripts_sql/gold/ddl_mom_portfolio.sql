/*
===============================================================================
DDL Script: Create gold.fct_mom_portfolio Table
===============================================================================
Script Purpose:
    調整股價資料抓到2026-06-18, 最後去掉 2026-06 的資料
    ----------------------------------------------
    計算 MOM portfolios
    1. cte_cumu_return :
    先計算個股的累積報酬率- mom, 依照定義: t月的 mom 為 t-12 ~ t-2 共 11個月的累積報酬率
    ↓
    2. cte_mom_mv :
    JOIN 月市值再把月市值 lag 1個月, 用於後續計算市值加權
    ↓
    3. cte_mom_group :
    每個月根據 cumu_return & lag_mv 排序,把公司分類進 MOM 的分組中,排序前把金融業與興櫃公司排除掉
    ↓
    4. cte_mom_vw_ratio :
    把個股市值除以同組市值加總, 計算個股市值占比
    ↓
    5. cte_mom_portfolio :
    個股市值占比*個股月報酬, 計算出 mom 投組月報酬
===============================================================================
*/

IF OBJECT_ID('gold.fct_mom_portfolio', 'U') IS NOT NULL
    DROP TABLE gold.fct_mom_portfolio;
GO
CREATE TABLE gold.fct_mom_portfolio	(
	month_date          DATE,
	portfolio           NVARCHAR(30),
	portfolio_return    FLOAT,
	dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO
TRUNCATE TABLE gold.fct_mom_portfolio;
GO
-----------------------------------------------
--1. cte_cumu_return :
--先計算個股的累積報酬率- mom, 依照定義: t月的 mom 為 t-12 ~ t-2 共 11個月的累積報酬率
WITH cte_cumu_return AS (
SELECT
    month_date,
    stock_id,
    month_return,
    CASE 
        WHEN COUNT(month_return + 1) OVER (
            PARTITION BY stock_id 
            ORDER BY month_date
            ROWS BETWEEN 12 PRECEDING AND 2 PRECEDING
        ) = 11
        THEN PRODUCT(month_return + 1) OVER (
            PARTITION BY stock_id 
            ORDER BY month_date
            ROWS BETWEEN 12 PRECEDING AND 2 PRECEDING
        )
    END AS mom
    --或者透過 ln 再 sum 最後再 exp 達到連乘的效果, 但 exp 不是 window function 所以需要套 cte 後再 exp  
    --SUM(LOG(month_return +1)) OVER (PARTITION BY stock_id ORDER BY month_date
	--ROWS BETWEEN 12 PRECEDING AND 2 PRECEDING) mom_to_exp
FROM silver.stock_month_return
),
-----------------------------------------------
--2. cte_mom_mv :
--JOIN 月市值再把月市值 lag 1個月, 用於後續計算市值加權
cte_mom_mv AS (
SELECT
    mm.month_date,
    mm.stock_id,
    mm.month_return,
    mm.mom,
    --mv.market_value,
    LAG(mv.market_value,1) OVER (PARTITION BY mm.stock_id ORDER BY mm.month_date) AS lag_mv
FROM cte_cumu_return AS mm
LEFT JOIN silver.month_market_value AS mv
ON mm.stock_id = mv.stock_id AND mm.month_date = mv.month_date
--WHERE mom IS NOT NULL 
),
-----------------------------------------------
--3. cte_mom_group :
--每個月根據 mom & lag_mv 排序,把公司分類進 MOM 的分組中,排序前把金融業與興櫃公司排除掉
--只有計算 UMD 投組, 直接把 lag_mv 和 mom 排序組在一起,不用多一個 cte
--如果 lag_mv 和 mom 有一個值 NULL, 直接分進 NA 組別
cte_mom_group AS (
SELECT 
    month_date,
    stock_id,
    month_return,
    --mom,
    lag_mv,
    (
    CASE
        WHEN lag_mv <   PERCENTILE_CONT (0.5) WITHIN GROUP (ORDER BY lag_mv) OVER (PARTITION BY month_date) THEN 's1'
        WHEN lag_mv >=  PERCENTILE_CONT (0.5) WITHIN GROUP (ORDER BY lag_mv) OVER (PARTITION BY month_date) THEN 's2'
        ELSE 'NA' 
    END 
    + '_' +
    CASE
	    WHEN mom <  PERCENTILE_CONT (0.3) WITHIN GROUP (ORDER BY mom) OVER (PARTITION BY month_date) THEN 'mom1'
	    WHEN mom <  PERCENTILE_CONT (0.7) WITHIN GROUP (ORDER BY mom) OVER (PARTITION BY month_date) THEN 'mom2'
	    WHEN mom >= PERCENTILE_CONT (0.7) WITHIN GROUP (ORDER BY mom) OVER (PARTITION BY month_date) THEN 'mom3'
	    ELSE 'NA' 
    END
    ) AS g_UMD
FROM cte_mom_mv AS cte
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
-----------------------------------------------
--4. cte_mom_vw_ratio :
--把個股市值除以同組市值加總, 計算個股市值占比
cte_mom_vw_ratio AS (
SELECT 
    *,
    CAST(lag_mv AS FLOAT) / SUM(lag_mv) OVER (PARTITION BY month_date, g_UMD) AS UMD_ratio
FROM cte_mom_group 
)
-----------------------------------------------
--5. cte_mom_portfolio :
--個股市值占比*個股月報酬, 計算出 mom 投組月報酬
INSERT INTO gold.fct_mom_portfolio (
			month_date,
			portfolio,
			portfolio_return
		)
SELECT
    month_date, 
    g_UMD AS portfolio,
    SUM(UMD_ratio * month_return) AS portfolio_return
FROM cte_mom_vw_ratio
WHERE g_UMD NOT LIKE '%NA%' AND month_date <= '2026-05-01'
GROUP BY month_date, g_UMD










