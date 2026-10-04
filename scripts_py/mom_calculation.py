# -*- coding: utf-8 -*-
"""
Created on Sat Sep  5 20:57:00 2026

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

# 計算 MOM portfolios
# 計算 MOM portfolios
# 1. cte_cumu_return :
# 先計算個股的累積報酬率- mom,
# 依照定義: t月的 mom 為 t-12 ~ t-2 共 11個月的累積報酬率
# ↓
# 2. cte_mom_mv :
# JOIN 月市值再把月市值 lag 1個月, 用於後續計算市值加權
# ↓
# 3. cte_mom_group :
# 每個月根據 cumu_return & lag_mv 排序,
# 把公司分類進 MOM 的分組中,排序前把金融業與興櫃公司排除掉
# ↓
# 4. cte_mom_vw_ratio :
# 把個股市值除以同組市值加總, 計算個股市值占比
# ↓
# 5. cte_mom_portfolio :
# 個股市值占比*個股月報酬, 計算出 mom 投組月報酬
# %% 1. df_mom:
# 先計算個股的累積報酬率- mom,
# 依照定義: t月的 mom 為 t-12 ~ t-2 共 11個月的累積報酬率

sql_return = pd.read_sql_query(
    sql = '''
    SELECT 
        month_date,
        stock_id,
        month_return
    FROM silver.stock_month_return
    ''',
    con = engine)

df_mom = sql_return.sort_values(['month_date','stock_id']).assign(
    mom = lambda x: x.groupby('stock_id').month_return.transform(
        lambda y: pd.Series(
            [1+y.shift(i) for i in range(2,13)]).prod()
        )
    )

# %% 2. df_mom_mv:
# JOIN 月市值再把月市值 lag 1個月, 用於後續計算市值加權

sql_mv = pd.read_sql_query(
    sql = '''
    SELECT 
        month_date,
        stock_id,
        market_value
    FROM silver.month_market_value
    ''',
    con = engine)

sql_mv.info
df_mom.info


df_mom_mv = df_mom.merge(
    sql_mv,
    how = 'left',
    on = ['month_date','stock_id'])

df_mom_mv = df_mom_mv.sort_values(['month_date']).assign(
    lag_mv = lambda x: x.groupby('stock_id').market_value.shift(1)
    )

# %% 3. df_group
# 每個月根據 mom & lag_mv 排序,
# 把公司分類進 MOM 的分組中,排序前把金融業與興櫃公司排除掉

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

df_group = df_mom_mv[lambda x: x.stock_id.isin(sr_id)].assign(
    g_mv = lambda x: np.select(
        condlist = [
        x.lag_mv < x.groupby('month_date').lag_mv.transform(lambda y:y.quantile(0.5)),
        x.lag_mv >= x.groupby('month_date').lag_mv.transform(lambda y: y.quantile(0.5))
        ],
        choicelist = ['s1','s2'],
        default = 'NA'),
    g_mom = lambda x: np.select(
        condlist = [
        x.mom < x.groupby('month_date').mom.transform(lambda y:y.quantile(0.3)),
        x.mom < x.groupby('month_date').mom.transform(lambda y: y.quantile(0.7)),
        x.mom >= x.groupby('month_date').mom.transform(lambda y: y.quantile(0.7))
        ],
        choicelist = ['mom1','mom2','mom3'],
        default = 'NA'),
    g_UMD = lambda x: x.g_mv + '_' + x.g_mom,
    )



# %% 4. df_vwr
# 把個股市值除以同組市值加總, 計算個股市值占比
# 個股市值占比*個股月報酬, 計算出 mom 投組月報酬
df_vwr = df_group.assign(
    UMD_ratio = lambda x: x.lag_mv/
    x.groupby(['month_date','g_UMD']).lag_mv.transform('sum'),
    UMD_vwr = lambda x: x.month_return*x.UMD_ratio
    )



# %% 5. cte_mom_portfolio
# 

df_port = df_vwr.groupby(['month_date','g_UMD']).agg(
    {'UMD_vwr':'sum'}).reset_index().set_axis(
    ['month_date','port','return'], axis = 1)

df_port = df_port.astype({'month_date':'string'})[
    lambda x: 
        (~x.port.str.contains('NA')) & 
        (x.month_date <= '2026-05-01')
    ]

# %%


sql_port = pd.read_sql_query(
    sql = '''
    SELECT 
        month_date,
        portfolio,
        portfolio_return 
    FROM gold.fct_mom_portfolio
    ''',
    con = engine).astype({'month_date':'string'}).set_axis(
    ['month_date','port','return'],axis = 1)


sql_port = sql_port.sort_values(
['month_date','port']).reset_index(drop = True)

df_port = df_port.sort_values(
['month_date','port']).reset_index(drop = True)


# AAA = df_port.value_counts('port')
# BBB = sql_port_q.value_counts('port')


# df_compare = sql_port.compare(df_port)

df_diff_abs = sql_port.merge(
    df_port,
    how = 'left',
    on = ['month_date','port']).assign(
    ret_diff = lambda x: 
        (x.return_x - x.return_y).abs()
    )

# %%


