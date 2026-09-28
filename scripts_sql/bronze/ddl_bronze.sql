/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
	This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	Run this script to re-define the DDL structure of 'bronze' Tables
	---------------------------------------------------------------------------
	使用到的資料來自3個來源:
	公開資訊觀測站: company_information(基本資料),de_company_information(下市/下櫃基本資料)
	FinMind: income_statement(綜合損益表),balance_sheet(資產負債表),adj_price(調整股價)
			 cash_flows_statement(現金流量表),market_value(市值),taiex_return_index(加權報酬指數)
	Investing.com: tw_10y_gov_bond_yield(臺灣十年期國債債券收益率)
===============================================================================
*/
--
-- company_information
IF OBJECT_ID('bronze.company_information', 'U') IS NOT NULL
    DROP TABLE bronze.company_information;
GO
CREATE TABLE bronze.company_information	(
	market NVARCHAR(20),
	company_id　NVARCHAR(20),
	company_name NVARCHAR(100),
	company_short_name NVARCHAR(50),
	industry_category NVARCHAR(30),
	foreign_registration_country NVARCHAR(30),
	chinese_address NVARCHAR(150),
	business_registration_number NCHAR(9),
	chairman NVARCHAR(50),
	general_manager NVARCHAR(50),
	spokesperson NVARCHAR(50),
	spokesperson_title NVARCHAR(50),
	acting_spokesperson NVARCHAR(50),
	main_phone NVARCHAR(50),
	establishment_date DATE,
	listing_date DATE,
	par_value_per_share NVARCHAR(30),
	paid_in_capital_ntd BIGINT,
	issued_common_shares_or_tdr_shares BIGINT,
	private_placement_common_shares BIGINT,
	preferred_shares BIGINT,
	financial_report_type NVARCHAR(20),
	earnings_distribution_frequency NVARCHAR(20),
	dividend_decision_level NVARCHAR(20),
	stock_transfer_agent NVARCHAR(50),
	transfer_agent_phone NVARCHAR(50),
	transfer_agent_address NVARCHAR(100),
	auditing_firm NVARCHAR(50),
	auditor_1 NVARCHAR(30),
	auditor_2 NVARCHAR(30),
	english_short_name NVARCHAR(50),
	english_address NVARCHAR(150),
	fax_number NVARCHAR(50),
	email NVARCHAR(100),
	website_url NVARCHAR(200),
	investor_relations_contact NVARCHAR(50),
	investor_relations_title NVARCHAR(50),
	investor_relations_phone NVARCHAR(50),
	investor_relations_email NVARCHAR(100),
	stakeholders_section_url NVARCHAR(200),
	corporate_governance_section_url NVARCHAR(200)
);
GO
--
-- de_company_information
IF OBJECT_ID('bronze.de_company_information', 'U') IS NOT NULL
    DROP TABLE bronze.de_company_information;
GO
CREATE TABLE bronze.de_company_information	(
	market NVARCHAR(20),
	industry_category NVARCHAR(30),
	company_id　NVARCHAR(20),
	company_name NVARCHAR(100),
	chinese_address NVARCHAR(150),
	business_registration_number NCHAR(9),
	chairman NVARCHAR(50),
	general_manager NVARCHAR(50),
	spokesperson NVARCHAR(50),
	spokesperson_title NVARCHAR(50),
	acting_spokesperson NVARCHAR(50),
	main_phone NVARCHAR(50),
	establishment_date DATE,
	listing_date DATE,
	delisting_date DATE,
	paid_in_capital_ntd BIGINT,
	stock_transfer_agent NVARCHAR(50),
	transfer_agent_phone NVARCHAR(50)
);
GO
--
-- income_statement
IF OBJECT_ID('bronze.income_statement', 'U') IS NOT NULL
    DROP TABLE bronze.income_statement;
GO
CREATE TABLE bronze.income_statement	(
	report_date		DATE,
	stock_id		NVARCHAR(30),
	item			NVARCHAR(100),
	item_value		FLOAT,
	origin_name		NVARCHAR(50)
);
GO
--
-- balance_sheet
IF OBJECT_ID('bronze.balance_sheet', 'U') IS NOT NULL
    DROP TABLE bronze.balance_sheet;
GO
CREATE TABLE bronze.balance_sheet	(
	report_date		DATE,
	stock_id		NVARCHAR(30),
	item			NVARCHAR(100),
	item_value		FLOAT,
	origin_name		NVARCHAR(50)
);
GO
--
-- cash_flows_statement
IF OBJECT_ID('bronze.cash_flows_statement', 'U') IS NOT NULL
    DROP TABLE bronze.cash_flows_statement;
GO
CREATE TABLE bronze.cash_flows_statement	(
	report_date		DATE,
	stock_id		NVARCHAR(30),
	item			NVARCHAR(100),
	item_value		FLOAT,
	origin_name		NVARCHAR(50)
);
GO
--
-- market_value
IF OBJECT_ID('bronze.market_value', 'U') IS NOT NULL
    DROP TABLE bronze.market_value;
GO
CREATE TABLE bronze.market_value	(
	trade_date		DATE,
	stock_id		NVARCHAR(30),
	market_value	BIGINT
);
GO
--
-- adj_price
IF OBJECT_ID('bronze.adj_price', 'U') IS NOT NULL
    DROP TABLE bronze.adj_price;
GO
CREATE TABLE bronze.adj_price	(
	trade_date			DATE,
	stock_id			NVARCHAR(50),
	trading_volume		BIGINT, --成交量
	trading_money		BIGINT, --成交金額
	open_price			FLOAT, --開盤價
	max_price			FLOAT, --最高價
	min_price			FLOAT, --最低價
	close_price			FLOAT, --收盤價
	spread				FLOAT, --漲跌幅
	trading_turnover	BIGINT --交易筆數
);
GO
--
-- taiex_return_index
IF OBJECT_ID('bronze.taiex_return_index', 'U') IS NOT NULL
    DROP TABLE bronze.taiex_return_index;
GO
CREATE TABLE bronze.taiex_return_index	(
	price		FLOAT, --報酬指數
	index_id	NVARCHAR(20),
	trade_date	DATE
);
GO
--
-- tw_10y_gov_bond_yield
IF OBJECT_ID('bronze.tw_10y_gov_bond_yield', 'U') IS NOT NULL
    DROP TABLE bronze.tw_10y_gov_bond_yield;
GO
CREATE TABLE bronze.tw_10y_gov_bond_yield	(
	trade_date	DATE,
	close_rate	FLOAT,
	open_rate	FLOAT,
	max_rate	FLOAT,
	min_rate	FLOAT,
	pct_change	NVARCHAR(30) --漲跌幅
);

--
--
--IF OBJECT_ID('bronze.foreign_shareholding', 'U') IS NOT NULL
--    DROP TABLE bronze.foreign_shareholding;
--GO
--CREATE TABLE bronze.foreign_shareholding	(
--	trade_date DATE,
--	stock_id NVARCHAR(50),
--	stock_name NVARCHAR(50),
--	international_code NVARCHAR(50),
--	foreign_investment_remaining_shares BIGINT,
--	foreign_investment_shares BIGINT,
--	foreign_investment_remain_ratio FLOAT,
--	foreign_investment_shares_ratio FLOAT,
--	foreign_investment_upper_limit_ratio FLOAT,
--	chinese_investment_upper_limit_ratio FLOAT,
--	number_of_shares_issued BIGINT,
--	recently_declare_date NVARCHAR(20),
--	note NVARCHAR(200)
--);