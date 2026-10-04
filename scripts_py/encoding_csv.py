# -*- coding: utf-8 -*-
"""
Created on Sun May 24 20:55:31 2026

@author: e1155_l2c4ye3
"""
import pandas as pd
import numpy as np
# %% read 上市,上櫃,興櫃 的公司基本資料
# https://mops.twse.com.tw/mops/#/web/t51sb01
twse = pd.read_csv('twse_company_information.csv', 
                   encoding = 'cp950',
                   # dtype = {'公司代號':'string'},
                   dtype = 'string',
                   encoding_errors = 'replace'
                   )

#
otc = pd.read_csv('otc_company_information.csv', 
                   encoding = 'cp950',
                   # dtype = {'公司代號':'string'},
                   dtype = 'string',
                   encoding_errors = 'replace'
                   )

#
emerging = pd.read_csv('emerging_company_information.csv', 
                   encoding = 'cp950',
                   # dtype = {'公司代號':'string'},
                   dtype = 'string',
                   encoding_errors = 'replace'
                   )
#
# colname 都一樣, 只差在 上市日期-上櫃日期-興櫃日期 而已
# tmp_a = otc.loc[:,twse.columns != otc.columns]
# tmp_b = emerging.loc[:,twse.columns != emerging.columns]

# %% read 下市,下櫃 公司基本資料, 下興櫃沒資料 
# https://mops.twse.com.tw/mops/#/web/t51sb01_1
# 下市的資料表不包含公司的產業,但可以依產業下載資料
# 故抓完全部資料再抓金融業的資料,再自己標記金融業
# colnames 也是只差在-上櫃日期':'上市日期','下櫃日期':'下市日期'
                     
de_twse_all = pd.read_csv('de_twse_company_all.csv', 
                   encoding = 'cp950',
                   # dtype = {'公司代號':'string'},
                   dtype = 'string',
                   encoding_errors = 'replace',
                   index_col = False
                   )
de_twse_finance = pd.read_csv('de_twse_company_finance.csv', 
                   encoding = 'cp950',
                   # dtype = {'公司代號':'string'},
                   dtype = 'string',
                   encoding_errors = 'replace',
                   index_col = False
                   )

de_otc_all = pd.read_csv('de_otc_company_all.csv', 
                   encoding = 'cp950',
                   # dtype = {'公司代號':'string'},
                   dtype = 'string',
                   encoding_errors = 'replace',
                   index_col = False
                   )
de_otc_finance = pd.read_csv('de_otc_company_finance.csv', 
                   encoding = 'cp950',
                   # dtype = {'公司代號':'string'},
                   dtype = 'string',
                   encoding_errors = 'replace',
                   index_col = False
                   )


# %% to_csv 上市,上櫃,興櫃 公司基本資料

company_info = pd.concat(
    [
     twse.assign(market = 'twse'),
     otc.assign(market = 'otc').rename(
         columns = {'上櫃日期':'上市日期'}),
     emerging.assign(market = 'emerging').rename(
         columns = {'興櫃日期':'上市日期'})
    ],
    axis = 0
    )
# 更改 colname 順序, 把 market 放到第一個 col
cols = ['market'] + twse.columns.to_list()
company_info = company_info[cols]

# 基本資料編碼統一改成 utf_8,
# Field delimiter 改為 '^', 避免匯入 MSSQL 時出現資料位移問題
company_info.to_csv("company_information.csv",
            index=False,
            sep = '^',
            encoding="utf_8")


# %%  to_csv 下市,下櫃  公司基本資料
# 把資料補上市場別-'market' 和 產業類別-'industry'

de_company_info = pd.concat(
    [
     de_twse_all.assign(
         market = 'de_twse',
         industry = lambda x: np.select(
             [x.公司代號.isin(de_twse_finance.公司代號)],
             ['金融業'],
             'unknown'
             )),
     de_otc_all.assign(
         market = 'de_otc',
         industry = lambda x: np.select(
             [x.公司代號.isin(de_otc_finance.公司代號)],
             ['金融業'],
             'unknown'
             )).rename(columns = {'上櫃日期':'上市日期',
                                  '下櫃日期':'下市日期'})
    ],
    axis = 0
    )


cols = ['market','industry'] + de_twse_all.columns.to_list()
de_company_info = de_company_info[cols]


# 基本資料編碼統一改成 utf_8,
# Field delimiter 改為 '^', 避免匯入 MSSQL 時出現資料位移問題
de_company_info.to_csv("de_company_information.csv",
            index=False,
            sep = '^',
            encoding="utf_8")





