------------------------------------------------------------------------------------------------------
------this piece of code is to analyze the decision 
-----------------------------------------------------------------------------------------------------
----look at DF transactions in 2021 ONLY -----

drop table #TEMP_online_trn_details_DF_2021
select *
---case when fulfil_node_no in ('1','5','8','9') then 'DF Nothland'
 ---when  fulfil_node_no in ('59','68','70') then 'DF Pacific Fair' 
 ---when fulfil_node_no in ('202','203','204','219','222','215','211') then 'DF Roseland' else 'Others' end as DF_Locations
into #TEMP_online_trn_details_DF_2021
from [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details2_new
where sudo_tpc in ('HO Home', 'EC Entertainment', 'TO Toys') and trn_date >='2021-01-01' and trn_date <='2021-12-31'

select *
from #TEMP_online_trn_details_DF_2021

--- at DF ana SKU level, aggregate----

drop table #TEMP_aggregation_sku_DF_2021

select distinct sku_no,
brand,
sudo_tpc,
category_desc,
class_desc,product_type,
DF_Locations,
sum(isnull(cast(order_quantity as float),0)) as total_sales_volume_by_DF,
sum(isnull(cast([sales_order_dollars_inc_gst] as float),0)) as sales_revenue_by_DF,
count (distinct [oms_order_no]) as total_tran_by_DF
into #TEMP_aggregation_sku_DF_2021
from  #TEMP_online_trn_details_DF_2021
group by  sku_no,
brand,
sudo_tpc,
category_desc,
class_desc,product_type,
DF_Locations


---label top 80 fraom pareto analysis chart----
select *
from #TEMP_aggregation_sku_DF_2021
 ----overlay with TOP skus
drop table #temp_top80
  select sku_no as sku_no_top20
into #temp_top80
from [Deals_ASX_Analysis].[dbo].DB_Pareto_all_DF
where CumSum_BySKU <= 80
order by Row_no


drop table #DB_aggregate_DarkFloor
 select *,
case when t2.sku_no_top20 is null then 'Not Top20' else 'Top 20' end as Top20_flg
into #DB_aggregate_DarkFloor      
 from #TEMP_aggregation_sku_DF_2021   as t1
 left join 
#temp_top80 t2
on t1.sku_no = t2.sku_no_top20


----- add split rate % ------------------ THIS SHOULD BE ONLY AGGREGATED at all SKU level --------------------

--- at sku level --- redo the aggregation, this is different from the above aggregated one. that one was at level of both DF and SKU but this one here is only at sku. higher level'
drop table #TEMP_aggregation_SKU_2021
select distinct sku_no,

sum(isnull(cast(order_quantity as float),0)) as total_sales_volume_by_SKU,
sum(isnull(cast([sales_order_dollars_inc_gst] as float),0)) as sales_revenue_by_SKU,
count (distinct [oms_order_no]) as total_tran_by_SKU,
sum(convert(float,[3PL_flg])) as [total_3PL_by_SKU],
sum(convert(float,[store_flg])) as [total_store_by_SKU],
sum(convert(float,[warehouse_flg])) as [total_warehouse_by_SKU],    
sum(convert(float,[supplier_flg])) as [total_supplier_by_SKU]

into #TEMP_aggregation_SKU_2021
from   #TEMP_online_trn_details_DF_2021
group by sku_no



drop table #TEMP_split_tbl_2021
select sku_no,
count (distinct [oms_order_no]) as total_split_by_SKU
into #TEMP_split_tbl_2021
from  
(select  distinct oms_order_no,sku_no from #TEMP_online_trn_details_DF_2021
where   [split_flg]=1 ) t
group by  sku_no




 ----- join the two tables together ----------------------------------------
 drop table #TEMP_aggregation_SKU_2021_v1
 select t1.*,
 case when t2.total_split_by_SKU is null then 0 else t2.total_split_by_SKU end as Total_split_sku

 into #TEMP_aggregation_SKU_2021_v1
 from #TEMP_aggregation_SKU_2021 t1
left join  #TEMP_split_tbl_2021 t2
on t1.sku_no = t2. sku_no  

----labelling-----
drop table #TEMP_aggregation_SKU_2021_v2
select *,
case when ((isnull(cast(Total_split_sku as float),0))/ total_tran_by_SKU)*100 <=25 then '<=25%' 
when ((isnull(cast(Total_split_sku as float),0))/ total_tran_by_SKU)*100 <=50 then '25-50%' 
when ((isnull(cast(Total_split_sku as float),0))/ total_tran_by_SKU)*100 <=75 then '50-75%' 
else '>75%' end as Split_type
into #TEMP_aggregation_SKU_2021_v2
from #TEMP_aggregation_SKU_2021_v1
 

  ------add other labels ----
drop table #TEMP_aggregation_SKU_2021_v3
select *,
case when  ([total_3PL_by_SKU] > [total_warehouse_by_SKU])  and ([total_3PL_by_SKU] > [total_supplier_by_SKU]) and   ([total_3PL_by_SKU] > [total_store_by_SKU])  then '3PL'  
  when ([total_store_by_SKU] > [total_3PL_by_SKU])  and ([total_store_by_SKU] > [total_supplier_by_SKU])  and ([total_store_by_SKU] > [total_warehouse_by_SKU]) then 'Stores'  
  when ([total_warehouse_by_SKU] > [total_3PL_by_SKU])  and ([total_warehouse_by_SKU] > [total_supplier_by_sku]) and  ([total_warehouse_by_SKU] > [total_store_by_SKU]) then 'Warehouse'  
  when ([total_supplier_by_SKU] > [total_3PL_by_SKU])  and ([total_supplier_by_SKU] > [total_warehouse_by_SKU])  and  ([total_supplier_by_SKU] > [total_store_by_SKU]) then 'Supplier'   else 'Others' end  as major_fulfilment_type
  
into #TEMP_aggregation_SKU_2021_v3
from #TEMP_aggregation_SKU_2021_v2

select *
from #TEMP_aggregation_SKU_2021_v3

-----apend data togehter---
drop table [Deals_ASX_Analysis].[dbo].DB_aggregate_DarkFloor

select t1.*,
t2.total_sales_volume_by_SKU,
t2.sales_revenue_by_SKU,
t2.total_tran_by_SKU,
t2.total_3PL_by_SKU,
t2.total_store_by_SKU,
t2.total_warehouse_by_SKU,
t2.total_supplier_by_SKU,
t2.Total_split_sku,
t2.Split_type,
t2.major_fulfilment_type
into [Deals_ASX_Analysis].[dbo].DB_aggregate_DarkFloor
from #DB_aggregate_DarkFloor as t1
left join #TEMP_aggregation_SKU_2021_v3 as t2
on t1.sku_no =t2.sku_no


select *
from [Deals_ASX_Analysis].[dbo].DB_aggregate_DarkFloor
order by sku_no


--------------------to find 2386 skus ------------------------------
select distinct sku_no, brand

from  [Deals_ASX_Analysis].[dbo].DB_aggregate_DarkFloor
where Top20_flg='Top 20' and major_fulfilment_type ='Stores' and Split_type  in ('<=25%', '25-50%')