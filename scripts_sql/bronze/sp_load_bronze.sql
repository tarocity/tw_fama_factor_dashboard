/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
	This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.
	---------------------------------------------------------------------------
	company_information 和 de_company_information 的 FIELDTERMINATOR  改為'^',
	否則會因基本資料中的各種字元導致原格式跑掉,尤其在 email 最常出錯,
	encoding 都用 python 改成 UTF-8,因此統一使用 CODEPAGE = '65001'
Parameters:
    None. 
Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/


CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start DATETIME, @batch_end DATETIME;
	BEGIN TRY
		SET @batch_start = GETDATE()
		PRINT '==========================================';
		PRINT 'Loading Bronze Layer';
		PRINT '==========================================';
		----------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>>> Truncating Table: bronze.company_information';
		TRUNCATE TABLE bronze.company_information;
		PRINT '>>> Inserting Data Into: bronze.company_information';
		BULK INSERT bronze.company_information
		FROM 'C:\Users\e1155_l2c4ye3\Desktop\factor_project\data_sets_csv\company_information.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = '^',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '----------------------------------------------------';
		--
		--
		SET @batch_start = GETDATE()
		PRINT '==========================================';
		PRINT 'Loading Bronze Layer';
		PRINT '==========================================';
		SET @start_time = GETDATE();
		PRINT '>>> Truncating Table: bronze.de_company_information';
		TRUNCATE TABLE bronze.de_company_information;
		PRINT '>>> Inserting Data Into: bronze.de_company_information';
		BULK INSERT bronze.de_company_information
		FROM 'C:\Users\e1155_l2c4ye3\Desktop\factor_project\data_sets_csv\de_company_information.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = '^',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '----------------------------------------------------';
		--
		--
		SET @start_time = GETDATE();
		PRINT '>>> Truncating Table: bronze.income_statement';
		TRUNCATE TABLE bronze.income_statement;
		PRINT '>>> Inserting Data Into: bronze.income_statement';
		BULK INSERT bronze.income_statement
		FROM 'C:\Users\e1155_l2c4ye3\Desktop\factor_project\data_sets_csv\financial_statement.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '----------------------------------------------------';
		--
		--
		SET @start_time = GETDATE();
		PRINT '>>> Truncating Table: bronze.balance_sheet';
		TRUNCATE TABLE bronze.balance_sheet;
		PRINT '>>> Inserting Data Into: bronze.balance_sheet';
		BULK INSERT bronze.balance_sheet
		FROM 'C:\Users\e1155_l2c4ye3\Desktop\factor_project\data_sets_csv\balance_sheet.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '----------------------------------------------------';
		--
		--
		SET @start_time = GETDATE();
		PRINT '>>> Truncating Table: bronze.cash_flows_statement';
		TRUNCATE TABLE bronze.cash_flows_statement;
		PRINT '>>> Inserting Data Into: bronze.cash_flows_statement';
		BULK INSERT bronze.cash_flows_statement
		FROM 'C:\Users\e1155_l2c4ye3\Desktop\factor_project\data_sets_csv\cash_flows_statement.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '----------------------------------------------------';
		--
		--
		SET @start_time = GETDATE();
		PRINT '>>> Truncating Table: bronze.market_value';
		TRUNCATE TABLE bronze.market_value;
		PRINT '>>> Inserting Data Into: bronze.market_value';
		BULK INSERT bronze.market_value
		FROM 'C:\Users\e1155_l2c4ye3\Desktop\factor_project\data_sets_csv\market_value_all.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '----------------------------------------------------';
		--
		--
		SET @start_time = GETDATE();
		PRINT '>>> Truncating Table: bronze.adj_price';
		TRUNCATE TABLE bronze.adj_price;
		PRINT '>>> Inserting Data Into: bronze.adj_price';
		BULK INSERT bronze.adj_price
		FROM 'C:\Users\e1155_l2c4ye3\Desktop\factor_project\data_sets_csv\adj_price_all.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '----------------------------------------------------';
		--
		--
		SET @start_time = GETDATE();
		PRINT '>>> Truncating Table: bronze.taiex_return_index';
		TRUNCATE TABLE bronze.taiex_return_index;
		PRINT '>>> Inserting Data Into: bronze.taiex_return_index';
		BULK INSERT bronze.taiex_return_index
		FROM 'C:\Users\e1155_l2c4ye3\Desktop\factor_project\data_sets_csv\TAIEX_return_index.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '----------------------------------------------------';
		--
		--
		SET @start_time = GETDATE();
		PRINT '>>> Truncating Table: bronze.tw_10y_gov_bond_yield';
		TRUNCATE TABLE bronze.tw_10y_gov_bond_yield;
		PRINT '>>> Inserting Data Into: bronze.tw_10y_gov_bond_yield';
		BULK INSERT bronze.tw_10y_gov_bond_yield
		FROM 'C:\Users\e1155_l2c4ye3\Desktop\factor_project\data_sets_csv\tw_10y_gov_bond_yield.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '----------------------------------------------------';
		--
		--
		--SET @start_time = GETDATE();
		--PRINT '>>> Truncating Table: bronze.foreign_shareholding';
		--TRUNCATE TABLE bronze.foreign_shareholding;
		--PRINT '>>> Inserting Data Into: bronze.foreign_shareholding';
		--BULK INSERT bronze.foreign_shareholding
		--FROM 'C:\Users\e1155_l2c4ye3\Desktop\factor_project\data_sets_csv\share_holding.csv'
		--WITH (
		--	FIRSTROW = 2,
		--	FIELDTERMINATOR = ',',
		--	CODEPAGE = '65001',
		--	TABLOCK
		--);
		--SET @end_time = GETDATE();
		--PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		--PRINT '----------------------------------------------------';
		----------------------------------------------------
		PRINT '==========================================';
		SET @batch_end = GETDATE()
		PRINT 'Loading Bronze Layer is Completed';
		PRINT '>>>	Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start, @batch_end) AS NVARCHAR) + ' seconds'; 
		PRINT '==========================================';
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