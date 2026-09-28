/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'FinMind_DB'.
    Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.
	
WARNING:
    Running the commented-out code will drop the entire 'FinMind_DB' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'FinMind_DB' database
--IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'FinMind_DB')
--BEGIN
--    ALTER DATABASE FinMind_DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--    DROP DATABASE FinMind_DB;
--END;
--GO

-- Create the 'FinMind_DB' database
CREATE DATABASE FinMind_DB;
GO

USE FinMind_DB;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
