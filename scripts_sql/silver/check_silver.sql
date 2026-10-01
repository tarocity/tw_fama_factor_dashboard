
-- 新聞: 2025 年 7 月 30：鴻海（2317）與 東元（1504）聯合停牌
-- 新聞: 台泥（1101）因有重訊待公布2025/8/13起暫停交易
-- 調整股價以上一個交易日資料呈現,交易量資料以 0 呈現
SELECT 
*
FROM bronze.adj_price
WHERE stock_id IN ('2317','1504','1101') 
AND YEAR(trade_date) = 2025 
AND MONTH(trade_date) IN (7,8)
ORDER BY trade_date

-- 後來發現無交易還是會有直接消失的資料,
-- 如'3485'的2016-01-30資料不存在
SELECT
*
FROM bronze.adj_price
WHERE stock_id IN ('1101','3485') 
AND YEAR(trade_date) IN (2016)
AND MONTH(trade_date) IN (1,2)
ORDER BY trade_date
--

-- 檢查每月最後一天交易日期與市場不同的股票
-- 滿多股票是因為減資所以暫停交易,導致沒有交易資料
-- 跟上述 鴻海（2317）與 東元（1504）不同
-- 有停止交易當天資料(交易量 = 0, 價格 = 上個交易日價格)
-- 市值表的狀況類似, 有時候是有資料(市值 = 0), 有時候沒資料
-- ===================================================
-- 結論: 計算月報酬跟月底市值, 抓取該股票當月的最後一筆資料,
-- 不統一使用市場每月的最後一天交易日, 去計算月報酬跟月市值
-- 在抓取月底市值資料前, 先剔除市值 = 0 的資料
WITH cte_sl AS(
SELECT
stock_id,
DATETRUNC(MONTH,trade_date) AS s_month,
MAX(trade_date) AS s_last
FROM bronze.adj_price 
WHERE YEAR(trade_date) >= 2012
GROUP BY DATETRUNC(MONTH,trade_date), stock_id
),
cte_al AS(
SELECT
DATETRUNC(MONTH,trade_date) AS a_month,
MAX(trade_date) AS a_last
FROM bronze.adj_price
WHERE YEAR(trade_date) >= 2012
GROUP BY DATETRUNC(MONTH,trade_date) 
),
cte_join AS(
SELECT
s.*,
a.a_last
FROM cte_sl s
LEFT JOIN cte_al a
ON s.s_month = a.a_month
)

SELECT
*
FROM cte_join AS cte
WHERE s_last != a_last
AND s_month < '2026-05-01'
AND EXISTS (
SELECT
	1	
FROM silver.company_industry AS ci
WHERE 
industry_category NOT IN ('金融保險業','金融業') AND
market != 'emerging' AND
ci.company_id = cte.stock_id 
)
ORDER BY a_last
