/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
	This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
	---------------------------------------------------------------------------
	1.company_industry:
	合併上市櫃和下市櫃公司基本機料,取出市場別,代號,名稱,產業

	2.financial_statement: 
	把三財報 UNION ALL 成一張表,統一日期格式,Q1-Q4財報日期統一:03-01,06-01,09-01,12-01
	其中 cash_flows_statement 的資料與公開資訊觀測站一致,是累積財報不是單季財報,
	因此先用 CTE 整理成單季財報數值再合併,最後取出計算因子要用到的項目

	3.month_market_value: 
	當日停牌無交易,市值資料可能以 0 呈現,因此先去除市值為 0 的資料,
	再以每間公司每個月最大日期的市值作為該月公司市值,統一日期格式:mm-01,
	
	4.taiex_month_return:
	以每月最後一天加權報酬指數計算該月的月報酬,統一日期格式:mm-01

	5.risk_free_rate: 
	轉換單位: 原數值/100去除百分比,
	以每個月日期最大日期的收盤利率當作該月的無風險利率,統一日期格式:mm-01

	6.stock_month_return:
	當日停牌無交易,---股價資料會以上個交易日資料呈現---(詳情見: check_silver.sql)
	處理方式同 month_market_value,以每間公司每個月最大日期的資料作為該月收盤價,
	以(當月收盤價/上個月收盤價)-1 計算月報酬,統一日期格式:mm-01,
Parameters:
    None. 
Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start DATETIME, @batch_end DATETIME; 
    BEGIN TRY
        SET @batch_start = GETDATE();
		--============================================================
		--1. Loading silver.company_industry
		--============================================================
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.company_industry';
		TRUNCATE TABLE silver.company_industry;
		PRINT '>> Inserting Data Into: silver.company_industry';
		INSERT INTO silver.company_industry (
			market,
			company_id,
			company_name,
			industry_category
		)
		SELECT 
			market,
			company_id,
			company_name,
			industry_category
		FROM bronze.company_information 
		UNION ALL
		SELECT 
			market,
			company_id,
			company_name,
			industry_category
		FROM bronze.de_company_information; 
	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> --------------------------';
		--============================================================
		--2. Loading silver.financial_statement
		--============================================================
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.financial_statement';
		TRUNCATE TABLE silver.financial_statement;
		PRINT '>> Inserting Data Into: silver.financial_statement';
		WITH cte_lag AS (
		SELECT
		*,
		LAG(item_value) OVER (PARTITION BY stock_id, YEAR(report_date), item ORDER BY report_date) AS lag_value
		FROM bronze.cash_flows_statement
		),
		cte_q AS (
		SELECT
		*,
		ISNULL(item_value - lag_value, item_value) AS q_value 
		FROM cte_lag
		),
		cte_cash AS (
		SELECT
		report_date,
		stock_id,
		item,
		q_value AS item_value,
		origin_name
		FROM cte_q
		)
		INSERT INTO silver.financial_statement (
			statement_type, 
			report_date, 
			stock_id, 
			item, 
			item_value, 
			origin_name 
		)
		SELECT * FROM (
			SELECT 
				'income' statement_type,
				DATETRUNC(MONTH,report_date) report_date,
				stock_id,
				--CASE item
				--	WHEN 'IncomeAfterTaxes' THEN 'IncomeAfterTax'
				--	WHEN '-' THEN origin_name
				--	ELSE item
				--END item,
				item,
				item_value,
				origin_name
			FROM bronze.income_statement 
			UNION ALL
			SELECT 
				'balance' statement_type,
				DATETRUNC(MONTH,report_date) AS report_date,
				stock_id,
				item,
				item_value,
				origin_name
			FROM bronze.balance_sheet
			UNION ALL
			SELECT 
				'cash_flows' statement_type,
				DATETRUNC(MONTH,report_date) AS report_date,
				stock_id,
				item,
				item_value,
				origin_name
			FROM cte_cash
			) sub
			WHERE
			item IN ('TotalAssets','Equity','Revenue','CostOfGoodsSold','OperatingExpenses','InterestExpense');
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> --------------------------';
		--============================================================
		--3. Loading silver.month_market_value
		--============================================================
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.month_market_value';
		TRUNCATE TABLE silver.month_market_value;
		PRINT '>> Inserting Data Into: silver.month_market_value';
		WITH cte_last_day AS (
		SELECT
			stock_id,
			MAX(trade_date) AS last_of_month
		FROM bronze.market_value
		WHERE market_value != 0
		GROUP BY stock_id, DATETRUNC(MONTH, trade_date)
		),
		cte_mv AS (
		SELECT
		*
		FROM bronze.market_value AS mv
		WHERE EXISTS (
		SELECT 1
		FROM cte_last_day AS ld
		WHERE 
		ld.stock_id = mv.stock_id AND 
		ld.last_of_month = mv.trade_date )
		)
		INSERT INTO silver.month_market_value (
			month_date,
			stock_id,
			market_value
		)
		SELECT
			DATETRUNC(MONTH, trade_date) AS month_date,
			stock_id,
			market_value
		FROM cte_mv AS mv;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> --------------------------';
		--============================================================
        --4. Loading silver.taiex_month_return
		--============================================================
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.taiex_month_return';
		TRUNCATE TABLE silver.taiex_month_return;
		PRINT '>> Inserting Data Into: silver.taiex_month_return';
		INSERT INTO silver.taiex_month_return (
			month_date,
			index_id,
			month_return
		)
		SELECT
			--trade_date,
			DATETRUNC(MONTH, trade_date) AS month_date,
			index_id,
			--price,
			--LAG(price) OVER (ORDER BY trade_date) lag_price,
			(price / LAG(price) OVER (ORDER BY trade_date)) -1 AS month_return
		FROM bronze.taiex_return_index
		WHERE index_id = 'TAIEX' AND
		trade_date IN (
			SELECT
				MAX(trade_date)
			FROM bronze.taiex_return_index
			GROUP BY DATETRUNC(MONTH, trade_date)
		);
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> --------------------------';
		--============================================================
        --5. Loading silver.risk_free_rate
		--============================================================
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.risk_free_rate';
		TRUNCATE TABLE silver.risk_free_rate;
		PRINT '>> Inserting Data Into: silver.risk_free_rate';
		INSERT INTO silver.risk_free_rate (
			month_date,
			rate
		)
		SELECT
			DATETRUNC(MONTH, trade_date) AS month_date,
			close_rate/100 rate
		FROM bronze.tw_10y_gov_bond_yield
		WHERE trade_date IN (
		SELECT 
			MAX(trade_date)
		FROM bronze.tw_10y_gov_bond_yield
		GROUP BY DATETRUNC(MONTH, trade_date)
		);
	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> --------------------------';
		--============================================================
        --6. Loading silver.stock_month_return
		--============================================================
        SET @start_time = GETDATE();	
		PRINT '>> Truncating Table: silver.stock_month_return';
		TRUNCATE TABLE silver.stock_month_return;
		PRINT '>> Inserting Data Into: silver.stock_month_return';
		WITH cte_last_day AS (
		SELECT
			stock_id,
			MAX(trade_date) AS last_of_month
		FROM bronze.adj_price
		GROUP BY stock_id, DATETRUNC(MONTH, trade_date)
		),
		cte_close_price AS (
		SELECT
			ap.trade_date,
			ap.stock_id,
			ap.close_price
		FROM bronze.adj_price AS ap
		WHERE EXISTS (
		SELECT 1
		FROM cte_last_day AS ld
		WHERE 
		ld.stock_id = ap.stock_id AND 
		ld.last_of_month = ap.trade_date)
		),
		cte_month_return AS (
		SELECT
			DATETRUNC(MONTH, trade_date) AS month_date,
			stock_id,
			(close_price / LAG(close_price,1) OVER(PARTITION BY stock_id ORDER BY trade_date)) -1 AS month_return
		FROM cte_close_price AS cp
		)
		INSERT INTO silver.stock_month_return (
			month_date,
			stock_id,
			month_return
		)
		SELECT
		*
		FROM cte_month_return
		WHERE month_return IS NOT NULL;
	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> --------------------------';
		--============================================================
		SET @batch_end = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '>>>	Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start, @batch_end) AS NVARCHAR) + ' seconds'; 
		PRINT '=========================================='
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END
