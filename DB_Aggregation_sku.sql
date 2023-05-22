------- split % over time by fulfilment node -----------

--- fr 3PL only ----
select distinct t1.sku_no,
SelectQuarter,
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
into #TEMP_aggregation_sku
from (select distinct sku_no from [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3 where  sudo_tpc ='AC Accessories' or sudo_tpc ='CH Childrenswear'  or sudo_tpc ='CM Cosmetics' or sudo_tpc ='FO Footwear' 
or sudo_tpc ='IA Intimate & Active'or sudo_tpc ='MW Menswear' or sudo_tpc = 'WW Womenswear') as t1
left join [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3 as t2
on t1. sku_no = t2.sku_no
where t2. sku_no is not null

group by  t1.sku_no,SelectQuarter,
sudo_tpc,
category_desc,
class_desc,product_type,
fashion_type,
Replenishment_Ind



--- split table ---'
 
select sku_no,
SelectQuarter,
count (distinct [oms_order_no]) as total_split
into #TEMP_split_tbl
from  [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3
where   [split_flg]=1
group by  sku_no,
SelectQuarter,
sudo_tpc


-------

 ----- population analysis --- decision tree ----------------------------------------
 
 select t1.*,
 case when t2.total_split is null then 0 else t2.total_split end as Total_split_sku

 into #TEMP_aggregation_sku1
 from #TEMP_aggregation_sku t1
left join  #TEMP_split_tbl t2
on t1.sku_no = t2. sku_no and t1.SelectQuarter =t2.SelectQuarter




 ------add other labels 

select *,
case when  ([total_3PL_by_sku] > [total_warehouse_by_sku])  and ([total_3PL_by_sku] > [total_supplier_by_sku]) and   ([total_3PL_by_sku] > [total_store_by_sku])  then '3PL'  
  when ([total_store_by_sku] > [total_3PL_by_sku])  and ([total_store_by_sku] > [total_supplier_by_sku])  and ([total_store_by_sku] > [total_warehouse_by_sku]) then 'Stores'  
  when ([total_warehouse_by_sku] > [total_3PL_by_sku])  and ([total_warehouse_by_sku] > [total_supplier_by_sku]) and  ([total_warehouse_by_sku] > [total_store_by_sku]) then 'Warehouse'  
  when ([total_supplier_by_sku] > [total_3PL_by_sku])  and ([total_supplier_by_sku] > [total_warehouse_by_sku])  and  ([total_supplier_by_sku] > [total_store_by_sku]) then 'Supplier'   else 'Others' end  as major_fulfilment_type,
 case when fashion_type ='Core item' then 'Core' else 'Non-core' end as Core_flg,
 case when Replenishment_Ind is null then 0 else Replenishment_Ind end as Replen_flg
  
  
  into [Deals_ASX_Analysis].[dbo].DB_aggregation_sku
 from #TEMP_aggregation_sku1



