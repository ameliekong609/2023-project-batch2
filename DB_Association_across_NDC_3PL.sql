---this code is to do association at sku level to see what are normally paired together at class level

---step1 only look at focus group -- top 20, fast sales, and stores
DROP TABLE #TEMP_focus_apparel
 select t1.*
 into #TEMP_focus_apparel
 from 
 (select * from [Deals_ASX_Analysis].[dbo].DB_DT_NDC_Stores
 where NDC_Store_1='NDC Pareto 80' ) t1
 left join 
 (select * from [Deals_ASX_Analysis].[dbo].DB_DT_all_2021 )t2
 on t1.sku_no = t2.sku_no
 where Core_flg in ('Replen Core' , 'Fashion_Seasonal_Trend') and major_fulfilment_type ='Stores'




 ---step 2 for these skus, we map with order id --
 
 drop table #TEMP_focus_apparel_association
 SELECT t1.*,
 t2.[oms_order_no]
 into #TEMP_focus_apparel_association
 FROM #TEMP_focus_apparel  as t1
 LEFT JOIN 
 (
 SELECT DISTINCT SKU_NO, [oms_order_no] FROM [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details2_new WHERE sudo_tpc in ('CM Cosmetics','CH Childrenswear' ,'IA Intimate & Active','MW Menswear' , 'WW Womenswear','AC Accessories' ) and trn_date >='2021-01-01' and trn_date <='2021-12-31') as t2
on t1.sku_no = t2.sku_no

 
 SELECT * FROM #TEMP_focus_apparel_association
---third, from these mapped order id, we further map with other skus (not them selves)
--- also for each sku pair, we can aggregrate total vol and association %

drop table [Deals_ASX_Analysis].[dbo].TEMP_Association_horizontal

select t1.sku_no, 
t1.brand,
t1.sudo_tpc,
t1.TPC_Brand,
t1.total_sales_volume,

t2.sku_no as sku_A,
t2.sku_desc as sku_desc_A,
t2.[sudo_tpc] as TPC_A,
t2.brand as BRAND_A,
t2.class_desc as CLASS_A,
t2.product_type as Product_type_A,
sum(isnull(cast(t2.order_quantity as float),0)) as Quantity_A,
(sum(isnull(cast(t2.order_quantity as float),0))/ total_sales_volume)*100 as association_pct
into [Deals_ASX_Analysis].[dbo].TEMP_Association_horizontal
from #TEMP_focus_apparel_association t1
left join 
(
select   [oms_order_no],[sudo_tpc],class_desc, brand,sku_no, order_quantity,sku_desc,product_type
From [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details2_new where trn_date >='2021-01-01' and trn_date <='2021-12-31' and sudo_tpc in ('CM Cosmetics','CH Childrenswear' ,'IA Intimate & Active','MW Menswear' , 'WW Womenswear','AC Accessories' )) as t2
on t1.oms_order_no = t2.oms_order_no and t1.sku_no <>t2.sku_no 

group by t1.sku_no, 
t1.brand,
t1.sudo_tpc,
t1.TPC_Brand,
t1.total_sales_volume,
t2.sku_no  ,
t2.[sudo_tpc]  ,t2.sku_desc ,
t2.brand  ,
t2.class_desc  ,t2.product_type
having t2.sku_no is not null 
ORDER BY t1.sku_no, 
t1.brand,
t1.sudo_tpc,
t1.TPC_Brand,
t1.total_sales_volume,
t2.sku_no  ,
t2.[sudo_tpc]  ,t2.sku_desc ,
t2.brand  ,
t2.class_desc  ,t2.product_type

-----
SELECT DISTINCT sku_A
FROM [Deals_ASX_Analysis].[dbo].TEMP_Association_horizontal



------allocate them to each cohort ---
select Pareto_label,
count(distinct sku_A) 
from 
(select t1.sku_A,t2.Pareto_label
from [Deals_ASX_Analysis].[dbo].TEMP_Association_horizontal as t1
left join  [Deals_ASX_Analysis].[dbo].DB_DT_NDC_Stores as t2
on t1.sku_A = t2.sku_no
where t2.sku_no is not null) as t3
group by Pareto_label




 



  


