---

 ---- filter aggregate total vol at sku level, only looking at 2021 sold------
 drop table #TEMP_quantile
SELECT 
         distinct sku_no, 
		 sudo_tpc,
sum(isnull(cast(order_quantity as float),0)) as total_sales_volume
into #TEMP_quantile
 from [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details2_new  
 where trn_date >='2021-01-01' and trn_date <='2021-12-31' and sudo_tpc in('CH Childrenswear'  ,'IA Intimate & Active','MW Menswear', 'WW Womenswear')
 group by sku_no , sudo_tpc


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

select * 
into #TEMP_quantile2
from (
SELECT 
 ROW_NUMBER() OVER(ORDER BY total_sales_volume desc) AS Row_no,
  sku_no,
  sudo_tpc,
  total_sales_volume,
  total_vol_all,
  pct_vol

  FROM  #TEMP_quantile1 ) t
   order by Row_no
 

---- add cumulative %
drop table #TEMP_quantile3

select *,
Sum(pct_vol) Over ( Order by Row_no ) As CumSum_BySKU

into #TEMP_quantile3
from #TEMP_quantile2
order by Row_no


drop table  [Deals_ASX_Analysis].[dbo].DB_Pareto_all_apparel

select *,
case when CumSum_BySKU <=20 then '20% Vol'
when CumSum_BySKU <= 30 then '30% Vol'
when CumSum_BySKU <= 40 then '40% Vol'
when CumSum_BySKU <=50 then '50% Vol'
when CumSum_BySKU <=60 then '60% Vol'
when CumSum_BySKU <= 70 then '70% Vol'
when CumSum_BySKU <= 80 then '80% Vol' 
when CumSum_BySKU <=90 then '90% Vol' else '100% Vol' end as Pareto_label
into [Deals_ASX_Analysis].[dbo].DB_Pareto_all_apparel
from #TEMP_quantile3
order by Row_no


select sku_no as sku_no_top20
into #temp_top80
from [Deals_ASX_Analysis].[dbo].DB_Pareto_all_apparel
where CumSum_BySKU <= 80
order by Row_no

