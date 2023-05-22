-------------------------black socks example ------------------
  drop table #BLACK_SOCKS
  SELECT *
  into #BLACK_SOCKS  ---197
  --sum(isnull(cast(total_sales_volume as float),0)) as vol
  FROM    [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE
  where sudo_tpc ='MW Menswear' and sku_desc like '%Sock%Black%'

--- attach the order number
  drop table #temp_order

  select  distinct t1.sku_no,t1. tranche, t2.oms_order_no
  into #temp_order
  FROM    #BLACK_SOCKS  t1
  left join 
   [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details2_new  t2
  on t1.sku_no = t2.sku_no

  ------ check the order 
  drop table #order_details
  select t1.oms_order_no,t1. tranche, t2. sudo_tpc, brand, product_type, sales_order_dollars_inc_gst,order_quantity
  into #order_details
  from #temp_order t1
  left join   [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details2_new  t2
  on t1.oms_order_no = t2.oms_order_no
  where t2.[3PL_flg]=1 AND split_flg=0 and sudo_tpc is not null
  order by t1.oms_order_no


  ------check the summary of the order
 drop table #good_order_3pl
  select distinct oms_order_no, count(distinct sudo_tpc) as count_tpc
  into #good_order_3pl
  from #order_details
  group by oms_order_no

  having count(distinct sudo_tpc)>1
    order by count_tpc desc


  ----- see examples from 3pl ---
  select   t2.oms_order_no, t2.sku_no, t2.sudo_tpc, t2.brand, t2.product_type, t3.Tranche, t2. sales_order_dollars_inc_gst, t2.order_quantity
  from #good_order_3pl t1
  left join [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details2_new t2
  on t1.oms_order_no = t2.oms_order_no 
  left join  [Deals_ASX_Analysis].[dbo].CY_2021_COMPLETE t3
  on t2. sku_no = t3. sku_no
  order by oms_order_no



   -----good example 1 ---

  select *
  from [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details2_new
  where oms_order_no ='1066318326'


  select *
from [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details2_new
 
  where oms_order_no ='1088193664'
