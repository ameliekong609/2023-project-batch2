----look at 2021 calendar year ----
------- split % over time by fulfilment node -----------

drop table  #TEMP_aggregation_apparel_2021
select distinct t1.sku_no,
sudo_tpc,
category_desc,
class_desc,product_type,
fashion_type,
Replenishment_Ind,
sum(isnull(cast(order_quantity as float),0)) as total_sales_volume,
sum(isnull(cast([sales_order_dollars_inc_gst] as float),0)) as sales_revenue,
count (distinct [oms_order_no]) as total_tran,
--sum(convert(float,[split_flg])) as [total_split],
sum(convert(float,[3PL_flg])) as [total_3PL_by_sku],
sum(convert(float,[store_flg])) as [total_store_by_sku],
sum(convert(float,[warehouse_flg])) as [total_warehouse_by_sku],    
sum(convert(float,[supplier_flg])) as [total_supplier_by_sku]

into #TEMP_aggregation_apparel_2021

from (select distinct sku_no from [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3 

where  sudo_tpc in ('CH Childrenswear' ,'IA Intimate & Active','MW Menswear' , 'WW Womenswear' )
and trn_date >='2021-01-01' and trn_date <='2021-12-31') as t1
left join 
(select * from
[Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3  where trn_date >='2021-01-01' and trn_date <='2021-12-31' 
AND   sudo_tpc in ('CH Childrenswear' ,'IA Intimate & Active','MW Menswear' , 'WW Womenswear' )) as t2
on t1. sku_no = t2.sku_no
where t2. sku_no is not null

group by  t1.sku_no,
sudo_tpc,
category_desc,
class_desc,product_type,
fashion_type,
Replenishment_Ind



--- split table ---'
 drop table  #TEMP_split_apparel_2021
select sku_no,
count (distinct [oms_order_no]) as total_split
into #TEMP_split_apparel_2021
from  
(select * from 
[Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3 where   trn_date >='2021-01-01' and trn_date <='2021-12-31' 
and sudo_tpc in ('CH Childrenswear' ,'IA Intimate & Active','MW Menswear' , 'WW Womenswear' )) t
where   [split_flg]=1
group by  sku_no



 ----- join the two tables together ----------------------------------------
 drop table #TEMP_aggregation_apparel_2021_v1
 select t1.*,
 case when t2.total_split is null then 0 else t2.total_split end as Total_split_sku

 into #TEMP_aggregation_apparel_2021_v1
 from #TEMP_aggregation_apparel_2021 t1
left join  #TEMP_split_apparel_2021 t2
on t1.sku_no = t2. sku_no  

 

 ------add other labels ----
 drop table #DB_aggregation_apparel_2021
select *,
case when  ([total_3PL_by_sku] > [total_warehouse_by_sku])  and ([total_3PL_by_sku] > [total_supplier_by_sku]) and   ([total_3PL_by_sku] > [total_store_by_sku])  then '3PL'  
  when ([total_store_by_sku] > [total_3PL_by_sku])  and ([total_store_by_sku] > [total_supplier_by_sku])  and ([total_store_by_sku] > [total_warehouse_by_sku]) then 'Stores'  
  when ([total_warehouse_by_sku] > [total_3PL_by_sku])  and ([total_warehouse_by_sku] > [total_supplier_by_sku]) and  ([total_warehouse_by_sku] > [total_store_by_sku]) then 'Warehouse'  
  when ([total_supplier_by_sku] > [total_3PL_by_sku])  and ([total_supplier_by_sku] > [total_warehouse_by_sku])  and  ([total_supplier_by_sku] > [total_store_by_sku]) then 'Supplier'   else 'Others' end  as major_fulfilment_type,
 case when (fashion_type ='Core item' and Replenishment_Ind =1 ) then 'Fast Sales - Core' 
 when (fashion_type <> 'Core item') then 'Fashion_Seasonal_Trend' else 'Others' end as Core_flg
  
  
  into #DB_aggregation_apparel_2021
 from #TEMP_aggregation_apparel_2021_v1


 ----overlay with TOP skus
 drop table #temp_top80

  select sku_no as sku_no_top20
into #temp_top80
from [Deals_ASX_Analysis].[dbo].DB_Pareto_all_apparel
where CumSum_BySKU < 80
order by Row_no
 
drop table [Deals_ASX_Analysis].[dbo].DB_aggregation_apparel_2021

 select *,
case when t2.sku_no_top20 is null then 'Not Top20' else 'Top 20' end as Top20_flg
into [Deals_ASX_Analysis].[dbo].DB_aggregation_apparel_2021    ----this is transaction table -------
 from #DB_aggregation_apparel_2021   as t1
 left join 
#temp_top80 t2
on t1.sku_no = t2.sku_no_top20
 


