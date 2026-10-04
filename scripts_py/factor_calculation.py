# -*- coding: utf-8 -*-
"""
Created on Sat Aug 29 00:29:38 2026

@author: e1155_l2c4ye3
"""

import pandas as pd
import numpy as np
import urllib
from sqlalchemy import create_engine

params = urllib.parse.quote_plus(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost\\SQLEXPRESS;"
    "DATABASE=FinMind_DB;"
    "Trusted_Connection=yes;"
)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

# 計算 Fama factor portfolios: HML, RMW, CMA
# 1. cte_pivot_financial :
# 把季報從長表轉寬表, 方便後續計算 factor variable 
# ↓
# 2. cte_factor_variable :
# 根據 report_date JOIN (3,6,9,12月)市值後計算 factor variable (bm, op, inv) 
# ↓
# 3. cte_sort_variable :
# 排序 factor variable, 把個股分類進因子的排序分組中,排序前把金融業與興櫃公司排除掉
# ↓
# 4. cte_factor_group :
# 把各因子排序與市值排序合併 g_mv  g_bm  g_op  g_inv 
# ↓
# 5. cte_value_weighted_group :
# 最後根據因子分組, 計算個股在所屬組別中的市值占比, 用於後續計算市值加權投組報酬率
# ↓
# 6. cte_join_return :
# cte 先合併 gold.dim_date, 再依照 gold.dim_date 的日期合併 stock_month_return
# ↓
# 7. gold.fct_factor_portfolio_rebalance_quarterly :
# 最後根據每個日期與該因子分組, 把所有個股的市值佔比*月報酬後 再加總,
# 完成計算因子投組的 市值加權報酬


# %% 1. df_pivot :
# 把季報從長表轉寬表, 方便後續計算 factor variable 

sql_pivot = pd.read_sql_query(
    sql = '''
    SELECT 
        report_date,
        stock_id,
        item,
        item_value
    FROM silver.financial_statement
    ''',
    con = engine)

df_pivot = pd.pivot(
        sql_pivot,
        columns = 'item',
        index = ['report_date','stock_id'],
        values = 'item_value'
        ).reset_index()


# %% 2. df_variable :
# 根據 report_date JOIN (3,6,9,12月)市值後計算 factor variable (bm, op, inv) 

sql_mv = pd.read_sql_query(
    sql = '''
    SELECT 
        month_date,
        stock_id,
        market_value AS mv
    FROM silver.month_market_value
    ''',
    con = engine)


df_variable = pd.merge(
    left = df_pivot,
    right = sql_mv,
    how = 'left',
    left_on = ['report_date','stock_id'],
    right_on = ['month_date','stock_id'],
    )

df_variable = df_variable[
    lambda x: (x.TotalAssets>0) & (x.mv>0)
    ].sort_values(['report_date','stock_id'])#.fillna({'InterestExpense': 0})


df_variable = df_variable.assign(
    bm = lambda x: x.Equity/x.mv,
    inv = lambda x: 
        (x.TotalAssets/x.groupby('stock_id').TotalAssets.shift(1)) -1,
    op = lambda x: 
        (x.Revenue-x.CostOfGoodsSold-x.OperatingExpenses-x.InterestExpense)/
        x.Equity
    )

# %% 3. df_group
# 排序 factor variable, 把個股分類進因子的排序分組中,排序前把金融業與興櫃公司排除掉

sql_ci = pd.read_sql_query(
    sql = '''
    SELECT 
        market,
        industry_category,
        company_id
    FROM silver.company_industry
    ''',
    con = engine)

sr_id = sql_ci[
    lambda x: (x.market != 'emerging') & 
    (~x.industry_category.isin(['金融保險業','金融業']))
    ].company_id

# df_variable = df_variable[lambda x: x.stock_id.isin(sr_id)]

df_group = df_variable[lambda x: x.stock_id.isin(sr_id)].assign(
    g_mv = lambda x: np.select(
        condlist = [
        x.mv < x.groupby('report_date').mv.transform(lambda y:y.quantile(0.5)),
        x.mv >= x.groupby('report_date').mv.transform(lambda y: y.quantile(0.5))
        ],
        choicelist = ['s1','s2'],
        default = 'NA'),
    g_bm = lambda x: np.select(
        condlist = [
        x.bm < x.groupby('report_date').bm.transform(lambda y:y.quantile(0.3)),
        x.bm < x.groupby('report_date').bm.transform(lambda y: y.quantile(0.7)),
        x.bm >= x.groupby('report_date').bm.transform(lambda y: y.quantile(0.7))
        ],
        choicelist = ['bm1','bm2','bm3'],
        default = 'NA'),
    g_op = lambda x: np.select(
        condlist = [
        x.op < x.groupby('report_date').op.transform(lambda y:y.quantile(0.3)),
        x.op < x.groupby('report_date').op.transform(lambda y: y.quantile(0.7)),
        x.op >= x.groupby('report_date').op.transform(lambda y: y.quantile(0.7))
        ],
        choicelist = ['op1','op2','op3'],
        default = 'NA'),
    g_inv = lambda x: np.select(
        condlist = [
        x.inv < x.groupby('report_date').inv.transform(lambda y:y.quantile(0.3)),
        x.inv < x.groupby('report_date').inv.transform(lambda y: y.quantile(0.7)),
        x.inv >= x.groupby('report_date').inv.transform(lambda y: y.quantile(0.7))
        ],
        choicelist = ['inv1','inv2','inv3'],
        default = 'NA')
    )[['report_date','stock_id','mv','g_mv','g_bm','g_op','g_inv']]

# %% 4. df_vw
# 把各因子排序與市值排序合併 g_mv  g_bm  g_op  g_inv 
# 最後根據因子分組, 計算個股在所屬組別中的市值占比, 用於後續計算市值加權投組報酬率
df_group = df_group.assign(
    g_HML = lambda x: x.g_mv + '_' + x.g_bm,
    g_RMW = lambda x: x.g_mv + '_' + x.g_op,
    g_CMA = lambda x: x.g_mv + '_' + x.g_inv,
    )

df_vw = df_group.assign(
    HML_ratio = lambda x: x.mv/
    x.groupby(['report_date','g_HML']).mv.transform('sum'),
    RMW_ratio = lambda x: x.mv/
    x.groupby(['report_date','g_RMW']).mv.transform('sum'),
    CMA_ratio = lambda x: x.mv/
    x.groupby(['report_date','g_CMA']).mv.transform('sum'),
    )

# %% 5. df_vw_ret
# cte 先合併 gold.dim_date, 再依照 gold.dim_date 的日期合併 stock_month_return
sql_date = pd.read_sql_query(
    sql = '''
    SELECT 
        month_date,
        report_date_by_quarter
    FROM gold.dim_date
    ''',
    con = engine)


sql_return = pd.read_sql_query(
    sql = '''
    SELECT 
        month_date,
        stock_id,
        month_return
    FROM silver.stock_month_return
    ''',
    con = engine)

df_vw_ret = pd.merge(
    left = df_vw, 
    right = sql_date,
    how = 'left',
    left_on = ['report_date'],
    right_on = ['report_date_by_quarter'],
    ).merge(
    sql_return,
    how = 'left',
    on = ['stock_id','month_date']
    ).assign(
    HML_vwr = lambda x: x.month_return*x.HML_ratio,
    RMW_vwr = lambda x: x.month_return*x.RMW_ratio,
    CMA_vwr = lambda x: x.month_return*x.CMA_ratio
        )

# %% 6. df_port
# 最後根據每個日期與該因子分組, 把所有個股的市值佔比*月報酬後 再加總, 
# 完成計算因子投組的 市值加權報酬

df_port = pd.concat(

    [
    df_vw_ret.groupby(['month_date','g_HML']).agg(
    {'HML_vwr':'sum'}).reset_index().set_axis(
    ['month_date','port','return'], axis = 1),
        
    df_vw_ret.groupby(['month_date','g_RMW']).agg(
    {'RMW_vwr':'sum'}).reset_index().set_axis(
    ['month_date','port','return'], axis = 1),
        
    df_vw_ret.groupby(['month_date','g_CMA']).agg(
    {'CMA_vwr':'sum'}).reset_index().set_axis(
    ['month_date','port','return'], axis = 1),
    ],
    axis = 0).astype({'month_date':'string'})[
    lambda x: (~x.port.str.contains('NA')) & 
              (x.month_date <= '2026-05-01')
    ]

# %% compare with sql 
# 把用 python 計算的投組與用 sql 計算的相比

sql_port_q = pd.read_sql_query(
    sql = '''
    SELECT 
        month_date,
        portfolio,
        portfolio_return 
    FROM gold.fct_factor_portfolio_rebalance_quarterly
    ''',
    con = engine).astype({'month_date':'string'}).set_axis(
    ['month_date','port','return'],axis = 1)

        
        

sql_port_q = sql_port_q.sort_values(
['month_date','port']).reset_index(drop = True)

df_port = df_port.sort_values(
['month_date','port']).reset_index(drop = True)


# AAA = df_port.value_counts('port')
# BBB = sql_port_q.value_counts('port')


# df_compare = sql_port_q.compare(df_port)

df_diff_abs = sql_port_q.merge(
    df_port,
    how = 'left',
    on = ['month_date','port']).assign(
    ret_diff = lambda x: 
        (x.return_x - x.return_y).abs()
    )

 
