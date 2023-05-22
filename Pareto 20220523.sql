---

 ---- filter aggregate total vol at sku level, only looking at 2021 sold------
SELECT 
         distinct sku_no, 
		 sudo_tpc,
sum(isnull(cast(order_quantity as float),0)) as total_sales_volume
into #TEMP_quantile
 from [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details2_new  
 where trn_date >='2021-01-01' and trn_date <='2021-12-31' and tpc_desc not in ('CO Concessions', 'CS Consignment') and tpc_desc is not null
 group by sku_no , sudo_tpc

 select  *
 from #TEMP_quantile
 --- for each sku, calculate % of vol contribution 
 
 drop table #TEMP_quantile1

 select  distinct sku_no,
 sudo_tpc,
 total_sales_volume,
(select sum(total_sales_volume) as total  from  #TEMP_quantile ) as total_vol_all,
total_sales_volume/(select sum(total_sales_volume) as total from #TEMP_quantile )*100 as pct_vol
into #TEMP_quantile1
 from #TEMP_quantile  
 order by total_sales_volume desc
 

----- add row no, for next step cumulative sum
drop table #TEMP_quantile2
SELECT 
 ROW_NUMBER() OVER(ORDER BY total_sales_volume desc) AS Row_no,
  sku_no,
  sudo_tpc,
  total_sales_volume,
  total_vol_all,
  pct_vol
 into #TEMP_quantile2
  FROM  #TEMP_quantile1
   order by Row_no
 
---- add cumulative %
 drop table [Deals_ASX_Analysis].[dbo].TEMP_cum_vol_pct
select *,
Sum(pct_vol) Over ( Order by Row_no ) As CumSum_BySKU


into [Deals_ASX_Analysis].[dbo].TEMP_cum_vol_pct
from #TEMP_quantile2

select *
from [Deals_ASX_Analysis].[dbo].TEMP_cum_vol_pct
order by Row_no


--- by tpc as well ---
drop table #TEMP_quantile1_tpc
 select  *,
   ROW_NUMBER() OVER(ORDER BY sudo_tpc,total_sales_volume desc) AS Row_no,
   SUM (total_sales_volume) OVER (PARTITION BY sudo_tpc ORDER BY sudo_tpc) as total_vol_tpc,
   total_sales_volume/ SUM (total_sales_volume) OVER (PARTITION BY sudo_tpc ORDER BY sudo_tpc) as pct_sku_tpc
   into #TEMP_quantile1_tpc
     FROM  #TEMP_quantile
   order by Row_no

SELECT *
from #TEMP_quantile1_tpc
order by Row_no

   ---add cumulative ----
   drop table [Deals_ASX_Analysis].[dbo].DB_pareto_all_2021
 select *,
Sum(pct_sku_tpc) Over (PARTITION BY sudo_tpc  Order by Row_no ) As CumSum_sku_tpc,
count ( sku_no) OVER (PARTITION BY sudo_tpc ORDER BY Row_no) AS cum_count_sku_tpc
into [Deals_ASX_Analysis].[dbo].DB_pareto_all_2021
from #TEMP_quantile1_tpc

 select *
 from [Deals_ASX_Analysis].[dbo].DB_pareto_all_2021
 order by Row_no