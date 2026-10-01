/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
	This script creates tables in the 'silver' schema, dropping existing tables 
    if they already exist.
	Run this script to re-define the DDL structure of 'silver' Tables
	---------------------------------------------------------------------------
	取出各 table 需要的資訊,把同性質的 table 合併,並附上 dwh_create_date
	bronze table(s) --> silver table
	1.company_information & de_company_information --> company_industry
	2.income_statement & balance_sheet & cash_flows_statement --> financial_statement
	3.market_value --> month_market_value
	4.taiex_return_index --> taiex_month_return
	5.tw_10y_gov_bond_yield --> risk_free_rate
	6.adj_price --> stock_month_return
===============================================================================
*/
--
-- company_industry
IF OBJECT_ID('silver.company_industry', 'U') IS NOT NULL
    DROP TABLE silver.company_industry;
GO
CREATE TABLE silver.company_industry	(
	market				NVARCHAR(20),
	industry_category	NVARCHAR(30),
	company_id　			NVARCHAR(20),
	company_name		NVARCHAR(100),
	dwh_create_date		DATETIME2 DEFAULT GETDATE()
);
GO
--
-- financial_statement
IF OBJECT_ID('silver.financial_statement', 'U') IS NOT NULL
    DROP TABLE silver.financial_statement;
GO
CREATE TABLE silver.financial_statement	(
	statement_type	NVARCHAR(10),
	report_date		DATE,
	stock_id		NVARCHAR(30),
	item			NVARCHAR(100),
	item_value		FLOAT,
	origin_name		NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
--
-- month_market_value
IF OBJECT_ID('silver.month_market_value', 'U') IS NOT NULL
    DROP TABLE silver.month_market_value;
GO
CREATE TABLE silver.month_market_value	(
	month_date		DATE,
	stock_id		NVARCHAR(30),
	market_value	BIGINT,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
--
-- taiex_month_return
IF OBJECT_ID('silver.taiex_month_return', 'U') IS NOT NULL
    DROP TABLE silver.taiex_month_return;
GO
CREATE TABLE silver.taiex_month_return	(
	month_date		DATE,
	index_id		NVARCHAR(20),
	month_return	FLOAT,
	dwh_create_date	DATETIME2 DEFAULT GETDATE()
);
GO
--
-- risk_free_rate
IF OBJECT_ID('silver.risk_free_rate', 'U') IS NOT NULL
    DROP TABLE silver.risk_free_rate;
GO
CREATE TABLE silver.risk_free_rate	(
	month_date		DATE,
	rate			FLOAT,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
--
-- stock_month_return
IF OBJECT_ID('silver.stock_month_return', 'U') IS NOT NULL
    DROP TABLE silver.stock_month_return;
GO
CREATE TABLE silver.stock_month_return	(
	month_date		DATE,
	stock_id		NVARCHAR(50),
	month_return	FLOAT,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO















