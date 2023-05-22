----wash 3PL existing vs added in 

--- STEP1 -- MAP the tranche numbers to each skus
 select t1.*, t2.TPC_Brand, t2.Pareto_label, t2.NDC_Store_1, t2.NDC_Store_2, t2.CAFA_ind,
 case when CumSum_BySKU <= 80 then 'Tranche 1'
 when CumSum_BySKU <= 95 then 'Tranche 2'
 else 'Tranche 3' end as Tranche
 into [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE
 from [Deals_ASX_Analysis].[dbo].DB_DT_all_2021 t1
 left join 
 [Deals_ASX_Analysis].[dbo].DB_DT_NDC_Stores t2
 on t1.sku_no = t2.sku_no

---current 56311 allocation ---
select Tranche,
count (distinct sku_no) as sku_cnt
 from  [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE 
 where major_fulfilment_type ='3PL' 
 group by Tranche


 ----get the new oppr   20375
select Tranche,Core_flg,
count (distinct sku_no) as sku_cnt
 from [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE
 where Core_flg in ('Replen Core' , 'Fashion_Seasonal_Trend') and major_fulfilment_type ='Stores' and Tranche ='Tranche 1'
 group by Tranche,Core_flg

------ WASH 1 ---- ASSOCIATION AGAINGST OPPOR  
drop table #TEMP_WASH1
 select distinct t1.SKU_A, t2.Tranche
 into #TEMP_WASH1
 from [Deals_ASX_Analysis].[dbo].TEMP_Association_horizontal as t1     
 left join 
 ------ the below is the new opportunity ---
 ( select * from [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE
 where Core_flg in ('Replen Core' , 'Fashion_Seasonal_Trend') and major_fulfilment_type ='Stores' and Tranche ='Tranche 1')t2
 ----end of NEW OPP  ---
 on t1.SKU_A = t2.sku_no
where t2.sku_no is  null    ---- this is to get the real add on count  ---


 ------------------------ WASH 2 -- assocciation against existing 3PL 50311----------------
 drop table #TEMP_WASH2
 select t1.sku_A,t3.Tranche
 into #TEMP_WASH2
 from #TEMP_WASH1   t1 ----56311
 left join 
 ----- the below is 3PL current
 (select sku_no from  [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE  where major_fulfilment_type ='3PL' ) t2   
 ----- end of 3PL current
 on t1.sku_A = t2.sku_no
 left join 
 (select * from  [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE  ) t3
 on t1.sku_A = t3.sku_no
 where t2.sku_no is null
  
  ------summary ----
select Tranche,
count (distinct sku_A) as sku_cnt
 from #TEMP_WASH2
 group by Tranche

---------------------------wash vertical ------
---wash 1 
drop table #TEMP_WASH1_VERTICAL
select distinct t1.SKU_ID 
into #TEMP_WASH1_VERTICAL
 from [Deals_ASX_Analysis].[dbo].TEMP_Association_vertical as t1     ----real addon  10061
 left join 
 ------ the below is the new opportunity ---
 ( select * from [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE
 where Core_flg in ('Replen Core' , 'Fashion_Seasonal_Trend') and major_fulfilment_type ='Stores' and Tranche ='Tranche 1')t2
 ----end of NEW OPP  ---
 on t1.SKU_ID = t2.sku_no
where t2.sku_no is  null


 ------------------------ WASH 2 -- vertical assocciation against existing 3PL 50311----------------
 drop table #TEMP_WASH2_vertical
 select t1.*
 into #TEMP_WASH2_vertical
 from #TEMP_WASH1_VERTICAL   t1 ----56311
 left join 
 ----- the below is 3PL current
 (select sku_no from  [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE  where major_fulfilment_type ='3PL' ) t2   
 ----- end of 3PL current
 on t1.SKU_ID = t2.sku_no
 where t2.sku_no is null

 ----wash 3 wash against horizontal association

 select t1.SKU_ID, t3.Tranche
 into #TEMP_WASH2_vertical_v1
 from #TEMP_WASH2_vertical   t1 
 left join #TEMP_WASH2 t2    
 on t1.SKU_ID = t2.sku_A
 left join 
 (select * from  [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE  ) t3
 on t1.SKU_ID = t3.sku_no
 where t2.sku_A is null


 ------summary ----
select Tranche,
count (distinct SKU_ID) as sku_cnt
 from #TEMP_WASH2_vertical_v1
 group by Tranche


 --------union 3PL expected final look in one table -----
 select * 
 into #TEMP_3PL_TRANCHE_EXPECTED FROM
 (
 (select sku_no,Tranche  from  [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE 
 where major_fulfilment_type ='3PL' ) 
 union 
  (select sku_no,Tranche from [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE
 where Core_flg in ('Replen Core' , 'Fashion_Seasonal_Trend') and major_fulfilment_type ='Stores' and Tranche ='Tranche 1')  
 union 
 (select sku_A as sku_no,Tranche from #TEMP_WASH2)
 union 
 (select SKU_ID as sku_no,Tranche from #TEMP_WASH2_vertical_v1)) TEMP

----MAP THESE EXPECTED SKUS WITH TYPES----

drop table #TEMP_3PL_TRANCHE_EXPECTED_V1
 select t1.* , 
 t2.sku_desc, 
 t2. brand, 
 t2.sudo_tpc, 
 t2.Replenishment_Ind, 
 t2.fashion_type, 
 t2.Product_Type, 
 t2.Product_life_weeks,
case when Product_Type = 'Exit/Clearance' then 'Exit/Clearance' 
     when Product_Type = 'Ongoing' and fashion_type <> 'Core Item'  and Product_life_weeks <52 then 'Ongoing - Fashion_Trend_<52' 
	 when Product_Type = 'Ongoing' and fashion_type <> 'Core Item'  and Product_life_weeks >=52  or  Product_life_weeks is null then 'Ongoing - Fashion_Trend_>52' 
	 when Product_Type = 'Ongoing' and fashion_type = 'Core Item' or fashion_type is null then 'Ongoing - Core' else 'Others' end as Product_type1
into #TEMP_3PL_TRANCHE_EXPECTED_V1
 from #TEMP_3PL_TRANCHE_EXPECTED t1
 left join 
  [Deals_ASX_Analysis].[dbo].Temp_CY2021_product_life_weeks_final t2
  on t1.sku_no = t2.sku_no


select Product_type1,Replenishment_Ind,Tranche,
count(distinct sku_no), 
avg(isnull(cast(Product_life_weeks as float),0)) as avg_weeks
from #TEMP_3PL_TRANCHE_EXPECTED_V1
group by Product_type1, Replenishment_Ind,Tranche

 
 ------ 3pl overlay ---
 select t1.sku_no, t1.Replenishment_Ind,t1.Tranche, t2.Product_type1
 into #TEMP_3PL_OVERLAY
  from 
  (select * from [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE 
 where major_fulfilment_type ='3PL' ) t1
 left join 
 #TEMP_3PL_TRANCHE_EXPECTED_V1 t2
 on t1. sku_no = t2.sku_no

 ---summarise
 select Product_type1,Replenishment_Ind,Tranche,
count(distinct sku_no)

from #TEMP_3PL_OVERLAY
group by Product_type1, Replenishment_Ind,Tranche

--- opportunity overlay ---

  select t1.sku_no, t1.Core_flg,t1.Replenishment_Ind,t1.Tranche, t2.Product_type1
 into #TEMP_oppor_OVERLAY
  from 
  (select * from [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE
 where Core_flg in ('Replen Core' , 'Fashion_Seasonal_Trend') and major_fulfilment_type ='Stores' and Tranche ='Tranche 1' ) t1
 left join 
 #TEMP_3PL_TRANCHE_EXPECTED_V1 t2
 on t1. sku_no = t2.sku_no

  ---summarise
 select Core_flg,Product_type1, Replenishment_Ind,Tranche,
count(distinct sku_no)

from #TEMP_oppor_OVERLAY
group by Core_flg,Product_type1, Replenishment_Ind,Tranche



-----  overlay with association ---

select t1.sku_A, t2.Replenishment_Ind,t2.Tranche, t2.Product_type1
 into #TEMP_association_OVERLAY
  from #TEMP_WASH2 t1
 left join 
 #TEMP_3PL_TRANCHE_EXPECTED_V1 t2
 on t1. sku_A = t2.sku_no

---summarise
 select Product_type1, Replenishment_Ind,Tranche,
count(distinct sku_A)

from #TEMP_association_OVERLAY
group by Product_type1, Replenishment_Ind,Tranche

---------ovely with vertical association -----

select t1.sku_ID, t2.Replenishment_Ind,t2.Tranche, t2.Product_type1
 into #TEMP_vertical_OVERLAY
  from #TEMP_WASH2_vertical_v1 t1
 left join 
 #TEMP_3PL_TRANCHE_EXPECTED_V1 t2
 on t1. sku_ID = t2.sku_no

 ---summarise
 select Product_type1, Replenishment_Ind,Tranche,
count(distinct sku_ID)

from #TEMP_vertical_OVERLAY
group by Product_type1, Replenishment_Ind,Tranche