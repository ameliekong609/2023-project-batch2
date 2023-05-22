---- this code is for association analysis with substyle----
---- the logic is
--- firstly filter skus that we want to focus based on the decition tree --Top 20 --> Fast sales --> Stores
---please note the data (DB_aggregation_apparel_2021) is from "DB_Aggregation_Apparel_2021_20220614"
---second, aggregate Luke's data to see how many Sku in total for one particular Substyle
---third, join focus table and luke's table together, and caculate how many sku in OUR focus are there for one particular substyle
--- the difference between TOTAL_SKU_curr and TOTAL_SKU are those sku extension because of Substyle.


 --------------------------------------------analysis of SUbstyle ---------------------------
 select t1.sku_no,t1.sudo_tpc,Core_flg, major_fulfilment_type
 into #TEMP_focus_apparel
 from 
 (select * from [Deals_ASX_Analysis].[dbo].DB_DT_NDC_Stores
 where NDC_Store_1='NDC Pareto 80' ) t1
 left join 
 (select * from [Deals_ASX_Analysis].[dbo].DB_DT_all_2021 )t2
 on t1.sku_no = t2.sku_no
 where Core_flg in ('Replen Core' , 'Fashion_Seasonal_Trend') and major_fulfilment_type ='Stores'
 
 --------------------------  for each sku, we know the total complete count of each substyle --------------
  SELECT DISTINCT PLANNING_SUBSTYLE_ID, PLANNING_SUBSTYLE_DESC,
 COUNT (DISTINCT SKU_ID) AS TOTAL_SKU
 INTO #TEMP_SUBSTYLE_LIST
 FROM [Deals_ASX_Analysis].[dbo].Myer_LUKED_ONLINE_SKU_LIST
 GROUP BY PLANNING_SUBSTYLE_ID, PLANNING_SUBSTYLE_DESC


 ----------------join tables above together by SKU_no, so that we can attach their substyle id for these existing SKU ---
 drop table [Deals_ASX_Analysis].[dbo].TEMP_focus_apparel_v1
 select *
 INTO [Deals_ASX_Analysis].[dbo].TEMP_focus_apparel_v1
 from #TEMP_focus_apparel t1
 left join [Deals_ASX_Analysis].[dbo].Myer_LUKED_ONLINE_SKU_LIST t2
 ON t1.sku_no = t2.SKU_ID

 ---------------------this is to count how mnay existing skus for each sub style--------------------------------------

 SELECT DISTINCT PLANNING_SUBSTYLE_ID, PLANNING_SUBSTYLE_DESC,
 COUNT (DISTINCT SKU_ID) AS TOTAL_SKU_curr
 INTO #TEMP_focus_apparel_v2
 FROM [Deals_ASX_Analysis].[dbo].TEMP_focus_apparel_v1
 GROUP BY PLANNING_SUBSTYLE_ID, PLANNING_SUBSTYLE_DESC

 ----------------------------------for each SUBSTYLE, we now know the total and the current 8156---
 select *
 from #TEMP_focus_apparel_v2 t1
 left join #TEMP_SUBSTYLE_LIST t2   --- this is total
 on t1.PLANNING_SUBSTYLE_ID= t2.PLANNING_SUBSTYLE_ID  

 --------------------------- by this far, i finished the counting, and the next step is to find the SKUS-----

 -----------------------the following is to find the additional sku expansion due to sizing issues, we put in yellow dash box 
 
----Step 1 - how to find the entire full size range from Luke' data. for those current sku range --
drop table #TEMP_total_sizing_sku
select t1.*
into #TEMP_total_sizing_sku
from 
(select
distinct SKU_ID, PLANNING_SUBSTYLE_ID  from [Deals_ASX_Analysis].[dbo].Myer_LUKED_ONLINE_SKU_LIST)  as t1
inner join 
(select distinct PLANNING_SUBSTYLE_ID from [Deals_ASX_Analysis].[dbo].TEMP_focus_apparel_v1) as t2
on t1.PLANNING_SUBSTYLE_ID = t2.PLANNING_SUBSTYLE_ID


----------Step 2 - how to find those left over those additional in yellow dash box --
drop table #TEMP_leftover_skus
select t1.SKU_ID 
into #TEMP_leftover_skus
from #TEMP_total_sizing_sku as t1
left join [Deals_ASX_Analysis].[dbo].TEMP_focus_apparel_v1 as t2
on t1.sku_id = t2.sku_no
where t2.sku_no is null

select distinct SKU_ID
from #TEMP_leftover_skus



---find the range of these leftover skus
drop table [Deals_ASX_Analysis].[dbo].TEMP_Association_vertical
select distinct SKU_ID  
into [Deals_ASX_Analysis].[dbo].TEMP_Association_vertical
from #TEMP_leftover_skus as t1
left join  [Deals_ASX_Analysis].[dbo].DB_DT_NDC_Stores as t2
on t1.SKU_ID = t2.sku_no
where t2.sku_no is not null   ---- the gap is those skus not selling in 2021)


SELECT * FROM  #TEMP_leftover_skus_v1   



----- wash CAFA and SUBSYLTE ----- there are dup
select distinct SKU_A 
--into #temp_wash
from (
select SKU_A from #temp_real_hori_v1   ----112061
union 
select SKU_ID as sku_no from #TEMP_leftover_skus_v1  --- 10061
)temp


------ de dup
 select distinct t1.SKU_A 
 into #temp_wash_v1
 from #temp_wash as t1     ----real addon
 left join #temp_real_hori_v1  t2     ----hori
 on t1.SKU_A = t2.sku_no
where t2.sku_no is  null

--- allocate pareto range ---
select Pareto_label, count(distinct sku_no)
from (
select t1.sku_no, t2.Pareto_label
from #temp_wash_v1 as t1
left join  [Deals_ASX_Analysis].[dbo].DB_DT_NDC_Stores as t2
on t1.sku_no = t2.sku_no
where t2.sku_no is not null )temp
group by Pareto_label