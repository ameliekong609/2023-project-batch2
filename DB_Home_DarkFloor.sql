--- Dark Floor ---
---- first see pareto for all of the 3tpc for DF?

drop table #TEMP_online_trn_details_DF_2021
select *,
case when fulfil_node_no in ('1','5','8','9') then 1 else 0 end as DF_Nothland,
case when  fulfil_node_no in ('59','68','70') then 1 else 0 end as  DF_Pacific_Fair ,
case when fulfil_node_no in ('202','203','204','219','222','215','211') then 1 else 0 end as DF_Roseland 
into #TEMP_online_trn_details_DF_2021
from [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3
where sudo_tpc in ('HO Home', 'EC Entertainment', 'TO Toys') and trn_date >='2021-01-01' and trn_date <='2021-12-31'

--- at sku level, aggregate----

drop table #TEMP_aggregation_sku_Home_2021

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
sum(convert(float,DF_Nothland)) as [total_DF_Nothland_by_sku],
sum(convert(float,DF_Pacific_Fair)) as [total_DF_Pacific_Fair_by_sku],
sum(convert(float,DF_Roseland)) as [total_DF_Roseland_by_sku]
into #TEMP_aggregation_sku_Home_2021
from (select distinct sku_no from #TEMP_online_trn_details_DF_2021) as t1
left join 
(
select * from  #TEMP_online_trn_details_DF_2021) as t2
on t1. sku_no = t2.sku_no
where t2. sku_no is not null

group by  t1.sku_no,
sudo_tpc,
category_desc,
class_desc,product_type,
fashion_type,
Replenishment_Ind



select *
from #TEMP_aggregation_sku_Home_2021


--- split table ---'
 
select sku_no,
count (distinct [oms_order_no]) as total_split
into #TEMP_split_tbl_2021
from  
(select * from 
[Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3 where   trn_date >='2021-01-01' and trn_date <='2021-12-31' and 
 sudo_tpc in ('HO Home', 'EC Entertainment', 'TO Toys')) t
where   [split_flg]=1
group by  sku_no



 ----- join the two tables together ----------------------------------------
 drop table #TEMP_aggregation_sku1_2021
 select t1.*,
 case when t2.total_split is null then 0 else t2.total_split end as Total_split_sku

 into #TEMP_aggregation_sku1_2021
 from #TEMP_aggregation_sku_Home_2021 t1
left join  #TEMP_split_tbl_2021 t2
on t1.sku_no = t2. sku_no  

 
 ------add other labels ----
 

 ----overlay with TOP skus
drop table #temp_top80
  select sku_no as sku_no_top20
into #temp_top80
from [Deals_ASX_Analysis].[dbo].DB_Pareto_all_DF
where CumSum_BySKU <= 80
order by Row_no



drop table [Deals_ASX_Analysis].[dbo].DB_aggregate_DarkFloor    
 select *,
case when t2.sku_no_top20 is null then 'Not Top20' else 'Top 20' end as Top20_flg
into [Deals_ASX_Analysis].[dbo].DB_aggregate_DarkFloor    
 from #TEMP_aggregation_sku1_2021   as t1
 left join 
#temp_top80 t2
on t1.sku_no = t2.sku_no_top20



---- look at the fulfilment node----
select *
from  [Deals_ASX_Analysis].[dbo].DB_aggregate_DarkFloor 

 





