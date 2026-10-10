# Taiwan Fama-French Factor Dashboard

Welcome to the **Taiwan Fama-French Factor Dashboard Project** repository! 📊    
This project presents an end-to-end workflow for constructing Fama-French factors and developing a Tableau dashboard for the Taiwan stock market.
The project integrates **Python**, **SQL Server**, and **Tableau** to build a structured data pipeline, construct factor-based portfolios, and create interactive visualizations.

---
## 📌 Project Overview

This project involves:

1. **Data Collection**: Collecting Taiwan stock market and financial data from **FinMind API** using Python.
2. **Data Architecture**: Organizing data using the Medallion Architecture with **Bronze**, **Silver**, and **Gold** layers in SQL Server.
3. **Data Processing & Transformation**: Cleaning and transforming raw data into dashboard-ready datasets.
4. **Factor & Portfolio Construction**: Constructing Fama-French factors and factor-sorted portfolios in SQL Server.
5. **Dashboard & Analytics**: Developing an interactive Tableau dashboard to analyze historical performance and calculate risk-return metrics.

---
## 🏗️ Data Architecture
The data architecture for this project follows Medallion Architecture **Bronze**, **Silver**, and **Gold** layers:
![Data_Architecture](docs/Data_Architecture.png)

1. **Bronze Layer**: Stores data that has been preprocessed using Python. Data is loaded from CSV files into SQL Server.
2. **Silver Layer**: Cleans, standardizes, and transforms data, including calculating derived columns, to prepare data for portfolio construction.
3. **Gold Layer**: Constructs Fama-French factors and portfolios to create dashboard-ready datasets for Tableau Public.

---
## 🔀 Data Flow
The diagram below illustrates how data flows through the Bronze, Silver, and Gold layers, highlighting data transformations and dependencies between tables.
![Data_Flow](docs/Data_Flow.png)

---
## 🛠️ Important Links & Tools:

- **Spyder**: IDE for writing Python scripts.
- **SQL Server Management Studio (SSMS)**: GUI for managing and interacting with databases.
- **JupyterLab**: Used to demonstrate the calculation process using Python and export it as an HTML file.
- **Data Sources**
  - [MOPS](https://mops.twse.com.tw/mops/#/web/t51sb01): Company information data.
  - [FinMind](https://finmind.github.io/tutor/TaiwanMarket/DataList/): Market and financial data.
  - [Investing.com](https://hk.investing.com/rates-bonds/taiwan-10-year-bond-yield-historical-data): Taiwan 10-year government bond yield data.
- **[Kenneth R. French Website](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/f-f_5_factors_2x3.html)**: Fama-French factor calculation methods.
- **[draw.io](https://www.drawio.com/):** Create data architecture, data flows, and Tableau dashboard layout diagram.
- **[Photopea](https://www.photopea.com/l/zh_tw/)**: Change the colors of icons used in the dashboard.
- **[Tableau Public]()**: Interactive dashboard for Taiwan Fama-French factors and portfolios.

---
## 📂 Repository Structure
```
taiwan-fama-french-factor-dashboard/
│
├── datasets_csv/                       # Raw and preprocessed datasets used for the project
│
├── docs/                               # Project documentation
│   ├── factor_project.drawio           # Draw.io diagrams for data architecture, data flow, and Tableau dashboard layout
│   ├── factor_dashboard.twbx           # Tableau workbook of Taiwan Fama-French factors and portfolios
│   └── fama_portfolio_calc.ipynb       # Jupyter Notebook demonstrating the calculation process using Python
│  
├── scripts_sql/                        # SQL scripts for ETL and transformations
│   ├── init_database.sql               # Script for creating database and schemas
│   ├── bronze/                         # Scripts for loading raw data
│   ├── silver/                         # Scripts for cleaning and transforming data
│   └── gold/                           # Scripts for constructing Fama-French factors and portfolios 
│
├── scripts_py/                         # Python scripts for getting FinMind KPI data, converting CSV encoding and connecting to SQL Server,etc 
│
├── png/                                # png files for icons used in Tableau dashboard
│
└── README.md                           # Project overview and instructions
```

---
## 🙏 Acknowledgments
The database architecture and README structure were inspired by [sql-data-warehouse-project](https://github.com/DataWithBaraa/sql-data-warehouse-project), created by DataWithBaraa.
