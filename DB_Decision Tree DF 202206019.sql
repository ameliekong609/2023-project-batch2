-------------------------------------------------------------------------------------------------
----- this piece of code is to create decision Tree of Dark floor SKUs
-------------------------------------------------------------------------------------------------

----Step 1 -- only have transactions from 2021 from the range of HOME Entertainment and Toys----
drop table #TEMP_online_trn_details_DF_2021

select *
into #TEMP_online_trn_details_DF_2021
from [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details2_new
where sudo_tpc in ('HO Home', 'EC Entertainment', 'TO Toys') and trn_date >='2021-01-01' and trn_date <='2021-12-31'


--- Step 2 - at sku level, create the aggregate the data -------

drop table #TEMP_aggregation_sku_DF_2021_v1
select distinct sku_no,

brand,
sudo_tpc,
category_desc,category_no,
class_desc,product_type,
sum(isnull(cast(order_quantity as float),0)) as total_sales_volume_by_SKU,
sum(isnull(cast([sales_order_dollars_inc_gst] as float),0)) as sales_revenue_by_SKU,
count (distinct [oms_order_no]) as total_tran_by_SKU,
sum(convert(float,[3PL_flg])) as [total_3PL_by_SKU],   -- for each sku, how many  orders (with duplication)_ that have been fulfiled by 3PL---
sum(convert(float,[store_flg])) as [total_store_by_SKU],
sum(convert(float,[warehouse_flg])) as [total_warehouse_by_SKU],    
sum(convert(float,[supplier_flg])) as [total_supplier_by_SKU]

into #TEMP_aggregation_sku_DF_2021_v1
from   #TEMP_online_trn_details_DF_2021
group by sku_no,brand,
sudo_tpc,
category_desc,category_no,
class_desc,product_type

----step 3 -find the split transactions ----
 drop table #TEMP_split_tbl_2021
select sku_no,
count (distinct [oms_order_no]) as total_split_by_SKU   ---for each sku,  how many DISTINCT Orders have been split,( if this sku ever is associated with any split orders )
into #TEMP_split_tbl_2021
from  
(select  distinct oms_order_no,sku_no from #TEMP_online_trn_details_DF_2021
where   [split_flg]=1 ) t
group by  sku_no


----Step 4 - join the two tables together ----------------------------------------
 drop table #TEMP_aggregation_sku_DF_2021_v2
 select t1.*,
 case when t2.total_split_by_SKU is null then 0 else t2.total_split_by_SKU end as Total_split_sku

 into #TEMP_aggregation_sku_DF_2021_v2
 from #TEMP_aggregation_sku_DF_2021_v1 t1
left join  #TEMP_split_tbl_2021 t2
on t1.sku_no = t2. sku_no  


----Step 5 - labelling-----
drop table #TEMP_aggregation_sku_DF_2021_v3
select *,
case when ((isnull(cast(Total_split_sku as float),0))/ total_tran_by_SKU)*100 <=25 then '<=25%' 
when ((isnull(cast(Total_split_sku as float),0))/ total_tran_by_SKU)*100 <=50 then '25-50%' 
when ((isnull(cast(Total_split_sku as float),0))/ total_tran_by_SKU)*100 <=75 then '50-75%' 
else '>75%' end as Split_type
into #TEMP_aggregation_sku_DF_2021_v3
from #TEMP_aggregation_sku_DF_2021_v2


  ------add other labels of major fulfilment node. ONE sku may be fulfiled by multiple channels----
drop table #TEMP_aggregation_sku_DF_2021_v4
select *,
case when  ([total_3PL_by_SKU] > [total_warehouse_by_SKU])  and ([total_3PL_by_SKU] > [total_supplier_by_SKU]) and   ([total_3PL_by_SKU] > [total_store_by_SKU])  then '3PL'  
  when ([total_store_by_SKU] > [total_3PL_by_SKU])  and ([total_store_by_SKU] > [total_supplier_by_SKU])  and ([total_store_by_SKU] > [total_warehouse_by_SKU]) then 'Stores'  
  when ([total_warehouse_by_SKU] > [total_3PL_by_SKU])  and ([total_warehouse_by_SKU] > [total_supplier_by_sku]) and  ([total_warehouse_by_SKU] > [total_store_by_SKU]) then 'Warehouse'  
  when ([total_supplier_by_SKU] > [total_3PL_by_SKU])  and ([total_supplier_by_SKU] > [total_warehouse_by_SKU])  and  ([total_supplier_by_SKU] > [total_store_by_SKU]) then 'Supplier'   else 'Others' end  as major_fulfilment_type
  
into #TEMP_aggregation_sku_DF_2021_v4
from #TEMP_aggregation_sku_DF_2021_v3




---label top 80 fraom pareto analysis chart----
 
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
into #DB_aggregate_DarkFloor      
 from #TEMP_aggregation_sku_DF_2021_v4   as t1
 left join 
#temp_top80 t2
on t1.sku_no = t2.sku_no_top20


-------------------------add the new label of hard or soft goods -----------------------------
select *,
case when sudo_tpc = 'EC Entertainment' and category_no in (' 560','561','562','565','566') then 'Appliances'
when sudo_tpc = 'EC Entertainment' and category_no in (' 552','553','554','556','558','563','567') then 'Electical'
when sudo_tpc = 'HO Home' and category_no in (' 650','651','652','655','656' ) then 'General Merchandise'
when sudo_tpc = 'HO Home' and category_no in (' 500','503','512','514'  ) then 'Hard Home'
when sudo_tpc = 'HO Home' and category_no in (' 504','506','507','508' ,'510' ) then 'Soft Home'
when sudo_tpc = 'EC Entertainment' and category_no = '107' then 'Travel Goods' else 'Others' end  as 'Hard_Soft'
into [Deals_ASX_Analysis].[dbo].DB_aggregate_DarkFloor 
from #DB_aggregate_DarkFloor
 

--------------------filter those <50% only and find their Hard Soft ------------------------
select Hard_Soft,
count (distinct sku_no)
from [Deals_ASX_Analysis].[dbo].DB_aggregate_DarkFloor 
where Split_type in  ('<=25%' , '25-50%' ) AND Top20_flg = 'Top 20' AND major_fulfilment_type ='Stores'
group by Hard_Soft