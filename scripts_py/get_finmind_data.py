# -*- coding: utf-8 -*-
"""
Created on Mon May 25 22:05:43 2026

@author: e1155_l2c4ye3
"""
# %% import
# FinMind api 資料集
# https://finmind.github.io/tutor/TaiwanMarket/DataList/
# 除了 TaiwanStockCashFlowsStatement,其餘資料都是在有 Backer 方案下去抓的
# 其中 TaiwanStockPriceAdj 和 TaiwanStockMarketValue
# 抓資料的時候有中斷,所以有分多次下載,檔案有超過 1 個
import pandas as pd
import requests
from FinMind.data import DataLoader
import time
token = 'secret'

# %% TaiwanStockFinancialStatements

api = DataLoader()
api.login_by_token(api_token= token)
# 先抓老公司確認 資料庫 taiwan_stock_financial_statement 的日期
df_check_date = api.taiwan_stock_financial_statement(
    stock_id="1101",
    start_date='1990-01-01',
)
sr_api_date = df_check_date.date.drop_duplicates()

# 依該日期抓所有公司 taiwan_stock_financial_statement
df_fina_stat = pd.DataFrame()
for i in sr_api_date:
    df_tmp = api.taiwan_stock_financial_statement(
        start_date=i
    )
    df_fina_stat = pd.concat(
        [df_fina_stat,  df_tmp],
        axis = 0
        )
    print(i)
    # time.sleep(0.5)
    
df_fina_stat.to_parquet('financial_statement.parquet')
df_fina_stat.to_csv(
    "financial_statement.csv",
    encoding="utf_8",
    index=False)

# test
# tmp_par = pd.read_parquet('financial_statement.parquet')
# tmp_csv = pd.read_csv('financial_statement.csv',
#                       dtype = {'stock_id':'string'})
# tmp_result = tmp_par.reset_index(drop = True).compare(tmp_csv.reset_index(drop = True))


# %% TaiwanStockBalanceSheet


api = DataLoader()
api.login_by_token(api_token= token)
# 先抓老公司確認 資料庫 taiwan_stock_balance_sheet 的日期
df_check_date = api.taiwan_stock_balance_sheet(
    stock_id="1101",
    start_date='2011-01-01',
)
sr_api_date = df_check_date.date.drop_duplicates()

# 依日期抓該所有公司 taiwan_stock_balance_sheet
df_bala_sheet = pd.DataFrame()
for i in sr_api_date:
    df_tmp = api.taiwan_stock_balance_sheet(
        start_date=i
    )
    df_bala_sheet = pd.concat(
        [df_bala_sheet,  df_tmp],
        axis = 0
        )
    print(i)
    # time.sleep(0.5)
    
df_bala_sheet.to_parquet('balance_sheet.parquet')
df_bala_sheet.to_csv(
    "balance_sheet.csv",
    encoding="utf_8",
    index=False)

# test
# tmp_par = pd.read_parquet('balance_sheet.parquet')
# tmp_csv = pd.read_csv('balance_sheet.csv',
#                       dtype = {'stock_id':'string'})
# tmp_result = tmp_par.reset_index(drop = True).compare(tmp_csv.reset_index(drop = True))

# %% TaiwanStockMarketValue 
# 先抓 2330 的資料, 再透過資料中有的日期去抓該日期所有資料
api = DataLoader()
api.login_by_token(api_token= token)
df_check_date = api.taiwan_stock_market_value(
    stock_id='2330',
    # start_date='2004-01-01',
    # end_date='2026-05-30',
    start_date='2026-05-27',
    end_date='2026-06-30',
    )
sr_api_date = df_check_date.date.drop_duplicates()
# 依日期抓該所有公司 taiwan_stock_market_value
# 第一次抓到 2010-09-30, 下次從 2010-10-01 開始
sr_api_date = sr_api_date[lambda x: x >= '2010-10-01']
# df_market_value = pd.DataFrame()
df_market_value_1 = pd.DataFrame()
#
url_token = "https://api.web.finmindtrade.com/v2/user_info"
headers = {"Authorization": f"Bearer {token}"}
#
for i in sr_api_date:
    resp = requests.get(url_token, headers=headers)
    token_times = resp.json()["user_count"] # 使用次數
    while 1600 - token_times < 50:
        print('sleep !')
        time.sleep(300)
        resp = requests.get(url_token, headers=headers)
        token_times = resp.json()["user_count"] # 使用次數
    #
    df_tmp = api.taiwan_stock_market_value(
    start_date = i
    )
    df_market_value_1 = pd.concat(
        [df_market_value_1,  df_tmp],
        axis = 0
        )
    print(i)
    
    # time.sleep(0.5)
    
# df_market_value.to_parquet('market_value_0.parquet')
# df_market_value_1.to_parquet('market_value_1.parquet')
# df_market_value_1.to_parquet('market_value_20260527_to_20260618.parquet')


# market_value_0 = pd.read_parquet('market_value_20040212_to_20100930.parquet')
# market_value_1 = pd.read_parquet('market_value_20101001_to_20260526.parquet')
# market_value_2 = pd.read_parquet('market_value_20260527_to_20260618.parquet')

# market_value_0.to_parquet('market_value_20040212_to_20100930.parquet')
# market_value_1.to_parquet('market_value_20101001_to_20260526.parquet')


market_value_all = pd.concat(
    [market_value_0,
     market_value_1,
     market_value_2]
    ,axis = 0)

market_value_all.to_parquet('market_value_all.parquet')
market_value_all.to_csv(
    "market_value_all.csv",
    encoding="utf_8",
    index=False)


# %% TaiwanStockPriceAdj
# 透過交易日日期資料, 去抓該交易日所有資料
#  TaiwanStockTradingDate
url = "https://api.finmindtrade.com/api/v4/data"
headers = {"Authorization": f"Bearer {token}"}
parameter = {
    "dataset": "TaiwanStockTradingDate",
}
resp = requests.get(url, headers=headers, params=parameter)
data = resp.json()
df_td = pd.DataFrame(data["data"])
##
# ls_api_date = pd.date_range(
#     start = '1994-10-01',
#     end = '1998-12-31').date.tolist()
#
# ls_api_date = ls_api_date + df_td.date.to_list()
# ls_api_date = [str(x) for x in ls_api_date]

# df_adj_price_0 抓到2006-03-24
ls_api_date = df_td.date[
    lambda x: (x >'2026-05-26')&(x <'2026-07-01')]
#
url_token = "https://api.web.finmindtrade.com/v2/user_info"
url = "https://api.finmindtrade.com/api/v4/data"
headers = {"Authorization": f"Bearer {token}"}
df_adj_price = pd.DataFrame()
#
for i in ls_api_date:
    resp = requests.get(url_token, headers=headers)
    token_times = resp.json()["user_count"] # 使用次數
    while 1600 - token_times < 50:
        print('sleep !')
        time.sleep(300)
        resp = requests.get(url_token, headers=headers)
        token_times = resp.json()["user_count"] # 使用次數
    # 
    parameter = {
        "dataset": "TaiwanStockPriceAdj",
        "start_date": i,
    }
    resp = requests.get(
        url,
        headers=headers,
        params=parameter)
    data_json = resp.json()
    df_tmp = pd.DataFrame(data_json["data"])
    df_adj_price = pd.concat(
        [df_adj_price, df_tmp],
        axis = 0
    )
    
    print(i)
        

# df_adj_price.to_parquet('df_adj_price_1.parquet')

# df_adj_price_0 union all df_adj_price_1
adj_price_0 = pd.read_parquet('adj_price_19941001_to_20060324.parquet')
adj_price_1 = pd.read_parquet('adj_price_20060327_to_20260526.parquet')
adj_price_2 = pd.read_parquet('adj_price_20260527_to_20260618.parquet')


# df_adj_price_0.to_parquet('adj_price_19941001_to_20060324.parquet')
# df_adj_price_1.to_parquet('adj_price_20060327_to_20260526.parquet')
# df_adj_price.to_parquet('adj_price_20260527_to_20260618.parquet')


df_adj_price_all = pd.concat(
    [adj_price_0,
     adj_price_1,
     adj_price_2],
    axis = 0)

df_adj_price_all.to_parquet('adj_price_all.parquet')
df_adj_price_all.to_csv(
    "adj_price_all.csv",
    encoding="utf_8",
    index=False)

# %% TaiwanStockTotalReturnIndex


api = DataLoader()
api.login_by_token(api_token = token)
# api.login_by_token(api_token='token')
TAIEX_return_index = api.taiwan_stock_total_return_index(
    index_id="TAIEX",
    start_date='2003-01-01',
    end_date='2026-06-30'
)

TPEx_return_index = api.taiwan_stock_total_return_index(
    index_id="TPEx",
    start_date='2003-01-01',
    end_date='2026-06-30'
)


TAIEX_return_index = pd.concat(
    [TAIEX_return_index,TPEx_return_index], axis = 0)


TAIEX_return_index.to_csv(
    "TAIEX_return_index.csv",
    encoding="utf_8",
    index=False)




# %% TaiwanStockShareholding

# api = DataLoader()
# api.login_by_token(api_token= token)
# ls_api_date = api.taiwan_stock_shareholding(
#     stock_id="2330",
#     start_date='2004-02-01',
#     end_date='2026-06-01'
# )
# ls_api_date = ls_api_date.date
# #
# #
# url_token = "https://api.web.finmindtrade.com/v2/user_info"
# headers = {"Authorization": f"Bearer {token}"}
# df_share_holding = pd.DataFrame()
# #
# for i in ls_api_date:
#     resp = requests.get(url_token, headers=headers)
#     token_times = resp.json()["user_count"] # 使用次數
#     while 1600 - token_times < 100:
#         print('sleep !')
#         time.sleep(300)
#         resp = requests.get(url_token, headers=headers)
#         token_times = resp.json()["user_count"] # 使用次數
#     # 
#     df_tmp = api.taiwan_stock_shareholding(
#     start_date= i,
#     )
#     df_share_holding = pd.concat(
#         [df_share_holding, df_tmp],
#         axis = 0
#     )
    
#     print(i)
        
# df_share_holding.to_parquet('share_holding.parquet')


# df_share_holding.to_csv(
#     "share_holding.csv",
#     encoding="utf_8",
#     index=False)

# %% TaiwanStockCashFlowsStatement
# 沒贊助方案-Backer, 改成一次抓一間公司的全日期資料
# 用損益表有的公司去抓現金流量表(損益表是用Backer抓的,一次單一日期所有資料)
# 損益表中有些公司是公開發行的,導致資料對應不起來,如:1716,
tmp_fin = pd.read_parquet("financial_statement.parquet")
sr_fin_code = tmp_fin.stock_id.drop_duplicates()
del [tmp_fin]
#
api = DataLoader()
api.login_by_token(api_token= token)

# token limit
url_token = "https://api.web.finmindtrade.com/v2/user_info"
headers = {"Authorization": f"Bearer {token}"}

#
df_cash_flow = pd.DataFrame()
for i in sr_fin_code:
    resp = requests.get(url_token, headers=headers)
    token_times = resp.json()["user_count"] # 使用次數
    while 600 - token_times < 50:
        print('sleep !')
        time.sleep(300)
        resp = requests.get(url_token, headers=headers)
        token_times = resp.json()["user_count"] # 使用次數
    #
    df_tmp = api.taiwan_stock_cash_flows_statement(
        stock_id= i,
        start_date='2008-06-01',
    )
    df_cash_flow = pd.concat(
        [df_cash_flow,  df_tmp],
        axis = 0
        )
    print(i)



df_cash_flow.to_parquet('cash_flows_statement.parquet')

df_cash_flow.to_csv(
    "cash_flows_statement.csv",
    encoding="utf_8",
    index=False)







