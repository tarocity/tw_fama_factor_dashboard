# -*- coding: utf-8 -*-
"""
Created on Sat Jun  6 15:21:37 2026

@author: e1155_l2c4ye3
"""
# %% import

import pandas as pd
import urllib
from sqlalchemy import create_engine

params = urllib.parse.quote_plus(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=T20231112\\SQLEXPRESS;"
    "DATABASE=FinMind_DB;"
    "Trusted_Connection=yes;"
)

engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

# %% 連接 MS SQL,把所有投組和因子取出組成長表

tmp = pd.read_sql_query(
    sql = 'SELECT * FROM gold.fct_market_premium',
    con = engine)

# 1	fct_factor_portfolio_rebalance_quarterly
# 2	fct_factor_portfolio_rebalance_annual
# 6	fct_mom_portfolio
# 11	fct_market_premium
# 12	fct_factor_data

df_portfolio = pd.read_sql_query(
    sql =
    '''
    SELECT 
         month_date,
         'quarterly' rebalance,
         portfolio,
         portfolio_return
    FROM gold.fct_factor_portfolio_rebalance_quarterly
    UNION ALL 
    SELECT 
         month_date,
         'annual' rebalance,
         portfolio,
         portfolio_return
    FROM gold.fct_factor_portfolio_rebalance_annual
    UNION ALL 
    SELECT 
         month_date,
         'monthly' rebalance,
         portfolio,
         portfolio_return
    FROM gold.fct_mom_portfolio
    UNION ALL 
    SELECT 
         month_date,
         'monthly' rebalance,
         portfolio,
         portfolio_return
    FROM gold.fct_market_premium
    UNION ALL 
    SELECT 
         month_date,
         rebalance,
         portfolio,
         portfolio_return
    FROM gold.fct_factor_data
    ''',
    con = engine).astype({'month_date':'string'})


df_portfolio = df_portfolio[
    lambda x: x.month_date <= '2026-05-01'].dropna()


df_check = df_portfolio.value_counts(
    subset = ['portfolio','rebalance'], dropna = False)


# %%


df_portfolio.to_excel(
    'factor_portfolio_0925.xlsx',
    index = False,
    sheet_name = 'portfolio')


# %%


df_old = pd.read_excel('factor_portfolio_0908.xlsx')



df_compare = df_old.merge(
    df_portfolio,
    on = ['month_date','rebalance','portfolio']).assign(
    diffret = lambda x: x.portfolio_return_x - x.portfolio_return_y,
    diffabs = lambda x: x.diffret.abs()
    )

AAA_cte_cash = df_compare[lambda x: x.diffabs >= 0.0000001]

BBB = df_compare.groupby(['portfolio']).agg({
    'diffabs':['sum','mean']
    })

# df_portfolio.to_excel(
#     'factor_portfolio_new.xlsx',
#     index = False,
#     sheet_name = 'portfolio')

# %%


AAA = df_portfolio[lambda x: x.portfolio.isin(['CMA'])]


df_portfolio.isna().sum()












