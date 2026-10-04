# -*- coding: utf-8 -*-
"""
Created on Fri Jun  5 17:07:03 2026

@author: e1155_l2c4ye3
"""

import pandas as pd

# %%  tw_10y_gov_bond_yield
#  https://hk.investing.com/rates-bonds/taiwan-10-year-bond-yield-historical-data


df_10y_bond_0 = pd.read_csv('臺灣十年期國債債券收益率_0.csv')
df_10y_bond_1 = pd.read_csv('臺灣十年期國債債券收益率_1.csv')
df_10y_bond_2 = pd.read_csv('臺灣十年期國債債券收益率_2.csv')

df_10y_bond = pd.concat(
    [df_10y_bond_0,
     df_10y_bond_1,
     df_10y_bond_2]
    ,axis = 0).drop_duplicates()



# %% df_10y_bond.to_csv
# 統一編碼 utf_8
df_10y_bond.to_csv(
    "tw_10y_gov_bond_yield.csv",
    encoding="utf_8",
    index=False)


